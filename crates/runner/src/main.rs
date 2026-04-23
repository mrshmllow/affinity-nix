use std::{
    fs::{self},
    io::{self, BufRead, BufReader},
    os::unix::fs::PermissionsExt,
    path::{Path, PathBuf},
    sync::LazyLock,
};

use anyhow::Context;
use clap::{Parser, Subcommand};
use duct::cmd;
use mutually_exclusive_features::exactly_one_of;
use nix::{
    libc::{self, S_IWUSR},
    mount::{MsFlags, mount, umount},
    sched::{CloneFlags, unshare},
    sys::wait::{WaitStatus, waitpid},
    unistd::{ForkResult, fork},
};
use tracing::{Level, error, info, instrument};
use tracing_subscriber::FmtSubscriber;
use walkdir::WalkDir;
use xdgdir::BaseDir;

use crate::check::{perform_migrations, sync_v2_settings};

mod check;
mod migrate;

exactly_one_of!("v3", "photo", "designer", "publisher");

const MOUNT_FAIL_STATUS: i32 = 111;

pub(crate) const WINE: &str = env!("WINE");
pub(crate) const WINEBOOT: &str = env!("WINEBOOT");
pub(crate) const WINESERVER: &str = env!("WINESERVER");
pub(crate) const WINETRICKS: &str = env!("WINETRICKS");
pub(crate) const FUSE_OVERLAYFS: &str = env!("FUSE_OVERLAYFS");
pub(crate) const GNUTAR: &str = env!("GNUTAR");
pub(crate) const ZENITY: &str = env!("ZENITY");

pub(crate) static LOWER_DIR: LazyLock<PathBuf> = LazyLock::new(|| PathBuf::from(env!("LOWER_DIR")));

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Arguments {
    /// Make Wine far more verbose.
    #[arg(long)]
    verbose: bool,

    /// Specified tool to use. If none matches, defaults to the affinity application.
    #[command(subcommand)]
    subcommand: Option<Program>,

    /// Arguments for affinity application
    #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
    affinity_arguments: Vec<String>,
}

#[derive(Subcommand, Debug)]
enum Program {
    /// Run wine within sandbox
    Wine {
        /// arguments to wine
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        arguments: Vec<String>,
    },
    /// Run winetricks within sandbox
    Winetricks {
        /// arguments to winetricks
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        arguments: Vec<String>,
    },
    /// Run wineboot within sandbox
    Wineboot {
        /// arguments to wineboot
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        arguments: Vec<String>,
    },
    /// Run wineserver within sandbox
    Wineserver {
        /// arguments to wineserver
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        arguments: Vec<String>,
    },
}

#[derive(Debug)]
enum ProgramToExecute {
    Affinity { arguments: Vec<String> },
    Other(Program),
}

#[derive(Debug)]
struct Paths {
    upper: PathBuf,
    work: PathBuf,
    wine_prefix: PathBuf,
}

impl Paths {
    fn ensure_created(&self) -> anyhow::Result<()> {
        let work_dir = self.work.join("work");

        if work_dir.is_dir() {
            let mut perms = fs::metadata(&work_dir)?.permissions();
            perms.set_mode(0o700);
            fs::set_permissions(&work_dir, perms).context("set workdir permissions")?;

            fs::remove_dir_all(&work_dir).context("delete workdir")?;
        }

        fs::create_dir_all(&self.upper).context("creating upper")?;
        fs::create_dir_all(&self.work).context("creating work")?;
        fs::create_dir_all(&self.wine_prefix).context("creating wine_prefix")?;

        Ok(())
    }
}

fn init_tracing() {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::TRACE)
        .finish();

    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");
}

fn make_env(expression: duct::Expression, wine_prefix: &Path, verbose: bool) -> duct::Expression {
    let expression = expression.env("WINEPREFIX", wine_prefix.display().to_string());

    if verbose {
        return expression;
    }

    expression.env("WINEDEBUG", "-all,fixme-all".to_string())
}

#[instrument]
fn warmup_prefix_directories(destination: &PathBuf) -> io::Result<()> {
    for entry in WalkDir::new(&*LOWER_DIR).into_iter().filter_map(|e| e.ok()) {
        if !entry.file_type().is_dir() {
            continue;
        }

        let relative_path = entry.path().strip_prefix(&*LOWER_DIR).unwrap();
        let target_path = destination.join(relative_path);

        if let Err(err) = fs::create_dir_all(&target_path) {
            error!(target_path = ?target_path, err = ?err, "failed to create");
        }
    }

    Ok(())
}

#[instrument]
fn warmup_prefix_registry(destination: &PathBuf, user: &String) -> io::Result<()> {
    let important_files = vec!["system.reg", "user.reg", "userdef.reg", ".update-timestamp"];

    for file in important_files {
        let src_path = LOWER_DIR.join(file);
        let dst_path = destination.join(file);

        if !src_path.try_exists()? || dst_path.try_exists()? {
            continue;
        }

        let content = fs::read_to_string(&src_path)?;
        let modified_content = content.replace("nixbld", user);

        fs::write(&dst_path, modified_content)?;

        let mut perms = fs::metadata(&dst_path)?.permissions();
        let current_mode = perms.mode();

        // set write bit
        perms.set_mode(current_mode | S_IWUSR);
        fs::set_permissions(&dst_path, perms)?;
    }

    Ok(())
}

#[instrument(skip_all)]
fn wineboot_update(wine_prefix: &Path, verbose: bool) -> anyhow::Result<()> {
    let handle = make_env(
        cmd!(WINEBOOT, "--update").stderr_to_stdout().unchecked(),
        wine_prefix,
        verbose,
    )
    .reader()?;

    let lines = BufReader::new(&handle).lines();

    for line in lines {
        let line = line?;
        info!("{line}");
    }

    match handle.try_wait()? {
        Some(output) => {
            if !output.status.success() {
                return Err(anyhow::anyhow!(
                    "wineboot --update failed: {:?}",
                    output.status
                ));
            }
        }
        None => {
            error!("wineboot child is still running in some way.");
        }
    }

    Ok(())
}

#[instrument(skip_all)]
fn execute(paths: &Paths, program: &ProgramToExecute, verbose: bool) -> anyhow::Result<()> {
    let user = std::env::var("USER")?;

    info!(user = ?user);

    if let Err(e) = warmup_prefix_directories(&paths.upper) {
        error!(error = %e, "warmup prefix directories failed (non-fatal)");
    };
    if let Err(e) = warmup_prefix_registry(&paths.upper, &user) {
        error!(error = %e, "warmup prefix registry failed (non-fatal)");
    };
    wineboot_update(&paths.wine_prefix, verbose)?;

    info!("finished warming & wineboot");

    perform_migrations(&paths.wine_prefix).context("performing migrations")?;

    if cfg!(not(feature = "v3")) {
        sync_v2_settings(&paths.wine_prefix, &user).context("sync v2 settings")?;
    }

    info!("finished pre-check");

    let application_handle = match program {
        ProgramToExecute::Affinity { arguments } => {
            let exe_suffix = if cfg!(feature = "v3") {
                "Affinity/AffinityHook.exe"
            } else if cfg!(feature = "photo") {
                "Photo 2/Photo.exe"
            } else if cfg!(feature = "publisher") {
                "Publisher 2/Publisher.exe"
            } else if cfg!(feature = "designer") {
                "Designer 2/Designer.exe"
            } else {
                unreachable!()
            };

            let exe_path = format!(
                "{}/drive_c/Program Files/Affinity/{}",
                paths.wine_prefix.display(),
                exe_suffix
            );

            info!("using exe {exe_path:?}");

            let mut cmd_arguments = vec![exe_path];
            cmd_arguments.extend(arguments.clone());

            cmd(WINE, cmd_arguments)
        }
        ProgramToExecute::Other(Program::Wine { arguments }) => cmd(WINE, arguments),
        ProgramToExecute::Other(Program::Winetricks { arguments }) => cmd(WINETRICKS, arguments),
        ProgramToExecute::Other(Program::Wineboot { arguments }) => cmd(WINEBOOT, arguments),
        ProgramToExecute::Other(Program::Wineserver { arguments }) => cmd(WINESERVER, arguments),
    };

    let application_handle = make_env(
        application_handle.stderr_to_stdout().unchecked(),
        &paths.wine_prefix,
        verbose,
    )
    .reader()?;

    let lines = BufReader::new(&application_handle).lines();

    for line in lines {
        let line = line?;
        println!("{line}");
    }

    match application_handle.try_wait()? {
        Some(output) => {
            if !output.status.success() {
                return Err(anyhow::anyhow!(
                    "application process failed: {:?}",
                    output.status
                ));
            } else {
                info!(status = ?output.status, "application process ended cleanly");
            }
        }
        None => {
            error!("application process is still running in some way.");
        }
    }

    let wineserver_wait = make_env(
        cmd!(WINESERVER, "-w").stderr_to_stdout().unchecked(),
        &paths.wine_prefix,
        verbose,
    )
    .reader()?;

    let lines = BufReader::new(&wineserver_wait).lines();

    for line in lines {
        let line = line?;
        info!("{line}");
    }

    match wineserver_wait.try_wait()? {
        Some(output) => {
            if !output.status.success() {
                return Err(anyhow::anyhow!("wineserver -w failed: {:?}", output.status));
            } else {
                info!(status = ?output.status, "wineserver -w exited cleanly");
            }
        }
        None => {
            error!("wineserver child is still running in some way.");
        }
    }

    Ok(())
}

#[instrument(skip_all, ret)]
fn make_mount_options(paths: &Paths) -> String {
    format!(
        "lowerdir={},upperdir={},workdir={}",
        LOWER_DIR.display(),
        paths.upper.display(),
        paths.work.display()
    )
}

#[instrument(skip(paths))]
fn cleanup_fuse(paths: &Paths) -> anyhow::Result<()> {
    let fusermount3 = cmd!(
        "/usr/bin/env",
        "fusermount3",
        "-u",
        "-z",
        paths.wine_prefix.display().to_string()
    )
    .stdout_to_stderr()
    .stderr_capture()
    .run();

    let success = match &fusermount3 {
        Ok(output) => {
            if output.status.success() {
                true
            } else {
                error!(status = %output.status, stderr = ?output.stderr, "`fusermount3` failed");
                false
            }
        }
        Err(err) => {
            error!(error = ?err, "`fusermount3` failed");
            false
        }
    };

    if !success {
        let fusermount = cmd!(
            "/usr/bin/env",
            "fusermount",
            "-u",
            "-z",
            paths.wine_prefix.display().to_string()
        )
        .stdout_to_stderr()
        .stderr_capture()
        .run()?;

        if !fusermount.status.success() {
            error!(status = %fusermount.status, stderr = ?String::from_utf8_lossy(&fusermount.stderr), "`fusermount2` failed");

            return Err(anyhow::anyhow!(
                "both `fusermount3` & `fusermount` failed! fusermount2: {:?}",
                String::from_utf8_lossy(&fusermount.stderr)
            ));
        }
    }

    info!("unmounted fuse cleanly");

    let _ = fs::remove_dir(&paths.wine_prefix)
        .inspect_err(|err| error!(error = ?err, "failed to remove wine_prefix"));

    Ok(())
}

#[instrument(skip_all)]
fn mount_run_unprivileged(
    paths: &Paths,
    program: &ProgramToExecute,
    verbose: bool,
) -> anyhow::Result<()> {
    let handle = cmd!(
        FUSE_OVERLAYFS,
        "-o",
        make_mount_options(paths),
        &paths.wine_prefix
    )
    .stderr_to_stdout()
    .unchecked()
    .reader()?;

    let lines = BufReader::new(&handle).lines();

    for line in lines {
        let line = line?;
        info!("{line}");
    }

    match handle.try_wait()? {
        Some(output) => {
            if !output.status.success() {
                return Err(anyhow::anyhow!(
                    "fuse-overlayfs failed to mount: {:?}",
                    output.status
                ));
            }
        }
        None => {
            error!("fuse-overlayfs child is still running in some way.");
        }
    }

    if let Err(err) = execute(paths, program, verbose) {
        error!(error = ?err, "Running with fuse failed.");
        let _ = cleanup_fuse(paths);
        return Err(anyhow::anyhow!(
            "failed to run application with `fuse-overlayfs`: {:?}",
            err
        ));
    };

    cleanup_fuse(paths)?;

    Ok(())
}

#[instrument(skip(paths))]
fn cleanup_privileged(paths: &Paths) {
    let _ = umount(&paths.wine_prefix)
        .inspect_err(|err| error!(error = ?err, "failed to unmount wine_prefix"));
    let _ = fs::remove_dir(&paths.wine_prefix)
        .inspect_err(|err| error!(error = ?err, "failed to remove wine_prefix"));
}

#[instrument(skip_all)]
fn mount_execute_privileged(paths: &Paths, program: &ProgramToExecute, verbose: bool) {
    match mount(
        Some("overlay"),
        &paths.wine_prefix,
        Some("overlay"),
        MsFlags::empty(),
        Some(make_mount_options(paths).as_str()),
    ) {
        Ok(_) => {
            if let Err(err) = execute(paths, program, verbose) {
                error!(error = ?err, "Running privileged failed.");
                cleanup_privileged(paths);
                std::process::exit(1);
            };
        }
        Err(err) => {
            error!(errorno = ?err, "Mount failed.");
            std::process::exit(MOUNT_FAIL_STATUS);
        }
    }

    cleanup_privileged(paths);
}

#[instrument(skip_all)]
fn mount_run_privileged(
    paths: &Paths,
    ids: (u32, u32),
    program: &ProgramToExecute,
    verbose: bool,
) -> anyhow::Result<()> {
    if let Err(err) = fs::write("/proc/self/setgroups", b"deny\n") {
        error!(error = ?err, "failed to write setgroups");
        mount_run_unprivileged(paths, program, verbose)?;
        return Ok(());
    }

    let uid_map = format!("0 {} 1\n", ids.0);
    if let Err(err) = fs::write("/proc/self/uid_map", uid_map) {
        error!(error = ?err, "failed to write uid_map");
        mount_run_unprivileged(paths, program, verbose)?;
        return Ok(());
    }

    let gid_map = format!("0 {} 1\n", ids.1);
    if let Err(err) = fs::write("/proc/self/gid_map", gid_map) {
        error!(error = ?err, "failed to write gid_map");
        mount_run_unprivileged(paths, program, verbose)?;
        return Ok(());
    }

    match unsafe { fork() } {
        Ok(ForkResult::Parent { child }) => match waitpid(child, None) {
            Ok(WaitStatus::Exited(_, status)) if status == MOUNT_FAIL_STATUS => {
                info!("Falling back on unprivileged due to failed mount");
                mount_run_unprivileged(paths, program, verbose)?;
            }
            Ok(WaitStatus::Exited(_, status)) => {
                std::process::exit(status);
            }
            Ok(WaitStatus::Signaled(_, signal, _)) => {
                info!(signal= ?signal, "child was killed by signal");
                std::process::exit(1);
            }
            Err(err) => {
                error!(errorno = ?err, "failed to wait for child");
                std::process::exit(1);
            }
            _ => {}
        },
        Ok(ForkResult::Child) => {
            unsafe {
                // make sure this namespace dies if the parent ends
                nix::libc::prctl(nix::libc::PR_SET_PDEATHSIG, nix::libc::SIGKILL);
            }
            mount_execute_privileged(paths, program, verbose);
            std::process::exit(0);
        }
        Err(err) => {
            error!(errorno = ?err, "Fork failed.");
            info!("Falling back on unprivileged");
            mount_run_unprivileged(paths, program, verbose)?;
        }
    }

    Ok(())
}

fn main() -> anyhow::Result<()> {
    init_tracing();

    let args = Arguments::parse();

    let base = BaseDir::new(if cfg!(feature = "v3") {
        "affinity-v3"
    } else {
        "affinity"
    })
    .expect("obtaining xdg basedir failed");

    let paths = Paths {
        upper: base.data,
        work: base.state,
        wine_prefix: base
            .runtime
            .unwrap_or_else(std::env::temp_dir)
            .join(format!("affinity-nix-prefix-{}", std::process::id())),
    };

    info!(paths = ?paths);

    paths
        .ensure_created()
        .context("setting up tmp directories")?;
    migrate::migrate(&paths).context("migrating to new overlayfs runner")?;

    let uid = unsafe { libc::getuid() };
    let gid = unsafe { libc::getgid() };

    let unshare =
        unshare(CloneFlags::CLONE_NEWUSER | CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWPID);

    let program = if let Some(subcommand) = args.subcommand {
        ProgramToExecute::Other(subcommand)
    } else {
        ProgramToExecute::Affinity {
            arguments: args.affinity_arguments,
        }
    };

    info!(program = ?program);

    match unshare {
        Ok(()) => mount_run_privileged(&paths, (uid, gid), &program, args.verbose),
        Err(err) => {
            error!(errorno = ?err, "Unshare failed.");
            mount_run_unprivileged(&paths, &program, args.verbose)?;

            Ok(())
        }
    }
}

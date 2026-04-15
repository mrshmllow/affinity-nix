use std::{fs, path::PathBuf};

use clap::Parser;
use nix::{
    libc,
    mount::{MsFlags, mount, umount},
    sched::{CloneFlags, unshare},
    sys::wait::{WaitStatus, waitpid},
    unistd::{ForkResult, fork},
};
use tracing::{Level, error, info, instrument};
use tracing_subscriber::FmtSubscriber;
use xdgdir::BaseDir;

const MOUNT_FAIL_STATUS: i32 = 111;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(long)]
    lower: PathBuf,

    #[arg(long)]
    v3: bool,
}

#[derive(Debug)]
struct Paths<'a> {
    lower: &'a PathBuf,
    upper: PathBuf,
    work: PathBuf,
    wine_prefix: PathBuf,
}

impl<'a> Paths<'a> {
    fn ensure_created(&self) -> std::io::Result<()> {
        fs::create_dir_all(&self.upper)?;
        fs::create_dir_all(&self.work)?;
        fs::create_dir_all(&self.wine_prefix)?;

        Ok(())
    }
}

fn init_tracing() {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::TRACE)
        .finish();

    tracing::subscriber::set_global_default(subscriber).expect("setting default subscriber failed");
}

#[instrument]
fn run_unprivileged() {}

#[instrument(skip(paths))]
fn mount_privileged(paths: &Paths) {
    let options = format!(
        "lowerdir={},upperdir={},workdir={}",
        paths.lower.display(),
        paths.upper.display(),
        paths.work.display()
    );

    info!(mount_options = ?options);

    match mount(
        Some("overlay"),
        &paths.wine_prefix,
        Some("overlay"),
        MsFlags::empty(),
        Some(options.as_str()),
    ) {
        Ok(_) => {
            // launch

            let entries = fs::read_dir(&paths.wine_prefix)
                .unwrap()
                .map(|res| res.map(|e| e.path()))
                .collect::<Result<Vec<_>, std::io::Error>>()
                .unwrap();

            info!(list = ?entries);
        }
        Err(err) => {
            error!(errorno = %err, "Mount failed.");
            std::process::exit(MOUNT_FAIL_STATUS);
        }
    }

    let _ = umount(&paths.wine_prefix)
        .inspect_err(|err| error!(error = ?err, "failed to unmount wine_prefix"));
    let _ = fs::remove_dir(&paths.wine_prefix)
        .inspect_err(|err| error!(error = ?err, "failed to remove wine_prefix"));
}

#[instrument(skip(paths))]
fn run_privileged(paths: &Paths, uid: u32, gid: u32) {
    fs::write("/proc/self/setgroups", b"deny\n").unwrap();

    let uid_map = format!("0 {} 1\n", uid);
    fs::write("/proc/self/uid_map", uid_map).unwrap();

    let gid_map = format!("0 {} 1\n", gid);
    fs::write("/proc/self/gid_map", gid_map).unwrap();

    match unsafe { fork() } {
        Ok(ForkResult::Parent { child }) => match waitpid(child, None) {
            Ok(WaitStatus::Exited(_, status)) => {
                if status == MOUNT_FAIL_STATUS {
                    info!("Falling back on unpriviledged due to failed mount");
                    run_unprivileged();
                }
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
            mount_privileged(paths);
        }
        Err(err) => {
            error!(errorno = %err, "Fork failed.");
            info!("Falling back on unpriviledged");
            run_unprivileged();
        }
    }
}

fn main() {
    init_tracing();

    let args = Args::parse();

    let base = BaseDir::new(if args.v3 { "affinity-v3" } else { "affinity" })
        .expect("obtaining xdg basedir failed");

    let paths = Paths {
        lower: &args.lower,
        upper: base.data,
        work: base.state,
        wine_prefix: base
            .runtime
            .unwrap_or_else(|| std::env::temp_dir())
            .join(format!("affinity-nix-prefix-{}", std::process::id())),
    };

    paths
        .ensure_created()
        .expect("failed to create temp directories");

    info!(paths = ?paths);

    let uid = unsafe { libc::getuid() };
    let gid = unsafe { libc::getgid() };

    let unshare =
        unshare(CloneFlags::CLONE_NEWUSER | CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWPID);

    match unshare {
        Ok(()) => run_privileged(&paths, uid, gid),
        Err(err) => {
            error!(errorno = %err, "Unshare failed.");
            run_unprivileged();
        }
    }
}

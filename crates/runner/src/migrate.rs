use std::{env, fs, io::{BufRead, BufReader}, path::Path};

use anyhow::Context;
use duct::cmd;
use tracing::{error, info, instrument};

use crate::{Binaries, Paths};

const MESSAGE: &str = "There have been upgrades to affinity-nix!

Affinity and it's dependencies are no longer installed directly, reducing startup time and manual updating.

To migrate, we need to delete the old installation. Your registry files and user data won't be touched.";

fn make_message(backup_location: &Path) -> String {
    format!("{MESSAGE} A backup will be created in at {}. Is that OK?", backup_location.display())
}

#[instrument(skip_all)]
pub(crate) fn migrate(paths: &Paths, binaries: &Binaries) -> anyhow::Result<()> {
    let revision_file = paths.upper.join(".revision");

    if !revision_file.is_file() {
        info!("revision file does not exist, skipping backup");
        return Ok(());
    }

    let revision: u32 = fs::read_to_string(revision_file).context("reading revision file")?.split_whitespace().collect::<String>().parse().context("parsing revision to u32")?;

    info!(revision = %revision);

    if revision >= 9 {
        info!("revision more than or equal to 9, skipping backup");
        return Ok(());
    }

    let backup_path = Path::new(&env::var("HOME").context("finding $HOME var")?).join(format!("affinity-nix-backup-{}.tar.zst", std::process::id()));

    let question = cmd!(&binaries.zenity, "--question", "--width", "480", format!("--text={}", make_message(&backup_path))).unchecked().run()?;

    if !question.status.success() {
        return Err(anyhow::anyhow!("User refused to migrate, we cannot continue or there may be data loss."));
    }

    let tar_handle = cmd!(&binaries.gnutar, "--zstd", "-cvpf", backup_path, &paths.upper).stdout_to_stderr().stderr_capture().reader()?;

    let lines = BufReader::new(&tar_handle).lines();

    for line in lines {
        let line = line?;
        info!("{line}");
    }

    match tar_handle.try_wait()? {
        Some(output) => {
            if !output.status.success() {
                return Err(anyhow::anyhow!(
                    "backing up with tar failed: {:?}",
                    output.status
                ));
            }

            info!(status = %output.status, "tar ended cleanly");
        }
        None => {
            error!("tar child is still running in some way.");
        }
    }

    let drive_c = paths.upper.join("drive_c");

    if !drive_c.is_dir() {
        return Ok(());
    }

    for entry in drive_c.read_dir().context("reading drive_c")? {
        let entry = entry.context("reading drive_c entry")?;

        if entry.file_name() == "users" {
            continue;
        }

        let path = entry.path();

        info!(path = ?path, "removing entry");

        if entry.file_type().context("reading entry filetype")?.is_dir() {
            fs::remove_dir_all(&path)
                    .with_context(|| format!("removing directory {}", path.display()))?;
        } else {
            fs::remove_file(&path)
                    .with_context(|| format!("removing file {}", path.display()))?;
        }
    }

    Ok(())
}

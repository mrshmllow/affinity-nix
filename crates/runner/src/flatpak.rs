use std::fs;

use anyhow::Context;
use duct::cmd;
use tracing::info;

use crate::{LOWER_DIR, Paths, ProgramToExecute, RSYNC, execute};

pub(crate) fn execute_flatpak(
    paths: &Paths,
    program: ProgramToExecute,
    verbose: bool,
) -> anyhow::Result<()> {
    let user_drive_c = paths.wine_prefix.join("drive_c");
    let base_drive_c = LOWER_DIR.join("drive_c");
    fs::create_dir_all(&user_drive_c).context("creating wine prefix")?;

    info!(user_drive_c = ?user_drive_c, base_drive_c = ?base_drive_c);

    let symlink_to_prefix = |path: &str| {
        std::os::unix::fs::symlink(base_drive_c.join(path), user_drive_c.join(path))
            .context(format!("symlinking {path:?}"))
    };

    let _ = symlink_to_prefix("Program Files (x86)");
    let _ = symlink_to_prefix("windows");

    // create writable programdata
    fs::create_dir_all(user_drive_c.join("ProgramData")).context("creating ProgramData")?;
    let _ = symlink_to_prefix("ProgramData/Microsoft");
    let _ = symlink_to_prefix("ProgramData/Package Cache");

    // create writable program files
    fs::create_dir_all(user_drive_c.join("Program Files")).context("creating Program Files")?;
    let _ = symlink_to_prefix("Program Files/Common Files");
    let _ = symlink_to_prefix("Program Files/Internet Explorer");
    let _ = symlink_to_prefix("Program Files/Windows Media Player");
    let _ = symlink_to_prefix("Program Files/Windows NT");

    let _ = fs::copy(
        LOWER_DIR.join("system.reg"),
        paths.wine_prefix.join("system.reg"),
    );
    let _ = fs::copy(
        LOWER_DIR.join("user.reg"),
        paths.wine_prefix.join("user.reg"),
    );
    let _ = fs::copy(
        LOWER_DIR.join("userdef.reg"),
        paths.wine_prefix.join("userdef.reg"),
    );

    let _ = fs::remove_dir_all(user_drive_c.join("Program Files/Affinity"));

    let copy_rsync = cmd!(
        RSYNC,
        "-v",
        "--chmod=D755,F644",
        "--recursive",
        "--delete",
        "/app/extra/sources/Affinity/",
        &user_drive_c.join("Program Files/Affinity")
    )
    .stderr_to_stdout()
    .read()
    .context("syncing affinity sources")?;

    for line in copy_rsync.lines().filter(|x| !x.is_empty()) {
        info!("syncing affinity sources: {line}");
    }

    info!("symlinked and copied");

    execute(paths, &program, verbose).context("executing application")?;

    Ok(())
}

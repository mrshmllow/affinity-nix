use std::{ffi::OsString, fs, path::PathBuf};

use anyhow::Context;
use duct::cmd;
use tracing::info;

use crate::{LOWER_DIR, Paths, ProgramToExecute, RSYNC, execute};

fn symlink_dir_entries(base_drive_c: &PathBuf, user_drive_c: &PathBuf, top_level_dir: &str, ignore: Vec<OsString>) -> anyhow::Result<()> {
    for entry in fs::read_dir(base_drive_c.join(top_level_dir)).context(format!("reading base {top_level_dir:?}"))? {
        let entry = entry.context(format!("unwrapping {top_level_dir:?} entry"))?;
        let last_part = entry.file_name();

        if ignore.contains(&last_part) {
            continue;
        }

        let _ = std::os::unix::fs::symlink(entry.path(), user_drive_c.join(top_level_dir).join(entry.file_name()));
    }

    Ok(())
}

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

    // create writable programdata
    fs::create_dir_all(user_drive_c.join("ProgramData")).context("creating ProgramData")?;
    symlink_dir_entries(&base_drive_c, &user_drive_c, "ProgramData", Vec::new()).context("symlinking ProgramData entries")?;

    fs::create_dir_all(user_drive_c.join("Program Files")).context("creating Program Files")?;
    symlink_dir_entries(&base_drive_c, &user_drive_c, "Program Files", Vec::new()).context("symlinking Program Files entries")?;

    fs::create_dir_all(user_drive_c.join("windows")).context("creating windows")?;
    // symlink_dir_entries(&base_drive_c, &user_drive_c, "windows", vec!["temp".into()]).context("symlinking windows entries")?;
    // fs::create_dir_all(user_drive_c.join("windows/temp")).context("creating windows/temp")?;

    symlink_dir_entries(&base_drive_c, &user_drive_c, "windows/temp", Vec::new()).context("symlinking windows/temp entries")?;

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

    let copy_rsync_affinity = cmd!(
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

    for line in copy_rsync_affinity.lines().filter(|x| !x.is_empty()) {
        info!("syncing affinity sources: {line}");
    }

    let copy_rsync_windows = cmd!(
        RSYNC,
        "-v",
        "--chmod=D755,F644",
        "--recursive",
        "--delete",
        &base_drive_c.join("windows"),
        &user_drive_c.join("windows")
    )
    .stderr_to_stdout()
    .read()
    .context("syncing C:\\windows")?;

    for line in copy_rsync_windows.lines().filter(|x| !x.is_empty()) {
        info!("syncing C:\\window: {line}");
    }

    info!("symlinked and copied");

    execute(paths, &program, verbose).context("executing application")?;

    Ok(())
}

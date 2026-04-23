use std::{
    fs,
    path::{Path, PathBuf},
    sync::LazyLock,
};

use anyhow::{Context, Result};
use duct::cmd;
use tracing::{info, instrument};

use crate::make_env;

pub(crate) static REGISTRY_PATCHES: LazyLock<PathBuf> =
    LazyLock::new(|| PathBuf::from(env!("REGISTRY_PATCHES")));
pub(crate) static ON_LINUX: LazyLock<PathBuf> = LazyLock::new(|| PathBuf::from(env!("ON_LINUX")));
pub(crate) const RSYNC: &str = env!("RSYNC");

const LATEST_REVISION: u32 = 10;

#[instrument(skip_all, ret)]
pub(crate) fn read_revision(wine_prefix: &Path) -> Result<Option<u32>> {
    let revision_file = wine_prefix.join(".revision");

    if !revision_file.is_file() {
        return Ok(None);
    }

    let revision: u32 = fs::read_to_string(revision_file)
        .context("reading revision file")?
        .split_whitespace()
        .collect::<String>()
        .parse()
        .context("parsing revision to u32")?;

    return Ok(Some(revision));
}

#[instrument(skip_all)]
pub fn sync_v2_settings(wine_prefix: &Path, user: &str) -> Result<()> {
    for app in ["Photo", "Designer", "Publisher"] {
        let app_settings_dst = wine_prefix.join(format!(
            "drive_c/users/{user}/AppData/Roaming/Affinity/{app}/2.0/"
        ));
        let app_settings_src = ON_LINUX.join(format!("Auxiliary/Settings/{app}/2.0/"));

        fs::create_dir_all(&app_settings_dst).context(format!(
            "creating settings directory for {app} w/ user {user}: {app_settings_dst:?}"
        ))?;

        let rsync = cmd!(
            RSYNC,
            "-v",
            "--ignore-existing",
            "--chmod=D755,F644",
            "--recursive",
            &app_settings_src,
            &app_settings_dst
        )
        .stderr_to_stdout()
        .read()
        .context(format!(
            "syncing {app} settings with rsync: dst {app_settings_dst:?}, src {app_settings_src:?}"
        ))?;

        for line in rsync.lines().filter(|x| !x.is_empty()) {
            info!(app = ?app, "{line}");
        }
    }

    Ok(())
}

pub fn write_revision(wine_prefix: &Path) -> Result<()> {
    let revision_file = wine_prefix.join(".revision");

    fs::write(&revision_file, LATEST_REVISION.to_string()).context("writing revision to file")?;

    info!("wrote {LATEST_REVISION:?} to {revision_file:?}");

    Ok(())
}

#[instrument(skip_all)]
pub fn perform_migrations(wine_prefix: &Path) -> Result<()> {
    let revision = crate::check::read_revision(wine_prefix)?.unwrap_or(0);

    if revision < 10 {
        let migration = make_env(
            cmd!(
                crate::WINE,
                "regedit",
                "/S",
                REGISTRY_PATCHES.join("one.reg")
            ),
            wine_prefix,
            true,
        )
        .stderr_to_stdout()
        .read()
        .context("applying one.reg")?;

        for line in migration.lines() {
            info!("vkd3d migration: {line}");
        }

        info!("finished vkd3d migration.");
    }

    write_revision(wine_prefix).context("writing revision")?;

    Ok(())
}

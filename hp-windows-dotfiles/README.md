# WAVE_DOTFILES

Personal Windows configuration for YASB, Komorebi, Nilesoft Shell, Vencord,
Spicetify, and PowerShell 7. The configs are collected here for backup and
reapplication; they are not a one-click installer.

This repository is prepared for public publishing. Machine-specific user paths
have been replaced with `YOUR_USERNAME`, private Vencord cloud state was
removed, and installed binaries, logs, backups, and generated runtime data are
not included. Review local changes before pushing updates.

## Contents

- [`yasb/`](./yasb/): bar configuration, styles, Komorebi lifecycle helper,
  and Matugen wallpaper-theme scripts.
- [`komorebi/`](./komorebi/): Komorebi, bar, and application rules.
- [`nilesoft/`](./nilesoft/): shell configuration and custom theme.
- [`vencord/`](./vencord/): QuickCSS and Vencord settings without cloud state.
- [`spicetify/`](./spicetify/): Spicetify settings and the LUNA/MONOCHROME
  theme customizations.
- [`powershell/`](./powershell/): PowerShell 7 profile.

## Requirements and upstream projects

- [YASB](https://github.com/amnweb/yasb)
- [Komorebi](https://github.com/LGUG2Z/komorebi)
- [Nilesoft Shell](https://github.com/moudey/Shell)
- [Vencord](https://github.com/Vendicated/Vencord)
- [Spicetify CLI](https://github.com/spicetify/cli)
- [PowerShell 7](https://github.com/PowerShell/PowerShell)
- [Matugen](https://github.com/InioX/matugen)
- [Superfile](https://github.com/yorukot/superfile), used by the `spf` shortcut.
- [ani-cli](https://github.com/pystardust/ani-cli)
- [btop](https://github.com/aristocratos/btop)
- [Cava](https://github.com/karlstav/cava)
- [Cargo](https://github.com/rust-lang/cargo), used to run the `rs-matrix` project.
- [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- [Git for Windows](https://github.com/git-for-windows/git), including Git Bash for `ani-cli`.
- [matrix-rain](https://www.npmjs.com/package/matrix-rain)
- [Oh My Posh](https://github.com/JanDeDobbeleer/oh-my-posh)
- [Winfetch](https://github.com/lptstr/winfetch)
- [Yazi](https://github.com/sxyazi/yazi)

Install the applications and any fonts referenced by your settings before
applying their configuration. The Komorebi fork executables are not included.

## How to apply

Back up your current configuration before copying files. Run commands in a
PowerShell 7 session, adjusting the repository path if you cloned it elsewhere:

```powershell
$repo = "$HOME\hp-windows-dotfiles"
```

### YASB and Matugen

1. Copy the files in `yasb` to `$HOME\.config\yasb`:

   ```powershell
   New-Item -ItemType Directory -Force "$HOME\.config\yasb" | Out-Null
   Copy-Item "$repo\yasb\*" "$HOME\.config\yasb" -Recurse -Force
   ```
2. In `config.yaml`, replace `YOUR_USERNAME` with your Windows account folder
   name. Set the wallpapers widget's `image_path` to your wallpaper directory.
3. Check that YASB and Komorebi are installed and that `pwsh.exe` is available.
4. Install Matugen and run the watcher once to generate the current palette:

   ```powershell
   & "$HOME\.config\yasb\wallpaper-watcher.ps1" sync
   ```

5. To sync the palette automatically after login, install the scheduled task
   from an elevated PowerShell 7 session:

   ```powershell
   & "$HOME\.config\yasb\wallpaper-watcher.ps1" install
   ```

The watcher reads the current Windows wallpaper, asks Matugen for a dark
`tonal-spot` palette, then writes the corresponding YASB, btop, Cava,
Superfile, Windows Terminal, Vencord, VS Code, and Nilesoft colors. Generated
files such as `matugen_colors.css` are runtime outputs and are intentionally
not tracked.

The LiMusic template at `yasb/matugen-limusic.css` is adapted from
[SimoHypers/limusic](https://github.com/SimoHypers/limusic) and is licensed
under GPL-3.0. That license applies to the template, not automatically to
every other file in this repository; a copy is included at
[`licenses/GPL-3.0.txt`](./licenses/GPL-3.0.txt). See
[GNU GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).

### Komorebi and its fork

Copy `komorebi\komorebi.json`, `komorebi\komorebi.bar.json`, and
`komorebi\applications.json` to `$HOME`:

```powershell
Copy-Item "$repo\komorebi\*.json" $HOME -Force
```

Copy `yasb\manage-komorebi.ps1` to `$HOME\.config\yasb`, then make sure
YASB's `start_command`, `stop_command`, and `reload_command` in `config.yaml`
point to that file. The supplied YAML uses `C:\Users\YOUR_USERNAME` as a
placeholder.

The local Komorebi directory contained only built `komorebi.exe` and
`komorebic.exe` files, so binaries are deliberately not committed. The
installed CLI reports version `0.1.41`, branch `first-simple`, commit
`7ea916f0`. No Git remote or source checkout was present, so the exact fork
URL and its patch set could not be verified. A fork is a separate copy of
Komorebi's source that can carry changes independently of upstream; use the
[upstream project](https://github.com/LGUG2Z/komorebi) as a reference and
replace that link with your fork's URL once you have it. Place your trusted
fork build at `$HOME\.config\yasb\komorebi-fork` to match the lifecycle
script.

### Nilesoft Shell

Copy `nilesoft\shell.nss` to the Nilesoft installation directory and
`nilesoft\imports\theme.nss` to its `imports` directory. Keep the rest of
Nilesoft's installed `imports` files in place because `shell.nss` references
them. Replacing files under `Program Files` may require an elevated session.
For example, with the default install path, run this from an elevated session:

```powershell
Copy-Item "$repo\nilesoft\shell.nss" "$env:ProgramFiles\Nilesoft Shell\shell.nss" -Force
Copy-Item "$repo\nilesoft\imports\theme.nss" "$env:ProgramFiles\Nilesoft Shell\imports\theme.nss" -Force
```

### Vencord

Back up `%APPDATA%\Vencord\settings` first, then copy `vencord\quickCss.css`
and `vencord\settings.json` there:

```powershell
Copy-Item "$repo\vencord\quickCss.css" "$env:APPDATA\Vencord\settings\quickCss.css" -Force
Copy-Item "$repo\vencord\settings.json" "$env:APPDATA\Vencord\settings\settings.json" -Force
```

The exported settings omit the `cloud` section; they do not include Vencord's
runtime files or logs.

### Spicetify

Copy the `spicetify\Themes` folders to `%APPDATA%\spicetify\Themes`. Set your
Spotify install paths for this PC, then select and apply the theme:

```powershell
Copy-Item "$repo\spicetify\Themes\*" "$env:APPDATA\spicetify\Themes" -Recurse -Force
spicetify config spotify_path "$env:APPDATA\Spotify" prefs_path "$env:APPDATA\Spotify\prefs"
spicetify config current_theme MONOCHROME
spicetify apply
```

The exported `config-xpui.ini` uses `YOUR_USERNAME` placeholders in its
Spotify paths. The MONOCHROME and LUNA CSS files had a stale import from a
different computer's Pywal cache; that machine-specific import was removed.
The CSS themes are separate from the Matugen watcher and are not currently
updated by it. The config enables the Spicetify Marketplace custom app, which
is not vendored here; install it from
[Spicetify Marketplace](https://github.com/spicetify/marketplace) if needed.
No third-party extension scripts are included; the exported extension list is
empty.

### PowerShell 7

Copy `powershell\ohmyposh.json` to `$HOME\.config\ohmyposh.json`. Merge
`powershell\Microsoft.PowerShell_profile.ps1` into
`$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` and
`powershell\profile.ps1` into `$HOME\Documents\PowerShell\profile.ps1`, or
back up and replace each profile if you want these settings. Start a new
PowerShell 7 session to load them. The second profile only loads the optional
Scoop Komorebi update script when it is present.

The repository copy intentionally omits the local hard-coded password gate
from the `spf` function; it calls Superfile directly instead. Do not store
passwords or tokens in a public profile.

## Publishing to GitHub

Create an empty public repository named `WAVE_DOTFILES` on GitHub, then from
this folder add and commit the files, set its remote, and push. If Git has no
author identity configured yet, set `user.name` and `user.email` first:

```powershell
git add -A
git commit -m "Add Windows dotfiles"
git remote add origin https://github.com/YOUR_GITHUB_NAME/WAVE_DOTFILES.git
git push -u origin main
```

Check `git status` and review the files before publishing any later updates.

# SkyCAD Electrical for Linux: install on Ubuntu and Linux Mint with Wine

![Status: in development](https://img.shields.io/badge/status-in%20development-orange)
![Platform: Linux Mint | Ubuntu](https://img.shields.io/badge/platform-Linux%20Mint%20%7C%20Ubuntu-green)
![Runs on: Wine](https://img.shields.io/badge/runs%20on-Wine%209%2B-red)
![Shell: Bash](https://img.shields.io/badge/shell-bash-lightgrey)

A one-command installer that runs **SkyCAD Electrical**, the Windows program for electrical schematics and panel design, on **Linux Mint and Ubuntu** using Wine.

Looking for **how to install SkyCAD on Linux**, or for a fix for SkyCAD not working in Wine (Internet Explorer 11 error, blank sheet, login not saved)? This script does the whole setup for you.

## What it is

SkyCAD Electrical only ships for Windows. A plain Wine install of it doesn't really work. The program starts, but sheets stay blank, parts can't be placed, and it hangs when you close it, so your settings and login are never saved.

This project fixes all of that. One script sets up a dedicated Wine environment with exactly the Windows components SkyCAD needs. Then it runs the official SkyCAD installer and adds a desktop and menu shortcut.

## What it does

- **Installs Wine** (WineHQ stable) if it's missing or broken. The Wine from the software store fails with SkyCAD.
- **Creates a separate Wine prefix** in `~/.wine-skycad`, so SkyCAD can't interfere with your other Wine programs.
- **Installs the Windows parts SkyCAD needs:** .NET Framework 4.8, Microsoft GDI+, and the Arial, Courier New and Calibri fonts.
- **Prepares the system for the SkyCAD installer:** sets Windows 10 mode and the Internet Explorer 11 registry values. Without them the installer refuses to run.
- **Runs your SkyCAD installer.**
- **Adds a `skycad` launcher**, plus desktop and menu icons. The launcher closes any stuck copy of SkyCAD before it starts a new one.
- **Can be safely run again.** It skips steps that are already done, and it logs everything to `~/skycad-install.log`.

> SkyCAD itself is **not** included. You need your own SkyCAD account and the official installer from SkyCAD's website.

## Requirements

| | |
|---|---|
| **Operating system** | Linux Mint or Ubuntu, 64-bit. Tested on Linux Mint 22.3 (Ubuntu 24.04 base). |
| **Disk space** | A few GB free (.NET and Wine take up most of it) |
| **Internet** | Needed during installation |
| **Account** | A normal user with `sudo` rights (it asks for your password once to install Wine) |
| **SkyCAD** | The installer from SkyCAD's website, renamed to `SkyCad_Setup.exe` |

## Installation

1. Download the SkyCAD installer from SkyCAD's website. Leave it in your **Downloads** folder.
2. **Rename the file to exactly `SkyCad_Setup.exe`.** The script only finds it under that name.
3. Open a **Terminal**, paste this command and press **Enter**:

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/TheMarcoPisPolo/SkyCAD_Linux/main/install.sh)
   ```

   If you get `curl: command not found`, use this command instead:

   ```bash
   bash <(wget -qO- https://raw.githubusercontent.com/TheMarcoPisPolo/SkyCAD_Linux/main/install.sh)
   ```

4. When the **SkyCAD installer** window appears, click **Install**. Close the window when it's finished.

**Good to know:**

- When you type your password, nothing appears on screen. That's normal.
- The install takes **15 to 40 minutes**. Windows may pop up and close by themselves. Leave them alone.

When the install is done, start SkyCAD from the **SkyCAD Electrical** icon on your desktop or in the menu. The first time, log in, then tick *"Don't show at next start-up"* on the welcome screen.

### Advanced options

```bash
# Use an installer that isn't in ~/Downloads
bash install.sh /path/to/SkyCad_Setup.exe

# Install into a different Wine prefix
SKYCAD_PREFIX=/some/folder bash install.sh
```

## Troubleshooting

| Problem | Solution |
|---|---|
| SkyCAD won't start, or it crashes right away | Start it from the **SkyCAD Electrical** icon, not from a shortcut Wine created. The icon closes any stuck copy first. |
| SkyCAD closes itself after the first setup and doesn't come back | Start it again from the icon. |
| The installer stopped with an error | Run the same install command again. It picks up where it stopped. |
| It still fails | Open an [issue](https://github.com/TheMarcoPisPolo/SkyCAD_Linux/issues) and attach the end of `~/skycad-install.log`. |

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TheMarcoPisPolo/SkyCAD_Linux/main/install.sh) --uninstall
```

This removes the SkyCAD Wine prefix, the launcher, and the menu and desktop icons. Wine itself stays installed.

## How it works

| Component | Why it's needed |
|---|---|
| Wine 9+ (WineHQ stable) | Runs Windows programs on Linux |
| .NET Framework 4.8 | SkyCAD is a .NET program. Wine's built-in Mono crashes when running it. |
| Microsoft GDI+ | Draws the sheets |
| Arial, Courier New and Calibri fonts | **Essential.** Without them sheets stay blank, parts can't be placed, and SkyCAD hangs when you close it, so your settings and login are never saved. |
| Windows 10 mode and IE11 registry values | The SkyCAD installer won't run without them |
| `skycad` launcher | Closes any stuck copy of SkyCAD before starting a new one |

## FAQ

### Does SkyCAD Electrical work on Linux?
Yes. SkyCAD Electrical is a Windows-only program, but it runs on Linux with Wine once the right Windows components are installed. This script installs them for you. Drawing, placing parts, saving settings and staying logged in all work.

### Can I install SkyCAD on Ubuntu?
Yes. The script works on Ubuntu and on Linux Mint, which is based on Ubuntu. It was tested on Linux Mint 22.3 (Ubuntu 24.04 base).

### The SkyCAD installer says Internet Explorer 11 is required
Wine doesn't report Internet Explorer 11 the way the SkyCAD installer expects. The script adds the IE11 registry values (`svcVersion` and `svcUpdateVersion`) so the installer runs.

### SkyCAD opens in Wine but the sheet is blank and I can't place parts
The Arial, Courier New and Calibri fonts are missing. The script installs them with winetricks (`corefonts` and `calibri`).

### SkyCAD forgets my login and settings in Wine
SkyCAD only saves its settings when it closes cleanly. Without the fonts above it hangs when closing, so nothing is saved. The fonts fix this too.

### Wine says "could not load kernel32.dll, status c0000135"
The Wine version from the software store is being used. The script installs and uses WineHQ stable instead.

### SkyCAD crashes in Wine right after login
SkyCAD needs the real .NET Framework 4.8. Wine's built-in Mono crashes with it. The script installs .NET 4.8 with winetricks.

### Does this work with Bottles, PlayOnLinux or Lutris?
Not tested. The script uses plain Wine with its own prefix (`~/.wine-skycad`). You can install the same components in another tool, using the table in [How it works](#how-it-works).

## Project status

This project is still in development. Installing, drawing, placing parts, saving settings and staying logged in all work on Linux Mint 22.3. Other distributions and versions haven't been tested yet. If you try one, please report how it went.

## Disclaimer

This is an independent community project. It is not affiliated with, endorsed by or supported by SkyCAD. *SkyCAD* and *SkyCAD Electrical* are trademarks of their respective owner. This repository only contains an installation script. It does not include or distribute any SkyCAD software.

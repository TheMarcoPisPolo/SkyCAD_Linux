# SkyCAD Electrical on Linux

Installs **SkyCAD Electrical** on Linux Mint / Ubuntu using Wine, with everything it needs to work properly
(drawing, placing parts, saving settings and remembering your login).

## Install (2 steps)

1. Download **`SkyCad_Setup.exe`** from SkyCAD's website and leave it in your **Downloads** folder.
2. Open a **Terminal** and paste this line, then press Enter:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TheMarcoPisPolo/SkyCAD_Linux/main/install.sh)
```

- It may ask for your password (to install Wine). The letters don't show while typing: that's normal.
- It takes **15 to 40 minutes**. Some windows may pop up and close by themselves: let them.
- When the **SkyCAD installer** opens, click **Install**, then close it when finished.

Then start SkyCAD from the **SkyCAD Electrical** icon on your desktop or in the menu.

## If something goes wrong

- Start SkyCAD from the **SkyCAD Electrical** icon (not the one Wine made): it clears a stuck copy first.
- The full install log is in `~/skycad-install.log`.
- You can run the install command again at any time; it skips what is already done.

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TheMarcoPisPolo/SkyCAD_Linux/main/install.sh) --uninstall
```

## What it sets up (for the curious)

| Piece | Why |
|---|---|
| Wine 9+ (WineHQ stable) | runs Windows programs |
| .NET Framework 4.8 | SkyCAD is a .NET program (Wine's own Mono crashes in it) |
| Microsoft GDI+ | draws the sheets |
| Arial, Courier New, Calibri fonts | **essential**: without them sheets stay blank, parts can't be placed and SkyCAD hangs when closing, so settings and login are never saved |
| Windows 10 mode + IE11 registry values | the SkyCAD installer refuses to run otherwise |
| `skycad` launcher | closes a stuck SkyCAD copy before starting |

Everything lives in `~/.wine-skycad`, separate from any other Wine programs.
SkyCAD itself is not included here; you need your own SkyCAD account and installer.

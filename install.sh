#!/usr/bin/env bash
# SkyCAD Electrical on Linux (Wine) - one-command installer
# Tested on Linux Mint 22.3 (Ubuntu 24.04 base) with Wine 11.
#
# Usage:
#   bash install.sh                      # looks for ~/Downloads/SkyCad_Setup*.exe
#   bash install.sh /path/to/SkyCad_Setup.exe
#   bash install.sh --uninstall
#
# Optional: SKYCAD_PREFIX=/some/folder bash install.sh   (default: ~/.wine-skycad)

set -euo pipefail

PREFIX="${SKYCAD_PREFIX:-$HOME/.wine-skycad}"
TOOLS="$HOME/.local/share/skycad-linux"
WINETRICKS="$TOOLS/winetricks"
LAUNCHER="$HOME/.local/bin/skycad"
DESKTOP_FILE="$HOME/.local/share/applications/skycad-electrical.desktop"
EXE_REL="drive_c/Program Files/SkyCAD Electrical/SkyCadElectrical.exe"
LOG="$HOME/skycad-install.log"

say()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m!!  %s\033[0m\n' "$*"; }
die()  { trap - EXIT; printf '\n\033[1;31mXX  %s\033[0m\n' "$*"; exit 1; }

export WINEPREFIX="$PREFIX" WINEDEBUG=-all
export PATH="/opt/wine-stable/bin:$PATH"
trap 'rc=$?; (( rc )) && printf "\n\033[1;31mXX  Stopped with an error (code %s). Run the same command again; if it fails again, send the end of %s.\033[0m\n" "$rc" "$LOG"' EXIT

# ---------------------------------------------------------------- uninstall
if [[ "${1:-}" == "--uninstall" ]]; then
  say "Removing SkyCAD (prefix $PREFIX, launcher, menu entry)"
  wineserver -k 2>/dev/null || true
  rm -rf "$PREFIX" "$LAUNCHER" "$DESKTOP_FILE" "$TOOLS"
  rm -f "$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")/skycad-electrical.desktop"
  say "Done."
  exit 0
fi

[[ $EUID -eq 0 ]] && die "Run this as your normal user, not with sudo. It asks for your password when needed."
exec > >(tee -a "$LOG") 2>&1
say "SkyCAD Electrical installer for Linux - log: $LOG"

# ---------------------------------------------------------------- 1. find the SkyCAD setup file
SETUP="${1:-}"
if [[ -z "$SETUP" ]]; then
  SETUP="$(ls -t "$HOME"/Downloads/SkyCad_Setup*.exe "$HOME"/Downloads/SkyCAD*Setup*.exe 2>/dev/null | head -1 || true)"
fi
if [[ ! -f "$PREFIX/$EXE_REL" && ( -z "$SETUP" || ! -f "$SETUP" ) ]]; then
  die "SkyCAD setup file not found.
    Download SkyCad_Setup.exe from SkyCAD's website into your Downloads folder,
    then run this script again (or pass the file: bash install.sh /path/to/SkyCad_Setup.exe)."
fi

# ---------------------------------------------------------------- 2. system packages + Wine
. /etc/os-release
CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
need_pkgs=()
for p in cabextract unzip curl wget p7zip-full; do
  dpkg -s "$p" >/dev/null 2>&1 || need_pkgs+=("$p")
done

# Always use WineHQ's Wine in /opt/wine-stable. The Wine from the Mint/Ubuntu software store
# (or a half-installed one) fails with "could not load kernel32.dll, status c0000135".
WINEBIN=/opt/wine-stable/bin
if [[ ! -x "$WINEBIN/wine" ]] || ! dpkg --print-foreign-architectures | grep -qx i386; then
  say "Installing Wine (WineHQ stable) - you may be asked for your password"
  [[ -n "$CODENAME" ]] || die "Could not detect your Ubuntu base version. Install WineHQ stable manually, then rerun."
  sudo dpkg --add-architecture i386
  sudo mkdir -pm755 /etc/apt/keyrings
  sudo wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
  sudo wget -qNP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/$CODENAME/winehq-$CODENAME.sources"
  sudo apt-get update
  sudo apt-get install -y --install-recommends winehq-stable "${need_pkgs[@]}"
elif (( ${#need_pkgs[@]} )); then
  say "Installing helper packages: ${need_pkgs[*]} - you may be asked for your password"
  sudo apt-get install -y "${need_pkgs[@]}"
fi
[[ -x "$WINEBIN/wine" ]] || die "WineHQ Wine did not install correctly (missing $WINEBIN/wine)."
export PATH="$WINEBIN:$PATH" WINE="$WINEBIN/wine" WINESERVER="$WINEBIN/wineserver"
say "Using $(wine --version) from $WINEBIN"

if pgrep -f -i 'SkyCadElectrical\.exe' >/dev/null; then
  warn "SkyCAD is running in this prefix - closing it so the installer can continue"
  wineserver -k || true
  sleep 2
fi

# ---------------------------------------------------------------- 3. latest winetricks
mkdir -p "$TOOLS"
say "Downloading the latest winetricks"
curl -fsSL -o "$WINETRICKS.new" https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
  && mv "$WINETRICKS.new" "$WINETRICKS" && chmod +x "$WINETRICKS" \
  || { [[ -x "$WINETRICKS" ]] || die "Could not download winetricks (check your internet)."; }

# ---------------------------------------------------------------- 4. Wine prefix + components
if [[ ! -f "$PREFIX/drive_c/windows/system32/kernel32.dll" ]]; then
  say "Creating Wine prefix $PREFIX"
  rm -rf "$PREFIX"   # leftover from a failed attempt
  if ! WINEARCH=win64 wineboot -i || ! wineserver -w || [[ ! -d "$PREFIX/drive_c/windows" ]]; then
    rm -rf "$PREFIX"
    die "Wine could not create its Windows folder. Send the end of $LOG for help."
  fi
fi

say "Installing Windows components (fonts, GDI+, .NET 4.8). This takes 15-40 minutes."
# corefonts + calibri : SkyCAD draws text in Arial/Calibri/Courier New. Without them it cannot
#                       draw sheets, cannot place parts and hangs on exit (settings/login never saved).
# gdiplus             : Microsoft GDI+, used to draw the sheets.
# dotnet48            : SkyCAD is a .NET Framework 4.8 program (Wine Mono crashes in it).
# (vcrun2019 is NOT needed: SkyCAD only uses the C++ runtime bundled with .NET.)
"$WINETRICKS" -q corefonts calibri gdiplus dotnet48
# dotnet48 switches the prefix to Windows 7; SkyCAD wants Windows 10.
"$WINETRICKS" -q win10
wineserver -w

say "Telling the SkyCAD installer that Internet Explorer 11 is present"
for view in /reg:64 /reg:32; do
  wine reg add 'HKLM\Software\Microsoft\Internet Explorer' /v svcVersion       /t REG_SZ /d 11.0.9600.18376 /f $view >/dev/null
  wine reg add 'HKLM\Software\Microsoft\Internet Explorer' /v svcUpdateVersion /t REG_SZ /d 11.0.215        /f $view >/dev/null
done
wineserver -w

# ---------------------------------------------------------------- 5. SkyCAD itself
if [[ -f "$PREFIX/$EXE_REL" ]]; then
  say "SkyCAD is already installed in this prefix - skipping its installer"
else
  say "Starting the SkyCAD installer: click Install in the window that opens, then close it when finished"
  wine "$SETUP" || true
  # Do NOT use "wineserver -w" here: the installer starts SkyCAD at the end, and that would
  # make this script wait until SkyCAD is closed. Only wait for the installer itself.
  while pgrep -f -i '^[A-Z]:\\.*(msiexec|setup[^\\]*)\.exe' >/dev/null; do sleep 3; done
  [[ -f "$PREFIX/$EXE_REL" ]] || die "SkyCAD was not installed (installer cancelled?). Run this script again."
fi

# ---------------------------------------------------------------- 6. launcher + menu/desktop icon
say "Creating the SkyCAD launcher and menu entry"
mkdir -p "$(dirname "$LAUNCHER")" "$(dirname "$DESKTOP_FILE")"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
# Start SkyCAD Electrical. Clears a stuck copy left in the background first.
export WINEPREFIX="$PREFIX"
export PATH="$WINEBIN:\$PATH"
if pgrep -f 'SkyCadElectrical.exe' >/dev/null; then wineserver -k; sleep 2; fi
cd "\$WINEPREFIX/drive_c/Program Files/SkyCAD Electrical" || exit 1
exec wine SkyCadElectrical.exe "\$@"
EOF
chmod +x "$LAUNCHER"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=SkyCAD Electrical
Comment=Electrical CAD (runs in Wine)
Exec=$LAUNCHER
Icon=$PREFIX/drive_c/Program Files/SkyCAD Electrical/SkyCadPackageLogo.ico
Terminal=false
Categories=Graphics;Engineering;
StartupWMClass=skycadelectrical.exe
EOF

DESK="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
# Remove the shortcuts Wine made: they start SkyCAD without clearing a stuck copy (-> crash).
rm -f "$DESK/SkyCAD Electrical.desktop" "$HOME/.local/share/applications/wine/Programs/SkyCAD Electrical.desktop"
if [[ -d "$DESK" ]]; then
  cp "$DESKTOP_FILE" "$DESK/"
  chmod +x "$DESK/skycad-electrical.desktop"
  gio set "$DESK/skycad-electrical.desktop" metadata::trusted true 2>/dev/null || true
fi

say "All done! Start SkyCAD from the 'SkyCAD Electrical' icon on your desktop or in the menu."
echo "    (or type: $LAUNCHER)"
echo "    If SkyCAD restarts itself after the first setup and does not come back, just start it"
echo "    again from the icon."
echo "    The first time, log in and tick \"Don't show at next start-up\" on the welcome screen."

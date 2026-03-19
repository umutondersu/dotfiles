#!/usr/bin/env bash
# foobar-wineprefix.sh
# Recreates the foobar2000 Wine prefix at ~/.local/share/wineprefixes/foobar
#
# Components installed (mirrors winetricks.log):
#   corefonts, vcrun2015, msxml6, sourcehansans, fakechinese, fakejapanese,
#   fakekorean, unifont, cjkfonts, msls31, fontsmooth=rgb, gdiplus
#
# Architecture detection:
#   - If 32-bit Wine is available (WINEARCH=win32 works) → creates a win32 prefix
#   - Otherwise → creates a win64 prefix using WoW64 thunking (works on modern
#     Arch/CachyOS where the default wine package is 64-bit only)
#
# After running, manually set up the D: drive if foobar2000 is on an external drive:
#   ln -sf /path/to/your/T7 ~/.local/share/wineprefixes/foobar/dosdevices/d:

set -euo pipefail

PREFIX="$HOME/.local/share/wineprefixes/foobar"
WINETRICKS_VERBS="corefonts vcrun2015 msxml6 sourcehansans fakechinese fakejapanese fakekorean unifont cjkfonts msls31 fontsmooth=rgb gdiplus"

# ── colours ──────────────────────────────────────────────────────────────────
bold=$'\e[1m'
red=$'\e[1;31m'
green=$'\e[1;32m'
yellow=$'\e[1;33m'
cyan=$'\e[1;36m'
reset=$'\e[0m'

info()  { printf '%s==>%s %s\n' "$cyan"  "$reset" "$*"; }
ok()    { printf '%s ok%s  %s\n' "$green" "$reset" "$*"; }
warn()  { printf '%s warn%s %s\n' "$yellow" "$reset" "$*"; }
die()   { printf '%s error%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

# ── preflight checks ─────────────────────────────────────────────────────────
info "Checking dependencies..."

command -v wine      >/dev/null 2>&1 || die "'wine' not found. Install wine or wine-staging and try again."
command -v winetricks >/dev/null 2>&1 || die "'winetricks' not found. Install winetricks and try again."

ok "wine $(wine --version 2>/dev/null) found"
ok "winetricks found"

# ── check prefix doesn't already exist ───────────────────────────────────────
if [[ -d "$PREFIX" ]]; then
    die "Prefix already exists at $PREFIX — remove it first if you want to recreate it:
       rm -rf \"$PREFIX\""
fi

# ── detect 32-bit Wine availability ──────────────────────────────────────────
info "Detecting Wine architecture support..."

WINEARCH_FLAG=""
PREFIX_ARCH="win64"

if WINEARCH=win32 WINEPREFIX=/tmp/winearch-probe-$$ wine --version >/dev/null 2>&1; then
    WINEARCH_FLAG="WINEARCH=win32"
    PREFIX_ARCH="win32"
    # clean up the probe prefix
    rm -rf "/tmp/winearch-probe-$$" 2>/dev/null || true
    ok "32-bit Wine available — will create a win32 prefix (exact match of original)"
else
    warn "32-bit Wine not available (normal on Arch/CachyOS with default wine package)"
    info "Using win64 prefix with WoW64 thunking — foobar2000 (32-bit) will still run fine"
fi

# ── create the prefix ────────────────────────────────────────────────────────
info "Creating prefix at $PREFIX ($PREFIX_ARCH)..."

mkdir -p "$(dirname "$PREFIX")"

if [[ "$PREFIX_ARCH" == "win32" ]]; then
    WINEARCH=win32 WINEPREFIX="$PREFIX" wineboot --init 2>/dev/null
else
    WINEPREFIX="$PREFIX" wineboot --init 2>/dev/null
fi

# wait for the wineserver to finish initialising
WINEPREFIX="$PREFIX" wineserver --wait 2>/dev/null || true

ok "Prefix created"

# ── set Windows version to Windows 10 ────────────────────────────────────────
info "Setting Windows version to Windows 10..."
WINEPREFIX="$PREFIX" winetricks -q win10
ok "Windows version set to Win10"

# ── install winetricks components ────────────────────────────────────────────
info "Installing winetricks components..."
info "(sourcehansans, unifont, and cjkfonts are large downloads — this will take a while)"
echo

for verb in $WINETRICKS_VERBS; do
    info "  Installing: $verb"
    WINEPREFIX="$PREFIX" winetricks -q "$verb"
    ok "  $verb done"
done

# ── wait for wine to settle ───────────────────────────────────────────────────
WINEPREFIX="$PREFIX" wineserver --wait 2>/dev/null || true

# ── summary ──────────────────────────────────────────────────────────────────
echo
printf '%s' "$bold"
echo "============================================================"
echo " foobar2000 Wine prefix created successfully"
echo "============================================================"
printf '%s' "$reset"
echo
echo "  Location : $PREFIX"
echo "  Arch     : $PREFIX_ARCH"
echo "  Win ver  : Windows 10"
echo
echo "  Components installed:"
for verb in $WINETRICKS_VERBS; do
    echo "    - $verb"
done
echo
printf '%s' "$yellow"
echo "  D: drive not configured (skipped by design)."
printf '%s' "$reset"
echo "  If foobar2000 lives on an external drive (e.g. Samsung T7),"
echo "  set up the D: mapping manually after mounting the drive:"
echo
echo "    ln -sf /path/to/T7 \"$PREFIX/dosdevices/d:\""
echo
echo "  Then launch foobar2000 with:"
echo
echo "    WINEPREFIX=\"$PREFIX\" wine \"D:\\\\foobar2000\\\\foobar2000.exe\""
echo

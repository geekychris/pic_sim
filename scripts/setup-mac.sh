#!/bin/bash
# One-shot macOS setup for the PIC18F452 simulator project.
#   1. MPLAB extensions for VS Code
#   2. MPLAB XC8 compiler (free mode)       -> /Applications/microchip/xc8/<ver>  (asks for sudo)
#   3. PIC18Fxxxx device family pack (DFP)  -> ~/.mchp_packs/Microchip/PIC18Fxxxx_DFP/<ver>
#
# Usage: bash scripts/setup-mac.sh        (run as yourself, NOT with sudo)
set -euo pipefail

XC8_VER=v4.00
DFP_VER=1.8.178
XC8_URL="https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc8-${XC8_VER}-full-install-macos-x64-installer.dmg"
DFP_URL="https://packs.download.microchip.com/Microchip.PIC18Fxxxx_DFP.${DFP_VER}.atpack"
XC8_DIR="/Applications/microchip/xc8/${XC8_VER}"
DFP_DIR="$HOME/.mchp_packs/Microchip/PIC18Fxxxx_DFP/${DFP_VER}"

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user; it calls sudo only for the compiler install."; exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---- 1. VS Code + MPLAB extensions -------------------------------------
CODE=$(command -v code || true)
[[ -n "$CODE" ]] || CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [[ ! -x "$CODE" ]]; then
  echo "VS Code not found. Install it from https://code.visualstudio.com (or: brew install --cask visual-studio-code)"; exit 1
fi
echo "==> Installing MPLAB extensions for VS Code"
"$CODE" --install-extension Microchip.mplab-extension-pack --force

# ---- 2. XC8 compiler ---------------------------------------------------
if [[ -x "$XC8_DIR/bin/xc8-cc" ]]; then
  echo "==> XC8 ${XC8_VER} already installed"
else
  if [[ $(uname -m) == arm64 ]] && ! arch -x86_64 /usr/bin/true 2>/dev/null; then
    echo "==> Installing Rosetta 2 (XC8 tools are x86-64)"
    softwareupdate --install-rosetta --agree-to-license
  fi
  echo "==> Downloading XC8 ${XC8_VER}"
  curl -fL -o "$TMP/xc8.dmg" "$XC8_URL"
  MNT="$TMP/mnt"; mkdir -p "$MNT"
  hdiutil attach -nobrowse -readonly -mountpoint "$MNT" "$TMP/xc8.dmg" >/dev/null
  APP=$(ls -d "$MNT"/*.app | head -1)
  BIN="$APP/Contents/MacOS/osx-$(uname -m)"
  [[ -x "$BIN" ]] || BIN="$APP/Contents/MacOS/osx-x86_64"
  echo "==> Installing XC8 (sudo password required)"
  sudo "$BIN" --mode unattended --unattendedmodeui none --prefix "$XC8_DIR"
  hdiutil detach "$MNT" >/dev/null || true
fi
"$XC8_DIR/bin/xc8-cc" --version | head -1

# ---- 3. Device family pack ---------------------------------------------
if [[ -f "$DFP_DIR/edc/PIC18F452.PIC" ]]; then
  echo "==> PIC18Fxxxx_DFP ${DFP_VER} already installed"
else
  echo "==> Downloading PIC18Fxxxx_DFP ${DFP_VER}"
  curl -fL -o "$TMP/dfp.atpack" "$DFP_URL"
  mkdir -p "$DFP_DIR"
  unzip -q -o "$TMP/dfp.atpack" -d "$DFP_DIR"
fi

echo
echo "Setup complete. Next: open this folder in VS Code, Cmd+Shift+B to build, F5 to simulate."

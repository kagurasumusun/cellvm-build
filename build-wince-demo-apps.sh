#!/bin/sh
# Build the non-EasyRPG demo apps (hellowince, chip8wince) with the LLVM/Clang
# WinCE toolchain. Minimal COREDLL/GDI dependencies only.
#
#   build-wince-demo-apps.sh [toolchain-bin-dir] [out-dir]
#   default toolchain-bin-dir = $PWD/install/wince-llvm/bin
set -eu
BIN=${1:-"$PWD/install/wince-llvm/bin"}
OUT=${2:-"$PWD/apps-out"}
SRC=$(CDPATH= cd -- "$(dirname "$0")/apps" && pwd)

mkdir -p "$OUT"
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing $1" >&2; exit 1; }; }
need "$BIN/arm-pc-wince-clang++"
need "$BIN/llvm-readobj"

"$BIN/arm-pc-wince-clang++" -Os -march=armv5te -o "$OUT/hellowince.exe"  "$SRC/hellowince/hellowince.cpp"
"$BIN/arm-pc-wince-clang++" -Os -march=armv5te -o "$OUT/chip8wince.exe"  "$SRC/chip8/chip8.cpp"

echo "built:"
ls -la "$OUT"/*.exe
"$BIN/llvm-readobj" --file-headers "$OUT/hellowince.exe" | grep -E "Machine:|Subsystem:" || true

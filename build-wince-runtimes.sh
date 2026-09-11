#!/bin/bash
#===- build-wince-runtimes.sh - WinCE stage-3 ----------------------------===//
#
# Stage 3 of the WinCE toolchain build (after build-wince-sysroot.sh
# assembled the wince-crt + wince-api sysroot):
#
#   [1/2] compiler-rt builtins for the target (the -lgcc replacement,
#         libclang_rt.builtins-<arch>.a) -- REQUIRED gate.  Built with
#         -ffreestanding plus the sysroot/crt-decls declaration header:
#         the builtins are free-standing code, but int_util.c includes
#         <stdlib.h> under _WIN32 (the abort() path is compiled out
#         under -ffreestanding; the include is not).  crt-decls is
#         compile-time-only and never installed into the sysroot.
#
#   [2/2] libunwind + libc++abi + libc++ (static) -- GATED on a C
#         library being installed in the sysroot (marker:
#         <sysroot>/include/stdlib.h).  The C library itself is the
#         LLVM runtimes' job too: llvm-libc for WinCE (not yet
#         buildable; when it lands, build it ahead of this step and
#         install its headers+archive into the sysroot).  The C++
#         runtime stack needs it underneath (malloc, the CRT headers);
#         until then this step reports skipped rather than failing.
#
# The builtins sit on the wince-api import surface (COREDLL and friends)
# and the Akari startup objects, none of which require a C library.
#
# Usage:
#   build-wince-runtimes.sh --toolchain <dir> [--sysroot <dir>] \
#       [--target arm-pc-wince] [--build-dir <dir>]
#
#===------------------------------------------------------------------------===//

set -euo pipefail

PROGRAM="$(basename "$0")"
REPO_ROOT="$(cd "$(dirname "$0")/llvm-project" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TARGET="arm-pc-wince"
TOOLCHAIN=""
SYSROOT=""
BLD=""

while [ $# -gt 0 ]; do
  case "$1" in
    --toolchain) TOOLCHAIN="$2"; shift 2 ;;
    --sysroot)   SYSROOT="$2"; shift 2 ;;
    --target)    TARGET="$2"; shift 2 ;;
    --build-dir) BLD="$2"; shift 2 ;;
    -h|--help)   sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
    *) echo "$PROGRAM: unknown option: $1" >&2; exit 1 ;;
  esac
done

[ -n "$TOOLCHAIN" ] || { echo "$PROGRAM: --toolchain is required" >&2; exit 1; }
[ -x "$TOOLCHAIN/clang" ] || { echo "$PROGRAM: $TOOLCHAIN/clang missing" >&2; exit 1; }
if [ -z "$SYSROOT" ]; then
  SYSROOT="$TOOLCHAIN/../wince-sysroot"
fi
[ -d "$SYSROOT/lib" ] || {
  echo "$PROGRAM: no sysroot at $SYSROOT; run build-wince-sysroot.sh first" >&2
  exit 1
}
[ -n "$BLD" ] || BLD="$REPO_ROOT/build-wince-runtimes"
mkdir -p "$BLD"

CC="$TOOLCHAIN/clang"
CXX="$TOOLCHAIN/clang++"
AR="$TOOLCHAIN/llvm-ar"
RANLIB="$TOOLCHAIN/llvm-ranlib"

case "$TARGET" in
  arm*) RT_ARCH="arm" ;;
  i386*) RT_ARCH="i386" ;;
  *) echo "$PROGRAM: unsupported target $TARGET" >&2; exit 1 ;;
esac

# CMAKE_<LANG>_COMPILER_TARGET is ignored until CMake has identified the
# compiler as Clang.  Identification compiles do not pass it, so put
# --target in the language flags (CI 33352687660).
COMMON_CMAKE=(
  -G Ninja
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
  -DCMAKE_AR="$AR" -DCMAKE_RANLIB="$RANLIB"
  -DCMAKE_C_COMPILER="$CC"
  -DCMAKE_CXX_COMPILER="$CXX"
  -DCMAKE_ASM_COMPILER="$CC"
  -DCMAKE_C_COMPILER_TARGET="$TARGET"
  -DCMAKE_CXX_COMPILER_TARGET="$TARGET"
  -DCMAKE_ASM_COMPILER_TARGET="$TARGET"
)

# --- [1/2] compiler-rt builtins (the -lgcc replacement) ----------------------
echo "== [1/2] compiler-rt builtins ($RT_ARCH)"
# -ffreestanding: the builtins are the layer below any hosted runtime,
# and it compiles int_util.c's abort() down to __builtin_trap.  The
# crt-decls header answers the unconditional <stdlib.h> include.  PE
# startup comes from the sysroot's Akari crt3.o/dllcrt3.o, not ELF
# crtbegin/crtend (CI 33355649455).
CRT_DECLS="$SCRIPT_DIR/sysroot/crt-decls"
[ -f "$CRT_DECLS/stdlib.h" ] || {
  echo "$PROGRAM: $CRT_DECLS/stdlib.h missing" >&2; exit 1; }
cmake -S "$REPO_ROOT/compiler-rt/lib/builtins" -B "$BLD/builtins" \
  "${COMMON_CMAKE[@]}" \
  -DCMAKE_SYSROOT="$SYSROOT" \
  -DCMAKE_C_FLAGS="--target=$TARGET --sysroot=$SYSROOT -ffreestanding -isystem $CRT_DECLS" \
  -DCMAKE_CXX_FLAGS="--target=$TARGET --sysroot=$SYSROOT -ffreestanding -isystem $CRT_DECLS" \
  -DCMAKE_ASM_FLAGS="--target=$TARGET --sysroot=$SYSROOT -ffreestanding -isystem $CRT_DECLS" \
  -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
  -DCOMPILER_RT_BAREMETAL_BUILD=ON \
  -DCOMPILER_RT_BUILD_CRT=OFF
cmake --build "$BLD/builtins" -j "$(nproc 2>/dev/null || echo 2)"

BUILTINS_A="$(find "$BLD/builtins" -name "libclang_rt.builtins-$RT_ARCH.a" -o -name "clang_rt.builtins-$RT_ARCH.lib" | head -1)"
[ -n "$BUILTINS_A" ] || {
  echo "$PROGRAM: builtins archive not found under $BLD/builtins" >&2; exit 1; }
install -m 644 "$BUILTINS_A" "$SYSROOT/lib/libclang_rt.builtins-$RT_ARCH.a"

# --- [2/2] libunwind + libc++abi + libc++ (static) ---------------------------
# Gated on a C library in the sysroot (llvm-libc, Stage 3; the builtins'
# private crt-decls copy never enters the sysroot).  The C++ runtime
# needs a real C library underneath (malloc, the CRT headers).
if [ ! -e "$SYSROOT/include/stdlib.h" ]; then
  echo "== [2/2] libunwind + libc++abi + libc++: skipped"
  echo "        (pending the C library in the sysroot -- llvm-libc,"
  echo "         Stage 3; marker $SYSROOT/include/stdlib.h absent)"
  echo "== done:"
  ls -l "$SYSROOT/lib" | grep -E 'clang_rt|unwind|c\+\+'
  exit 0
fi

echo "== [2/2] libunwind + libc++abi + libc++"
cmake -S "$REPO_ROOT/runtimes" -B "$BLD/runtimes" \
  "${COMMON_CMAKE[@]}" \
  -DCMAKE_SYSROOT="$SYSROOT" \
  -DCMAKE_C_FLAGS="--target=$TARGET --sysroot=$SYSROOT" \
  -DCMAKE_CXX_FLAGS="--target=$TARGET --sysroot=$SYSROOT" \
  -DCMAKE_ASM_FLAGS="--target=$TARGET --sysroot=$SYSROOT" \
  -DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLIBUNWIND_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_STATIC=ON \
  -DLIBUNWIND_ENABLE_PIC=OFF \
  -DLIBUNWIND_HIDE_SYMBOLS=ON \
  -DLIBUNWIND_ENABLE_THREADS=OFF \
  -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_ENABLE_STATIC=ON \
  -DLIBCXXABI_ENABLE_PIC=OFF \
  -DLIBCXXABI_USE_COMPILER_RT=ON \
  -DLIBUNWIND_USE_COMPILER_RT=ON \
  -DLIBCXXABI_ENABLE_EXCEPTIONS=ON \
  -DLIBCXXABI_ENABLE_THREADS=OFF \
  -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_STATIC=ON \
  -DLIBCXX_ENABLE_PIC=OFF \
  -DLIBCXX_STATICALLY_LINK_ABI_IN_STATIC_LIBRARY=ON \
  -DLIBCXX_ENABLE_MONOTONIC_CLOCK=ON \
  -DLIBCXX_ENABLE_THREADS=OFF \
  -DLIBCXX_ENABLE_FILESYSTEM=ON \
  -DLIBCXX_ENABLE_WIDE_CHARACTERS=ON \
  -DLIBCXX_ENABLE_TIME_ZONE_DATABASE=OFF \
  -DLIBCXX_HERMETIC_STATIC_LIBRARY=ON

# LIBCXX_ENABLE_TIME_ZONE_DATABASE stays OFF: WinCE has no IANA tz
# database and the experimental tzdb sources #error on non-__linux__
# targets ("unknown path to the IANA Time Zone Database").
#
# LIBCXX_ENABLE_FILESYSTEM stays ON: <fstream> is gated on the filesystem
# configuration macro, and OFF turns it into an empty shell that nothing
# using ifstream can compile against.
#
# The runtimes umbrella is one Ninja graph.  Subdirs have no build.ninja
# (CI 33362273917: ninja: loading 'build.ninja' after libc++.a linked).
cmake --build "$BLD/runtimes" -j "$(nproc 2>/dev/null || echo 2)"

for lib in libunwind libc++abi libc++; do
  install -m 644 "$(find "$BLD/runtimes" -name "$lib.a" | head -1)" \
    "$SYSROOT/lib/$lib.a"
done
# C++ headers for AddClangCXXStdlibIncludeArgs (<sysroot>/include/c++/v1).
if [ -d "$BLD/runtimes/include/c++/v1" ]; then
  mkdir -p "$SYSROOT/include/c++"
  cp -r "$BLD/runtimes/include/c++/v1" "$SYSROOT/include/c++/"
fi

echo "== done:"
ls -l "$SYSROOT/lib" | grep -E 'clang_rt|unwind|c\+\+'

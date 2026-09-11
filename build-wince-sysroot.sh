#!/bin/sh
#===- build-wince-sysroot.sh - WinCE sysroot assembler --------------------===#
#
# Assembles the Windows CE sysroot from this repository's submodules:
#
#   ./wince-crt        Akari CRT: PE/COFF startup + data globals
#                      (kagurasumusun/wince-crt submodule)
#   ./wince-api        WinCE API headers + doc-derived import libraries
#                      (kagurasumusun/wince-api submodule)
#   ./pthread-win32    pthreads4w static library (optional extra; needs the
#                      C library layer, gated below)
#
# The 2026-09 stack replaces the retired CeGCC-lineage pair (mingwrt +
# w32api, whose upstream repositories are gone) with the in-house pair:
#
#   wince-crt  is the PE startup and process-glue layer (crt0/dllcrt/
#              runtime: the EXE/DLL entry points and the per-process
#              data globals).  It is deliberately NOT a C library
#              (malloc/printf/string stay with the consumer's C
#              library -- see its include/akari/crt.h scope note);
#              the C library layer is pending there.
#   wince-api  is the documented WinCE API surface, written from
#              scratch from the official Microsoft CE documentation:
#              MSVC-cased headers (include/) plus doc-derived import
#              libraries (def/*-doc.def -- name-only exports, no
#              ordinals, no device-dump/SDK-derived names).
#
# Driver compatibility (clang's WinCE toolchain names its own start
# files and default libraries; see clang/lib/Driver/ToolChains/WinCE.cpp
# in the llvm-project submodule).  The sysroot installs:
#
#   crt3.o dllcrt3.o        <- akari_crt0.o / akari_dllcrt.o (real names
#                              kept alongside)
#   libmingw32.a            <- libakari.a (the CRT glue archive)
#   libcoredll{,4,6}.a      <- wince-api def/coredll-doc.def (the driver
#                              probes all three spellings by CE version)
#   lib<dll>.a              <- every other def/<dll>-doc.def
#   libmingwex.a libceoldname.a libmingwthrd.a
#                           <- EMPTY placeholder archives.  The driver's
#                              default link line names them unconditionally
#                              (the CeGCC C-library supplement layers); the
#                              real content arrives with wince-crt's C
#                              library layer.  Until then a link that
#                              references their symbols fails with a clear
#                              undefined-symbol error instead of a missing
#                              file error.  See lib/PLACEHOLDERS.md.
#
# Known driver gap (2026-09-10 toolchain): -mconsole links
# /entry:mainCRTStartup (the desktop spelling); the CE-documented main()
# entry is mainACRTStartup (what Akari provides, per the /ENTRY Windows CE
# 5.0 page).  main()-based programs link fine through the default GUI
# entry (Akari's WinMainCRTStartup dispatches to whichever of
# WinMain/wWinMain/main the image defines, via weak references); pass
# -Wl,/entry:mainACRTStartup for the dedicated console-startup path
# until the driver spellings are revisited upstream.
#
# The pthread / gmon / posix extras of the old sysroot all include the C
# library headers (stdlib.h/stdio.h/string.h/errno.h/process.h), so they
# are gated on wince-crt growing that layer (marker: wince-crt's
# include/stdlib.h).  They build unchanged once the marker exists.
#
# Result layout (driver-compatible):
#   <sysroot>/include/...      wince-api headers (+ akari/ CRT headers,
#                              + generated lowercase include aliases)
#   <sysroot>/lib/
#     crt3.o dllcrt3.o         CRT startup objects (Akari)
#     akari_crt0.o akari_dllcrt.o libakari.a   (real names)
#     libcoredll{,4,6}.a       doc-derived COREDLL import libraries
#     lib<dll>.a               doc-derived import libraries (108 def files)
#     libmingw32.a             = libakari.a
#     libmingwex.a libceoldname.a libmingwthrd.a   placeholders
#     libpthread.a libgmon.a gcrt3.o libposix.a   gated extras
#
# Stage 3 (compiler-rt builtins + libunwind/libc++abi/libc++) is driven by
# build-wince-runtimes.sh.
#
# Usage:
#   build-wince-sysroot.sh --toolchain <dir> [--target <triple>] \
#       [--prefix <dir>] [--jobs N] [--keep-build]
#
#===------------------------------------------------------------------------===#

set -e

PROGRAM="$(basename "$0")"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

TARGET="arm-pc-wince"
PREFIX=""
TOOLCHAIN=""
JOBS=2
KEEP_BUILD=0

usage() {
  sed -n '2,70p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --toolchain) TOOLCHAIN="$2"; shift 2 ;;
    --target)    TARGET="$2"; shift 2 ;;
    --prefix)    PREFIX="$2"; shift 2 ;;
    --jobs)      JOBS="$2"; shift 2 ;;
    --keep-build) KEEP_BUILD=1; shift ;;
    -h|--help)   usage ;;
    *) echo "$PROGRAM: unknown option: $1" >&2; usage ;;
  esac
done

case "$TARGET" in
  arm-pc-wince*|i386-pc-wince*) ;;
  *) echo "$PROGRAM: unsupported WinCE target '$TARGET'" >&2; exit 1 ;;
esac

if [ -z "$TOOLCHAIN" ]; then
  echo "$PROGRAM: --toolchain <dir-with-clang> is required" >&2
  exit 1
fi
if [ -x "$TOOLCHAIN/clang" ]; then
  :
elif [ -x "$TOOLCHAIN/bin/clang" ]; then
  TOOLCHAIN="$TOOLCHAIN/bin"
else
  echo "$PROGRAM: clang not found under $TOOLCHAIN (build stage 1 first," >&2
  echo "  see clang/cmake/caches/WinCE.cmake)" >&2
  exit 1
fi

if [ -z "$PREFIX" ]; then
  # The WinCE toolchain driver's default sysroot location: <prefix>/wince-sysroot
  PREFIX="$TOOLCHAIN/../wince-sysroot"
fi
SYSROOT="$(cd "$(dirname "$PREFIX")" 2>/dev/null && pwd)/$(basename "$PREFIX")"

WINCECRT_SRC="$REPO_ROOT/wince-crt"
WINCEAPI_SRC="$REPO_ROOT/wince-api"
PTHREAD_SRC="$REPO_ROOT/pthread-win32"

for d in "$WINCECRT_SRC" "$WINCEAPI_SRC"; do
  if [ ! -e "$d/Makefile" ]; then
    echo "$PROGRAM: $d is missing (submodules are part of this repo;" >&2
    echo "  your checkout appears incomplete)" >&2
    exit 1
  fi
done

# --- Tools -----------------------------------------------------------------
CLANG="$TOOLCHAIN/clang"
LLVM_AR="$(ls "$TOOLCHAIN"/llvm-ar* 2>/dev/null | head -1)"
LLVM_RANLIB="$(ls "$TOOLCHAIN"/llvm-ranlib* 2>/dev/null | head -1)"
LLVM_DLLTOOL="$(ls "$TOOLCHAIN"/llvm-dlltool* 2>/dev/null | head -1)"
for t in "$LLVM_AR" "$LLVM_RANLIB" "$LLVM_DLLTOOL"; do
  [ -n "$t" ] || { echo "$PROGRAM: required LLVM binary tool missing in $TOOLCHAIN" >&2; exit 1; }
done

# The 2026-09-10 llvm-wince toolchain names a CE machine by its target
# ("llvm-dlltool -m arm-pc-wince"; the invented machine names "armwince"/
# "armce" are gone -- "[WinCE][ToolDrivers] Name a CE machine by its
# target, not an invented machine", b2851a3d).  The target triple is the
# spelling both directions accept.
DLLTOOL_MACHINE="$TARGET"

# Baseline ARMv5TE for the gated extras below.  wince-crt's Makefile
# pins -march=armv5tej itself for *-pc-wince ARM builds (WCE_ARCHFLAGS;
# the 2026-09-10 driver answers a bare CE ARM triple with the generic
# default arm7tdmi/ARMv4T, which the COFF codegen cannot lower dllimport
# calls for), so the CRT build below passes no march of its own.  An
# explicit WINCE_ARCH_FLAGS overrides everything, for experiments.
case "$TARGET" in
  arm*) ARCH_FLAGS="${WINCE_ARCH_FLAGS:--march=armv5te -mfloat-abi=soft}" ;;
  *)    ARCH_FLAGS="${WINCE_ARCH_FLAGS:-}" ;;
esac

mkdir -p "$SYSROOT/lib" "$SYSROOT/include"

echo "== WinCE sysroot: target $TARGET"
echo "== sysroot: $SYSROOT"

# --- wince-crt (Akari: startup + data globals) -------------------------------
echo "== [1/5] wince-crt (Akari CRT startup objects + glue archive)"
CRT_BUILD="$REPO_ROOT/build-wince-crt"
rm -rf "$CRT_BUILD"
mkdir -p "$CRT_BUILD"
# Out of tree: the CRT's Makefile builds in-place per checkout; copy the
# sources so the submodule checkout stays clean.
cp -r "$WINCECRT_SRC/." "$CRT_BUILD/"
(
  cd "$CRT_BUILD"
  make clean >/dev/null 2>&1 || true
  make TARGET="$TARGET" CC="$CLANG" AR="$LLVM_AR" \
       ARCHFLAGS="${WINCE_ARCH_FLAGS:-}" \
       > "$REPO_ROOT/build-wince-crt.log" 2>&1 || {
    tail -40 "$REPO_ROOT/build-wince-crt.log" >&2; exit 1; }
)
CRT_B="$CRT_BUILD/build"
for f in "$CRT_B/akari_crt0.o" "$CRT_B/akari_dllcrt.o" "$CRT_B/libakari.a"; do
  [ -s "$f" ] || { echo "$PROGRAM: wince-crt did not produce $f" >&2; exit 1; }
done
# Real names + the driver-compat names, one archive content each.
install -m 644 "$CRT_B/akari_crt0.o" "$SYSROOT/lib/akari_crt0.o"
install -m 644 "$CRT_B/akari_crt0.o" "$SYSROOT/lib/crt3.o"
install -m 644 "$CRT_B/akari_dllcrt.o" "$SYSROOT/lib/akari_dllcrt.o"
install -m 644 "$CRT_B/akari_dllcrt.o" "$SYSROOT/lib/dllcrt3.o"
install -m 644 "$CRT_B/libakari.a" "$SYSROOT/lib/libakari.a"
install -m 644 "$CRT_B/libakari.a" "$SYSROOT/lib/libmingw32.a"
mkdir -p "$SYSROOT/include/akari"
install -m 644 "$WINCECRT_SRC/include/akari/compiler.h" "$SYSROOT/include/akari/"
install -m 644 "$WINCECRT_SRC/include/akari/crt.h" "$SYSROOT/include/akari/"

# --- wince-api (doc-derived headers + import libraries) ----------------------
echo "== [2/5] wince-api (WinCE API headers + doc-derived import libraries)"
API_DEF="$WINCEAPI_SRC/def"
[ -d "$API_DEF" ] || { echo "$PROGRAM: $API_DEF missing" >&2; exit 1; }
n_libs=0
for f in "$API_DEF"/*-doc.def; do
  [ -e "$f" ] || continue
  b="$(basename "$f" -doc.def)"
  "$LLVM_DLLTOOL" -m "$DLLTOOL_MACHINE" -d "$f" \
    -l "$SYSROOT/lib/lib$b.a" >/dev/null 2>&1 || {
    echo "$PROGRAM: llvm-dlltool failed on $f" >&2; exit 1; }
  n_libs=$((n_libs + 1))
done
# The driver asks for the coredll import library by CE-version-dependent
# spelling (libcoredll.a for CE 5, libcoredll4.a for CE 4, libcoredll6.a
# for CE 6+); the doc-derived surface is version-agnostic, so every
# spelling resolves to the same library.
for alt in libcoredll4.a libcoredll6.a; do
  install -m 644 "$SYSROOT/lib/libcoredll.a" "$SYSROOT/lib/$alt"
done
# Headers: wince-api's are MSVC-cased (Windows.h), self-contained.
cp -r "$WINCEAPI_SRC/include/." "$SYSROOT/include/"
# Lowercase include aliases: CeGCC-lineage sources #include <windows.h>
# (lowercase), and the Linux build host's lookup is case-sensitive.  A
# forwarder per spelling whose lowercase form is absent.  On a
# case-insensitive host the lowercase name IS the header, so the -e test
# skips them (and overwriting the canonical file would be wrong).
n_alias=0
for h in "$WINCEAPI_SRC"/include/*.h; do
  b="$(basename "$h")"
  lb="$(printf '%s' "$b" | tr 'A-Z' 'a-z')"
  [ "$lb" = "$b" ] && continue
  [ -e "$SYSROOT/include/$lb" ] && continue
  printf '#pragma once\n/* lowercase include alias; canonical spelling: %s */\n#include "%s"\n' \
    "$b" "$b" > "$SYSROOT/include/$lb"
  n_alias=$((n_alias + 1))
done
echo "   import libraries: $n_libs  (+coredll aliases; $n_alias lowercase include aliases)"

# --- driver-compat placeholder archives --------------------------------------
echo "== [3/5] driver-compat placeholders (C-library layers pending in wince-crt)"
"$LLVM_AR" rcs "$SYSROOT/lib/libmingwex.a"
"$LLVM_RANLIB" "$SYSROOT/lib/libmingwex.a"
"$LLVM_AR" rcs "$SYSROOT/lib/libceoldname.a"
"$LLVM_RANLIB" "$SYSROOT/lib/libceoldname.a"
"$LLVM_AR" rcs "$SYSROOT/lib/libmingwthrd.a"
"$LLVM_RANLIB" "$SYSROOT/lib/libmingwthrd.a"
cat > "$SYSROOT/lib/PLACEHOLDERS.md" <<'EOF'
# Placeholder archives

`libmingwex.a`, `libceoldname.a` and `libmingwthrd.a` are EMPTY.  The
WinCE clang driver's default link line names them unconditionally (they
were the CeGCC-lineage C-library supplement / old-name-redirect / thread
-glue layers of the retired mingwrt stack).  Their real content is
pending in the wince-crt C library layer (see wince-crt's
include/akari/crt.h scope note: Akari is the startup layer, the C
library is the consumer's).

Until that layer lands, a program that references their symbols fails
at link time with a clear `undefined symbol` error (e.g. `strlen`,
`_stricmp`) rather than a missing-file error.  A Win32-API-only program
links and runs.
EOF

# --- gated extras (need the C library layer) ---------------------------------
# Marker: wince-crt growing the C library means it ships the CRT headers
# first (stdlib.h & friends).  Everything below includes them.
C_LIBRARY_MARKER="$WINCECRT_SRC/include/stdlib.h"

if [ -e "$C_LIBRARY_MARKER" ]; then
  echo "== [4/5] pthread-win32 (pthreads4w static library)"
  PTHREAD_BUILD="$REPO_ROOT/build-wince-pthread"
  rm -rf "$PTHREAD_BUILD"
  mkdir -p "$PTHREAD_BUILD"
  PTHREAD_CFLAGS="--target=$TARGET $ARCH_FLAGS -O2 -g0 -fno-ident \
 -fms-extensions -std=c17 -nostdinc \
 -isystem $WINCECRT_SRC/include -isystem $SYSROOT/include \
 -I $PTHREAD_SRC -DHAVE_CONFIG_H \
 -D_MT -DPTW32_STATIC_LIB -D__CLEANUP_C -D__PTHREAD_JUMBO_BUILD__"
  # PTW32_CLEANUP_C: structured-exception unwinding does not exist on WinCE;
  # the setjmp/longjmp C cleanup variant is the supported configuration.
  (cd "$PTHREAD_BUILD" && \
   $CLANG $PTHREAD_CFLAGS -c "$PTHREAD_SRC/pthread.c" -o pthread.o) \
   > "$REPO_ROOT/build-wince-pthread.log" 2>&1 || \
   { tail -30 "$REPO_ROOT/build-wince-pthread.log" >&2; exit 1; }
  "$LLVM_AR" rcs "$SYSROOT/lib/libpthread.a" "$PTHREAD_BUILD/pthread.o"
  "$LLVM_RANLIB" "$SYSROOT/lib/libpthread.a"
  for h in pthread.h sched.h semaphore.h _ptw32.h need_errno.h; do
    install -m 644 "$PTHREAD_SRC/$h" "$SYSROOT/include/$h"
  done

  echo "== [5/5] gmon (-pg) + posix shim"
  for part in gmon posix; do
    SRC="$REPO_ROOT/sysroot/$part"
    BLD="$REPO_ROOT/build-wince-$part"
    rm -rf "$BLD"; mkdir -p "$BLD"
    CFLAGS_X="--target=$TARGET $ARCH_FLAGS -O2 -g0 -fno-ident \
 -fms-extensions -std=c17 -nostdinc \
 -isystem $WINCECRT_SRC/include -isystem $SYSROOT/include \
 -iwithprefixbefore include -I $SRC"
    for c in "$SRC"/*.c; do
      (cd "$BLD" && $CLANG $CFLAGS_X -c "$c" -o "$(basename "$c" .c).o") \
        >> "$REPO_ROOT/build-wince-$part.log" 2>&1 || \
        { tail -30 "$REPO_ROOT/build-wince-$part.log" >&2; exit 1; }
    done
  done
  install -m 644 "$REPO_ROOT/build-wince-gmon/gcrt3.o" "$SYSROOT/lib/gcrt3.o"
  "$LLVM_AR" rcs "$SYSROOT/lib/libgmon.a" "$REPO_ROOT/build-wince-gmon/libgmon.o"
  "$LLVM_RANLIB" "$SYSROOT/lib/libgmon.a"
  "$LLVM_AR" rcs "$SYSROOT/lib/libposix.a" \
    "$REPO_ROOT/build-wince-posix/process.o" \
    "$REPO_ROOT/build-wince-posix/popen.o" \
    "$REPO_ROOT/build-wince-posix/signal.o"
  "$LLVM_RANLIB" "$SYSROOT/lib/libposix.a"
  mkdir -p "$SYSROOT/include/sys"
  install -m 644 "$REPO_ROOT/sysroot/posix/sys/wait.h" "$SYSROOT/include/sys/wait.h"
else
  echo "== [4/5] pthread-win32: skipped (pending the wince-crt C library layer;"
  echo "        marker wince-crt/include/stdlib.h absent)"
  echo "== [5/5] gmon + posix shim: skipped (same marker)"
fi

# --- summary -----------------------------------------------------------------
echo "== done: $SYSROOT"
ls -l "$SYSROOT/lib" | head -30
echo "   next: build-wince-runtimes.sh --toolchain $TOOLCHAIN --sysroot $SYSROOT"

if [ "$KEEP_BUILD" = 0 ]; then
  rm -rf "$CRT_BUILD" "$REPO_ROOT/build-wince-pthread" \
         "$REPO_ROOT/build-wince-gmon" "$REPO_ROOT/build-wince-posix"
fi

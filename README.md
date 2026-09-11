# cellvm-build — Windows CE full toolchain build

Builds the complete Windows CE cross toolchain and its proof-of-life
stages, in the [cegcc-build](https://github.com/salman-javed-nz/cegcc-build)
style: **submodules + build scripts + CI**.

* **Target**: Windows Embedded CE 6.0 (CE 5.0/4.x selectable), 32-bit ARM,
  ARMv5TE / `armel` ABI (little-endian, soft-float, AAPCS).
* **Compiler side**: LLVM/Clang/LLD with a WinCE driver and COFF/CE
  support — this repository's `llvm-project` submodule (branch
  `llvm-wince`).
* **CRT**: **wince-crt** (the `wince-crt` submodule) — the Akari CRT:
  PE/COFF startup objects (`crt3.o`/`dllcrt3.o` real names
  `akari_crt0.o`/`akari_dllcrt.o`) and the per-process data globals
  (`libakari.a`).  Akari is deliberately **not a C library**
  (malloc/printf/string stay with the consumer's C library — see its
  `include/akari/crt.h` scope note).  The C library itself comes from
  **Stage 3: the LLVM runtimes** (llvm-libc for C, libc++ for C++),
  built by `build-wince-runtimes.sh` from the llvm-project submodule;
  the pipeline gates on it landing in the sysroot (below).
* **API layer**: **wince-api** (the `wince-api` submodule) — the
  documented WinCE API surface, written from scratch from the official
  Microsoft CE documentation: MSVC-cased headers (`include/`) and
  doc-derived import libraries (`def/*-doc.def`, name-only exports, no
  ordinals, no device-dump/SDK-derived names).
* **Threads**: static **pthread-win32** (optional extra, gated on the
  C library layer).
* **In-house sysroot code**: `sysroot/` (the `-pg` gmon sampler, the
  posix shim, the include overlay, the compiler-rt build declarations).

The 2026-09 stack replaces the retired CeGCC-lineage pair (mingwrt +
w32api; their upstream repositories are gone) with the in-house pair
above.

## Repository layout

```
llvm-project/   submodule, kagurasumusun/llvm-project @ llvm-wince
                (WinCE driver, cmake cache, lld/COFF CE support, lit tests;
                compiler-side CI gate lives there)
wince-crt/      submodule, kagurasumusun/wince-crt @ main
                (Akari CRT: startup objects + data globals)
wince-api/      submodule, kagurasumusun/wince-api @ main
                (WinCE API headers + doc-derived import libraries)
pthread-win32/  submodule, kagurasumusun/pthread-win32 @ master
sysroot/
  crt-decls/      compile-time declarations for the compiler-rt builtins
                  build only (never installed into the sysroot)
  gmon/           -pg sampling profiler (gcrt3.c, libgmon.c)   [gated*]
  posix/          execv/execl(p)/system/waitpid/popen/pclose/signal/alarm [gated*]
  include-overlay/  headers overlaid last (sal.h)
  gen-include-aliases.py  emit case-alias forwarders for an app tree's
                  #include spellings (run by Stage 5)
build-wince-sysroot.sh      Stage 2: assemble the sysroot from the submodules
build-wince-runtimes.sh     Stage 3: compiler-rt builtins (required) +
                            libunwind/libc++abi/libc++ (gated*)
build-easyrpg-player.sh     Stage 5: EasyRPG Player deps + player [gated*]
bind-cegcc-names.sh         install arm-mingw32ce-* tool names in a bin dir
audit-coredll.py            doc-surface coverage readout vs a device dumpbin
armasm/armasm-convert.py    ARM assembly (armasm) -> GNU as converter
easyrpg-player/             MaxSignal/Player Makefile overlay (no audio)
.github/workflows/cellvm-build.yml   full-pipeline CI (Stage 1-5)
```

## The pipeline

```
stage 1  clang/lld/llvm-tools host build     (llvm-project, WinCE cmake cache)
         WinCE lit gate (the fork's test set, count-asserted)
stage 2  gates: wince-api check + crosscheck (fresh clang, 6 WinCE targets),
         wince-crt check (host parser self-test)
stage 2  sysroot: wince-crt + wince-api + driver-compat installs
         (build-wince-sysroot.sh; C-library extras gated*)
         driver-default link proof: EXE(WinMain) + EXE(main) + DLL
stage 3  compiler-rt builtins (required) + end-to-end link smoke with the
         real builtins (division -> __aeabi_idiv)   (build-wince-runtimes.sh)
         libunwind/libc++abi/libc++                  [gated*]
packaging + install/compile sanity check
stage 4  unmodified TECLIB/glpi-wince-agent (their Makefile)     [gated*]
stage 5  MaxSignal/EasyRPG Player 0.6.2.3-wince (Makefile overlay) [gated*]
```

Stage 1 is also run as the compiler-side CI gate in `llvm-project`
itself; this repository's CI runs the whole pipeline end to end.

### The C-library gate

The C library is the LLVM runtimes' job, not wince-crt's: llvm-libc
for C and libc++ for C++ are Stage 3 (`build-wince-runtimes.sh`).  The
C++ stack needs the C library underneath it, and llvm-libc does not
build for WinCE yet, so everything that needs a C library — the
pthread/gmon/posix sysroot extras (Stage 2), the libunwind/libc++abi/
libc++ stack (Stage 3) and the two third-party application stages (4/5)
— is gated on the marker `<sysroot>/include/stdlib.h` (installed once
llvm-libc lands).  Until then those steps print `skipped (pending the
C library)` instead of failing, and a **Win32-API-only program links
and runs through the bare driver line today**
(`clang --target=arm-pc-wince -o app.exe app.c`).

### Driver compatibility

The WinCE clang driver names its own start files and default libraries
(see `clang/lib/Driver/ToolChains/WinCE.cpp` in the llvm-project
submodule).  The sysroot installs: `crt3.o`/`dllcrt3.o` (from Akari),
`libmingw32.a` (= `libakari.a`), `libcoredll{,4,6}.a` (from wince-api's
`def/coredll-doc.def`; the driver probes all three spellings by CE
version), one `lib<dll>.a` per doc def file, and **empty placeholder
archives** for `libmingwex.a`/`libceoldname.a`/`libmingwthrd.a` (the
retired CeGCC C-library supplement layers; a link referencing their
symbols fails with a clear `undefined symbol` error — see
`lib/PLACEHOLDERS.md` in the assembled sysroot).

Known driver gap (2026-09-10 toolchain): `-mconsole` links
`/entry:mainCRTStartup` (the desktop spelling); the CE-documented
`main()` entry is `mainACRTStartup` (what Akari provides).  `main()`
programs link fine through the default GUI entry — Akari's
`WinMainCRTStartup` dispatches to whichever of WinMain/wWinMain/main
the image defines — and the dedicated console path is available with
`-Wl,/entry:mainACRTStartup`.

The 2026-09-10 llvm-wince toolchain also names a CE machine by its
target (`llvm-dlltool -m arm-pc-wince`); the invented machine names
(`armwince`/`armce`) are gone, and the driver answers a bare CE ARM
triple with the generic default `arm7tdmi` (ARMv4T), so the ARM core is
asked for by option (wince-crt's Makefile pins `-march=armv5tej`
itself; `build-wince-sysroot.sh` passes `-march=armv5te
-mfloat-abi=soft` for the gated extras).

## Building locally

Prerequisites: cmake ≥ 3.20, ninja, a C/C++ host compiler, `mold`
(`ld.mold`), `zstd`, `autoconf/automake/libtool` (for the Stage-5 deps),
`curl`, `unzip`.

```sh
git clone --recurse-submodules https://github.com/kagurasumusun/cellvm-build.git
cd cellvm-build

# Stage 1: host toolchain (this builds the pinned llvm-project submodule)
cmake -G Ninja -S llvm-project/llvm -B build \
  -C llvm-project/clang/cmake/caches/WinCE.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PWD/install/wince-llvm" \
  -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON
cmake --build build --target clang lld llc \
  llvm-ar llvm-ranlib llvm-dlltool llvm-nm llvm-mc llvm-readobj \
  llvm-objdump llvm-objcopy llvm-rc llvm-config
cmake --build build --target install-clang install-clang-resource-headers install-lld
BIN="$PWD/install/wince-llvm/bin"
ln -sf clang  "$BIN/clang++"; ln -sf clang "$BIN/clang-cl"
ln -sf lld    "$BIN/lld-link"

# Stage 2: sysroot (built into install/wince-llvm/wince-sysroot)
sh build-wince-sysroot.sh --toolchain "$BIN" --target arm-pc-wince \
  --prefix "$PWD/install/wince-llvm/wince-sysroot"

# Stage 3: compiler runtimes (builtins required; C++ stack gated)
bash build-wince-runtimes.sh --toolchain "$BIN" \
  --sysroot "$PWD/install/wince-llvm/wince-sysroot"

# Smoke test: the bare driver line, Win32-API-only program
printf '#include <Windows.h>\nint WINAPI WinMain(HINSTANCE h, HINSTANCE p, LPWSTR c, int s){ Sleep(1); return 0; }\n' > app.c
"$BIN/clang" --target=arm-pc-wince -o app.exe app.c
```

The toolchain is then a self-contained prefix:
`install/wince-llvm/{bin,lib,include,wince-sysroot}` with the Akari
startup objects, the doc-derived import libraries and GNU-spelled
library names (`libcoredll.a`, `libws2.a`, ...).
`bind-cegcc-names.sh "$BIN"` adds the `arm-mingw32ce-gcc` style names
that unmodified CeGCC Makefiles already use (they only bind
`--target=arm-pc-wince`).

## CI

`.github/workflows/cellvm-build.yml` runs the full pipeline on every
push (all branches; the work line is `main`) and on manual dispatch, on
ubuntu-24.04, with ccache + Ninja build-directory caching.  It uploads
the toolchain tarball plus whatever gated stages produced.  Submodule
pins are bumped to states the compiler-side CI (llvm-project Stage 1 +
WinCE lit gate) has already passed.

## Documentation

The authoritative compiler-side specs live in the `llvm-project`
submodule:

* `llvm-project/utils/wince/README.md` — full design, audits, verification
  status, scope/non-goals (read this first).
* `llvm-project/WINCE-HANDOFF.md` — handoff record.
* `llvm-project/utils/wince/STATUS.md` — current green state.

For the sysroot stack: `wince-api/docs/` (clean-room source policy,
per-milestone inventory) and `wince-crt/README.md` (CRT scope and the
official-doc basis of every startup behavior).

## Policies

* **COREDLL import surface**: `wince-api/def/coredll-doc.def` is the
  single source (documented names only).  The old two-repository def
  mirror (mingwrt ↔ w32api) is retired with the pair;
  `audit-coredll.py` is now a coverage readout of that doc surface
  against device dumps — informational only, it must not feed the def
  (wince-api's source policy bans device-dump/SDK-derived names).
* **#include case**: every wince-api header ships under its documented
  dominant Header-row spelling (`Windows.h`, `aygshell.h`, `bt_ddi.h`,
  ...; the M72 evidence method) — one file per header, no case or name
  forwarder aliases (wince-api M100).  Third-party app trees with
  other spellings generate their own aliases at their build time via
  `gen-include-aliases.py` (their build, not the sysroot).
* **Driver-compat placeholders**: empty archives under their CeGCC
  names, documented in the sysroot's `lib/PLACEHOLDERS.md`; the real
  content arrives with wince-crt's C library layer.

## Verification status

**Win32-API-only programs link through the bare driver default line:
EXE (WinMain), EXE (main, via Akari's weak dispatch) and DLL — PE
verified `IMAGE_FILE_MACHINE_ARM`, subsystem
`IMAGE_SUBSYSTEM_WINDOWS_CE_GUI`, coredll.dll imports.**  compiler-rt
builtins build against the stack (Stage 3, required gate); the C
library (llvm-libc), the C++ runtime stack and the two application
stages are gated until llvm-libc builds for WinCE.

Historical: the retired mingwrt+w32api stack linked the EasyRPG Player
end to end (run 33600018503, `c83b9f4`); that bar returns when the C
library layer lands.  CI compiles and links; **on-device execution is
not verified** (no CE hardware in the loop).

# cellvm-build — Windows CE full toolchain build

Builds the complete Windows CE cross toolchain and its proof-of-life
applications, in the [cegcc-build](https://github.com/salman-javed-nz/cegcc-build)
style: **submodules + build scripts + CI**.

* **Target**: Windows Embedded CE 6.0 (CE 5.0/4.x selectable), 32-bit ARM,
  ARMv5TE / `armel` ABI (little-endian, soft-float, AAPCS), default CPU
  `arm926ej-s` (i.MX28).
* **Compiler side**: LLVM/Clang/LLD with a WinCE driver and COFF/CE
  support — this repository's `llvm-project` submodule (branch `llvm-wince`).
* **CRT**: the CeGCC-lineage **mingwrt + w32api** (the `mingwrt` / `w32api`
  submodules), built with their own `configure`/`make` using Clang in place
  of GCC and LLVM tools in place of binutils. No bespoke CRT.
* **Threads**: static **pthread-win32** (optional extra, linked only with
  `-mthreads`).
* **In-house sysroot code**: `sysroot/` (the `-pg` gmon sampler, the posix
  shim, the include overlay).

## Repository layout

```
llvm-project/   submodule, kagurasumusun/llvm-project @ llvm-wince
                (WinCE driver, cmake cache, lld/COFF CE support, lit tests;
                compiler-side CI gate lives there)
mingwrt/        submodule, kagurasumusun/mingwrt @ master
w32api/         submodule, kagurasumusun/w32api @ wip
pthread-win32/  submodule, kagurasumusun/pthread-win32 @ master
sysroot/
  gmon/           -pg sampling profiler (gcrt3.c, libgmon.c)
  posix/          execv/execl(p)/system/waitpid/popen/pclose/signal/alarm + sys/wait.h
  include-overlay/  headers overlaid last (SAL, intrin.h)
build-wince-sysroot.sh      Stage 2: assemble the sysroot from the submodules
build-wince-runtimes.sh     Stage 3: compiler-rt builtins + libunwind/libc++abi/libc++
build-easyrpg-player.sh     Stage 5: EasyRPG Player deps + player (official zip)
bind-cegcc-names.sh         install arm-mingw32ce-* tool names in a bin dir
audit-coredll.py            verify COREDLL import surface vs a device dumpbin
armasm/armasm-convert.py    ARM assembly (armasm) -> GNU as converter
easyrpg-player/             MaxSignal/Player Makefile overlay (no audio)
.github/workflows/cellvm-build.yml   full-pipeline CI (Stage 1-5)
```

## The pipeline

```
stage 1  clang/lld/llvm-tools host build     (llvm-project, WinCE cmake cache)
stage 2  sysroot: mingwrt + w32api + pthread (build-wince-sysroot.sh)
stage 3  compiler-rt + libunwind/libc++abi/libc++  (build-wince-runtimes.sh)
stage 4  unmodified TECLIB/glpi-wince-agent (their Makefile)     [CI]
stage 5  MaxSignal/EasyRPG Player 0.6.2.3-wince (Makefile overlay) [CI]
```

Stage 1 is also run as the compiler-side CI gate in `llvm-project` itself;
this repository's CI runs the whole pipeline end to end.

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

# Stage 3: compiler runtimes (builtins, libunwind, libc++abi, libc++)
bash build-wince-runtimes.sh --toolchain "$BIN" \
  --sysroot "$PWD/install/wince-llvm/wince-sysroot"

# Smoke test
"$BIN/clang" --target=arm-pc-wince -c -x c /dev/null -o /dev/null
"$BIN/clang" --target=arm-pc-wince -### -x c /dev/null
```

The toolchain is then a self-contained prefix:
`install/wince-llvm/{bin,lib,include,wince-sysroot}` with GNU-named
libraries (`libmingw32.a`, `libcoredll.a`, `libc++.a`, ...).
`bind-cegcc-names.sh "$BIN"` adds the `arm-mingw32ce-gcc` style names that
unmodified CeGCC Makefiles already use (they only bind `--target=arm-pc-wince`).

## CI

`.github/workflows/cellvm-build.yml` runs the full pipeline on every push to
`main` (and on manual dispatch), on ubuntu-24.04, with ccache + Ninja
build-directory caching. It uploads the toolchain tarball, the
glpi-wince-agent and the EasyRPG Player builds.

## Documentation

The authoritative specs live in the `llvm-project` submodule:

* `llvm-project/utils/wince/README.md` — full design, audits, verification
  status, scope/non-goals (read this first).
* `llvm-project/WINCE-HANDOFF.md` — handoff record (§14 = this
  reorganization).
* `llvm-project/utils/wince/STATUS.md` — current green state.

## Verification status

CI compiles and links; **on-device execution is not yet verified** (no CE
hardware in the loop). See the llvm-project docs above for the per-feature
verification matrix.

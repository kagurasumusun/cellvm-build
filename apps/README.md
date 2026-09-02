# apps/ — non-EasyRPG WinCE demo apps (LLVM/Clang llvm-wince chain)

Small, self-contained Windows CE 6 / ARMv5TE GUI executables used as build
and launch-test targets besides EasyRPG Player. They only import from
`COREDLL.dll` (GDI) so they link with the bare CRT + w32api sysroot.

| app | what it is |
|---|---|
| `hellowince/` | minimal Win32 window painting "Hello WinCE 6" |
| `chip8/` | CHIP-8 interpreter ("emulator" demo), embedded IBM-logo ROM, GDI 64x32 render |

Build: `build-wince-demo-apps.sh`.

> Launch note (PW-AJ2 / 4th-gen): these clang-built EXEs carry `.ARM.exidx` but
> **no `.pdata`**, so they cannot pass the official `wceprj` gate (which requires
> `.pdata`) and must be started via the **exeopener** route
> (`AppMain.exe`=exeopener whitelist[0] wrapper + `AppMain_.exe`=payload),
> exactly like the EasyRPG Player build. See the PHASE1 report.

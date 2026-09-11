#!/usr/bin/env python3
"""
audit-coredll.py - coverage readout of the doc-derived COREDLL import
surface against a real device's export list.

Usage:
    dumpbin /EXPORTS coredll.dll > coredll.txt      # on a Windows host,
    # or copy CoreDLL.dll from the device (\Windows) and dump it
    python3 audit-coredll.py coredll.txt [more-dumps...]

The sysroot's COREDLL import library is built from wince-api's
def/coredll-doc.def -- the DOCUMENTED surface only (every name is on an
official CE reference page; no device-dump/SDK/shared-source name is in
it, by that project's source policy).  This audit does not and must not
feed the def; it reports:
  * device exports the documented surface does not carry (the device's
    undocumented surface -- informational: the CRT functions live here
    on real devices, and are the wince-crt C library layer's problem,
    not wince-api's),
  * documented names a given device does not export (candidates for a
    CE-version/OEM note on the def; CE OEM variation means a name
    missing from ONE device's dump is not necessarily wrong - cross-
    check several devices/generations).

The 2010-era CE5/WM6 dump used for the original (pre-wince-api) audit
is archived at
https://www.cnblogs.com/lucienbao/archive/2010/10/29/wince_coredll.html
(1799 functions).  A dump from YOUR device is the authoritative source
for OEM-specific surfaces.
"""

import sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(HERE)
DEFS = (os.path.join(REPO, "wince-api/def/coredll-doc.def"),)


def def_names(paths):
    names = set()
    for p in paths:
        for line in open(p, encoding="latin1"):
            line = line.strip()
            if line and not line.startswith(";") \
               and not line.upper().startswith("LIBRARY") \
               and not line.upper().startswith("EXPORTS") \
               and " " not in line:
                names.add(line)
    return names


def dump_names(path):
    """Parse `dumpbin /EXPORTS` output (ordinal + name lines, or .def-style
    plain name lists)."""
    names = set()
    started = False
    for line in open(path, encoding="latin1", errors="replace"):
        line = line.strip()
        if line.upper().startswith("EXPORTS") or line == "ordinal    name":
            started = True
            continue
        if not started or not line:
            continue
        toks = line.split()
        # dumpbin: "<ordinal> <hint> <rva> <name>" or "<ordinal> <name>"
        if toks[0].isdigit():
            if len(toks) >= 2 and not toks[1].isdigit():
                names.add(toks[-1] if len(toks) >= 4 else toks[1])
            continue
        if len(toks) == 1 and not toks[0][0].isdigit():
            names.add(toks[0])
    return names


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    defs = def_names(DEFS)
    dumps = set()
    for arg in sys.argv[1:]:
        dumps |= dump_names(arg)
    missing = sorted(dumps - defs)
    extra = sorted(defs - dumps)
    print(f"dump exports: {len(dumps)}   def entries: {len(defs)}")
    print(f"\n== device exports not in the documented surface ({len(missing)}):")
    for n in missing:
        print("  ", n)
    print(f"\n== documented names this device does not export ({len(extra)}) - OEM variation;")
    print("   cross-check before removing:")
    for n in extra:
        print("  ", n)
    sys.exit(1 if missing else 0)


if __name__ == "__main__":
    main()

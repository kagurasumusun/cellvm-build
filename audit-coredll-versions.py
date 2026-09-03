#!/usr/bin/env python3
"""
audit-coredll-versions.py - per-CE-version COREDLL import-surface audit.

Complements audit-coredll.py (which unions the defs against ONE device dump and
so cannot see version skew).  This tool audits each vendored def against the
authoritative source/dump for ITS OWN CE generation and flags cross-version
mixing/contamination:

  1. CE6 source audit: parse the CE 6.0 shared-source coredll export surface
     (core_common.def + crt/corelib1.def, ARM-retail policy) and report any
     export the source declares that coredll6.def lacks (a real deficiency).
  2. Version monotonicity: CE4.2 <= CE5.0 <= CE6.0 (APIs accumulate).  Names in
     an older def but absent from a newer one are either (a) genuinely retired /
     moved to k.coredll by the CE6 kernel split, or (b) contamination.  Each is
     listed for review against MSDN's per-version "OS Versions" tag.
  3. MSDN-floor check: a small set of exports MSDN documents as "coredll, Windows
     CE 1.0 and later" (so present on EVERY generation) that device/SDK dumps
     are known to omit; assert every def carries them.

Usage:
    audit-coredll-versions.py MINGWRT_DIR [CE600_CORE_COMMON DEF CE600_CORELIB1 DEF]

Exit status: 1 if any deficiency (missing source export, or a MSDN-floor export
absent from a def) is found; 0 otherwise.  Mixing candidates are advisory.
"""
import os
import re
import sys

# --- ARM-retail coredll preprocessor context (CE6 shared source) -------------
DEFINED = {"COREDLL_DEF", "_ARM_", "ARM", "UNDER_CE", "_WIN32", "_WIN32_WCE"}

# Exports MSDN documents as coredll, "Windows CE 1.0 and later" -> every def
# must carry them.  Device/SDK dumps are known to omit the TLS pair (the CE 5.0
# coredll.def header records restoring them); clang's emulated TLS imports them.
MSDN_FLOOR = ["TlsAlloc", "TlsFree", "TlsGetValue", "TlsSetValue"]


def _is_defined(sym):
    return sym in DEFINED


def _eval_expr(expr):
    e = expr.strip()
    e = re.sub(r"defined\s*\(\s*([A-Za-z_]\w*)\s*\)",
               lambda m: "T" if _is_defined(m.group(1)) else "F", e)
    e = re.sub(r"defined\s+([A-Za-z_]\w*)",
               lambda m: "T" if _is_defined(m.group(1)) else "F", e)
    e = re.sub(r"\b([A-Za-z_]\w*)\b",
               lambda m: "T" if _is_defined(m.group(1)) else "F", e)
    e = e.replace("!", " not ").replace("&&", " and ").replace("||", " or ")
    e = re.sub(r"\bT\b", "True", e)
    e = re.sub(r"\bF\b", "False", e)
    try:
        return bool(eval(e, {"__builtins__": {}}, {}))
    except Exception:
        return True


def _strip_macros(line):
    if re.search(r"\bKCOREDLL_ONLY\s*\(", line):
        line = re.sub(r"\bKCOREDLL_ONLY\s*\(([^()]*)\)", "", line)
    line = re.sub(r"\bCOREDLL_ONLY\s*\(([^()]*)\)", r"\1", line)
    line = re.sub(r"\bCRT2\s*\(\s*([\w?@.$]+)\s*,[^)]*\)", r"\1", line)
    line = re.sub(r"\bFP_CRT2\s*\(\s*([\w?@.$]+)\s*,[^)]*\)", r"\1", line)
    line = re.sub(r"\bCRT\s*\(\s*([\w?@.$]+)\s*\)", r"\1", line)
    line = re.sub(r"\bFP_CRT\s*\([^,()]+,\s*([\w?@.$]+)\s*\)", r"\1", line)
    return line


def _extract_names(line):
    names = []
    s = line.strip()
    if not s:
        return names
    s = re.split(r"\s//|\s;", s)[0].strip()
    if not s:
        return names
    for m in re.finditer(r"\bSTDAPI\s*\(\s*([A-Za-z_?][\w?@.$]*)", s):
        names.append(m.group(1))
    if names:
        return names
    m = re.match(r"^([A-Za-z_?][\w?@.$]*)", s)
    if m and m.group(1).upper() not in (
            "LIBRARY", "EXPORTS", "STDAPI", "DEFINE", "INCLUDE"):
        names.append(m.group(1))
    return names


def parse_ce_source(path, handle_include=None):
    """Parse a CE shared-source .def for the ARM-retail coredll export surface."""
    out = set()
    stack = []
    for raw in open(path, encoding="latin1"):
        line = raw.rstrip("\r\n")
        stripped = line.strip()
        m = re.match(r"^\s*#\s*(ifdef|ifndef|if|elif|else|endif)\b(.*)$", line)
        if m:
            d, rest = m.group(1), m.group(2).strip()
            parent = all(a for a, _, _ in stack)
            if d in ("ifdef", "ifndef", "if"):
                if d == "ifdef":
                    act = _is_defined(rest.split()[0]) if rest else True
                elif d == "ifndef":
                    act = (not _is_defined(rest.split()[0])) if rest else True
                else:
                    act = _eval_expr(rest)
                stack.append((act and parent, act, parent))
            elif d == "elif" and stack:
                _, took, par = stack[-1]
                act = (not took) and _eval_expr(rest)
                stack[-1] = (act and par, took or act, par)
            elif d == "else" and stack:
                _, took, par = stack[-1]
                stack[-1] = ((not took) and par, True, par)
            elif d == "endif" and stack:
                stack.pop()
            continue
        if not all(a for a, _, _ in stack):
            continue
        if stripped.startswith("#include"):
            mm = re.search(r'#include\s*[<"]([^">]+)[">]', stripped)
            if mm and handle_include:
                out |= handle_include(mm.group(1))
            continue
        if stripped.startswith(";") or stripped.startswith("//"):
            continue
        for n in _extract_names(_strip_macros(line)):
            out.add(n)
    return out


def vendored_names(path):
    names = set()
    for line in open(path, encoding="latin1"):
        s = line.strip()
        if not s or s.startswith(";"):
            continue
        if s.upper().startswith(("LIBRARY", "EXPORTS")):
            continue
        m = re.match(r"^(\S+)", s)
        if m:
            names.add(m.group(1))
    return names


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    mingwrt = sys.argv[1]
    ce4 = vendored_names(os.path.join(mingwrt, "coredll4.def"))
    ce5 = vendored_names(os.path.join(mingwrt, "coredll.def"))
    ce6 = vendored_names(os.path.join(mingwrt, "coredll6.def"))
    fail = 0

    print("== vendored def name counts ==")
    print("   CE4.2 coredll4.def : %d" % len(ce4))
    print("   CE5.0 coredll.def  : %d" % len(ce5))
    print("   CE6.0 coredll6.def : %d" % len(ce6))

    # (3) MSDN-floor: every generation must carry these.
    print("\n== MSDN-floor exports (coredll, 'CE 1.0 and later') ==")
    for label, s in (("CE4.2", ce4), ("CE5.0", ce5), ("CE6.0", ce6)):
        miss = [n for n in MSDN_FLOOR if n not in s]
        if miss:
            print("   DEFICIENCY %s missing: %s" % (label, ", ".join(miss)))
            fail = 1
        else:
            print("   %s OK (%s)" % (label, ", ".join(MSDN_FLOOR)))

    # (1) CE6 authoritative-source audit (only if the source defs are provided).
    if len(sys.argv) >= 4:
        core_common, corelib1 = sys.argv[2], sys.argv[3]
        lib1 = parse_ce_source(corelib1)
        src = parse_ce_source(
            core_common,
            handle_include=lambda n: lib1
            if n.replace("\\", "/").split("/")[-1] == "corelib1.def" else set())
        missing = sorted(src - ce6)
        print("\n== CE6 source audit (ARM-retail core_common+corelib1: %d exports) ==" % len(src))
        if missing:
            print("   DEFICIENCY: coredll6.def lacks %d source export(s):" % len(missing))
            for n in missing:
                print("      ", n)
            fail = 1
        else:
            print("   OK: coredll6.def carries every ARM-retail source export.")

    # (2) Version monotonicity / mixing (advisory).
    print("\n== version monotonicity (advisory; review vs MSDN per-version tag) ==")
    a = sorted(ce4 - ce5)
    print("   CE4.2 not in CE5.0 (%d)%s" % (len(a), ":" if a else " - OK (CE4<=CE5)"))
    for n in a:
        print("      ", n)
    b = sorted(ce5 - ce6)
    print("   CE5.0 not in CE6.0 (%d) - expect k.coredll-split kernel internals," % len(b))
    print("      CE5/WM6-only SDK names, and genuinely retired APIs:")
    for n in b:
        print("      ", n)
    return fail


if __name__ == "__main__":
    sys.exit(main())

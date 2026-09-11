/*
 * crt-decls/stdlib.h - compile-time declarations for compiler-rt builtins.
 *
 * compiler-rt's int_util.c includes <stdlib.h> under _WIN32 unconditionally
 * (the abort() call itself is compiled out under -ffreestanding, but the
 * include is not).  The wince-crt stack ships no C library headers yet
 * (Akari is the startup layer; the C library is the consumer's -- see
 * wince-crt include/akari/crt.h), so this directory supplies the missing
 * declarations to the builtins build ONLY.  It is never installed into
 * the sysroot: nothing here has an implementation behind it.
 *
 * When wince-crt grows the C library layer (its include/stdlib.h marker),
 * this directory is no longer passed to the builtins build and can be
 * deleted together with the flag that names it.
 */
#ifndef CELLVM_CRT_DECLS_STDLIB_H
#define CELLVM_CRT_DECLS_STDLIB_H

void abort(void);
void exit(int);

#endif

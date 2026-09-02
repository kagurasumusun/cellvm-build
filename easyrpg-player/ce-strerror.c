/* WinCE mingwrt/coredll gaps used by libpng and pixman. Do not patch
   those trees.  This file deliberately does NOT define strerror: the CRT
   (mingwrt coredll_stubs.c) provides it, and defining it here too made
   libcecompat.a duplicate the symbol against the always-linked CRT
   member (lld-link: duplicate symbol: strerror, Stage 5). */
#include <windows.h>

int remove(const char *path) {
  extern int unlink(const char *);
  return unlink(path);
}

HANDLE WINAPI CreateMutexA(LPSECURITY_ATTRIBUTES attr, BOOL initial, LPCSTR name) {
  wchar_t wbuf[260];
  LPCWSTR wname = NULL;
  if (name) {
    MultiByteToWideChar(CP_ACP, 0, name, -1, wbuf, 260);
    wname = wbuf;
  }
  return CreateMutexW(attr, initial, wname);
}

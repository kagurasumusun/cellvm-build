///////////////////////////////////////////////////////////////////////////////
//  wincehelper.h
//  WinCE での動作を前提としていないプログラムを
//  WinCE で動かせるようにするための自作関数
//  (C) HO_0520_IT
//  CC0, Unlicense, WTFPL Version 2, NYSL Version 0.9982
//  https://github.com/HO-0520-IT/wincehelper
///////////////////////////////////////////////////////////////////////////////

#include <cstdio>
#include <string>
#include <limits>

#ifndef WINCEHELPER__FUNC
#define WINCEHELPER__FUNC
char *wceh_getcwd(char *buffer, int maxlen);
int wceh_CHDIR(const char *dirname);
FILE *wceh_fopen(const char *filename, const char *mode);
char *get_wceh_cwd();
std::wstring stringtowidestring(std::string str);
#endif


#ifndef WINCEHELPER__M_PI
#define WINCEHELPER__M_PI
#define M_PI		3.14159265358979323846
#endif

// hellowince : minimal non-EasyRPG WinCE 6 GUI app built with the
// kagurasumusun/llvm-project (llvm-wince) clang/lld/llvm-dlltool chain.
// Target: PW-AJ2 (i.MX28, ARMv5TE, WinCE 6.0, 800x480). Loaded via exeopener.
#include <windows.h>

static const wchar_t CLASS_NAME[] = L"HelloWinCE";

LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM w, LPARAM l)
{
    switch (msg) {
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        RECT rc; GetClientRect(hWnd, &rc);
        HBRUSH bg = CreateSolidBrush(RGB(255,255,255));
        FillRect(hdc, &rc, bg);
        DeleteObject(bg);
        SetTextColor(hdc, RGB(20,40,120));
        SetBkMode(hdc, TRANSPARENT);
        DrawTextW(hdc, L"Hello WinCE 6", -1, &rc, DT_SINGLELINE|DT_CENTER|DT_VCENTER);
        EndPaint(hWnd, &ps);
        return 0;
    }
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hWnd, msg, w, l);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPWSTR, int)
{
    WNDCLASSW wc = {};
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = CLASS_NAME;
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wc.hCursor       = LoadCursorW(NULL, IDC_ARROW); // WinCE: may be NULL
    if (!RegisterClassW(&wc)) return 1;
    HWND hw = CreateWindowExW(0, CLASS_NAME, L"HelloWinCE - LLVM/Clang build",
        WS_VISIBLE|WS_CAPTION|WS_SYSMENU, 0, 0, 640, 360,
        NULL, NULL, hInst, NULL);
    if (!hw) return 2;
    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}

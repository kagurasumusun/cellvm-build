// chip8wince : a self-contained CHIP-8 interpreter ("emulator app") for
// Windows CE 6 / ARMv5TE (SHARP Brain PW-AJ2), built with the
// kagurasumusun/llvm-project (llvm-wince) clang/lld/llvm-dlltool chain.
// Renders the 64x32 CHIP-8 screen with GDI; embeds a default IBM-logo ROM so a
// launch test is deterministic without needing a ROM file on the device.
#include <windows.h>

// ---- CHIP-8 core -----------------------------------------------------------
static unsigned char mem[4096];
static unsigned char V[16];       // VF = V[15] (carry/borrow/flag)
static unsigned short I;
static unsigned short pc;
static unsigned char  disp[64*32];   // 1 = lit
static unsigned char  gfxDirty = 1;
static unsigned short stack[16]; int sp = 0;
static unsigned char  key[16];
static unsigned char  delayT, soundT;
static int stepRate = 8;           // instructions per "step", times steps/frame

static void beep(void){ /* sound disabled; see constitution: no audio yet */ }

// Classic IBM logo test ROM, 8 sprites across one row. Deterministic display.
static const unsigned char ibm_rom[] = {
    0xA2,0x1E, 0x6A,0x00, 0x6B,0x00, 0x6C,0x08, 0x6D,0x00,
    0xD2,0x1F, 0x12,0x00,
    0xF0,0x90,0x90,0x90,0xF0,
    0x20,0x60,0x20,0x20,0x70,
    0xF0,0x10,0xF0,0x80,0xF0,
    0xF0,0x10,0xF0,0x10,0xF0,
    0x90,0x90,0xF0,0x10,0x10,
    0xF0,0x80,0xF0,0x10,0xF0,
    0xF0,0x80,0xF0,0x90,0xF0,
    0xF0,0x10,0x20,0x40,0x40
};

static void rom_init(const void *data, int n){
    for(int i=0;i<0x200;i++) mem[i]=0;
    // font (digits 0-F) into 0x050
    static const unsigned char font[80]={
      0xF0,0x90,0x90,0x90,0xF0,0x20,0x60,0x20,0x20,0x70,0xF0,0x10,0xF0,0x80,0xF0,
      0xF0,0x10,0xF0,0x10,0xF0,0x90,0x90,0xF0,0x10,0x10,0xF0,0x80,0xF0,0x10,0xF0,
      0xF0,0x80,0xF0,0x90,0xF0,0xF0,0x10,0x20,0x40,0x40,0xF0,0x90,0xF0,0x90,0xF0,
      0xF0,0x90,0xF0,0x10,0xF0,0xF0,0x90,0xF0,0x90,0x90,0xE0,0x90,0xE0,0x90,0xE0,
      0xF0,0x80,0x80,0x80,0xF0,0xE0,0x90,0x90,0x90,0xE0,0xF0,0x80,0xF0,0x80,0xF0,
      0xF0,0x80,0xF0,0x80,0x80};
    for(int i=0;i<80;i++) mem[0x050+i]=font[i];
    int n0 = (data&&n>0)?n:(int)sizeof(ibm_rom);
    const unsigned char *src = (data&&n>0)?(const unsigned char*)data:ibm_rom;
    for(int i=0;i<n0 && (0x200+i)<4096;i++) mem[0x200+i]=src[i];
    for(int i=0;i<16;i++)V[i]=0;
    I=0; pc=0x200; sp=0; delayT=0; soundT=0;
    for(int i=0;i<64*32;i++)disp[i]=0;
    gfxDirty=1;
}

static void cls(){ for(int i=0;i<64*32;i++)disp[i]=0; gfxDirty=1; }

static unsigned short fetch(){ unsigned short o=(mem[pc]<<8)|mem[pc+1]; pc+=2; return o; }

// draw 8xH sprite from (I) at (x,y); returns VF=1 if collision
static void drw(int x,int y,int h){
    V[0xF]=0;
    for(int row=0;row<h;row++){
        unsigned char bits=mem[I+row];
        for(int c=0;c<8;c++){
            int px=(x+c)&63, py=(y+row)&31;
            if(bits & (0x80>>c)){
                int idx=py*64+px;
                if(disp[idx]) V[0xF]=1;
                disp[idx]^=1;
            }
        }
    }
    gfxDirty=1;
}

static void step(void){
    unsigned short op=fetch();
    unsigned char  n  = op & 0x000F;
    unsigned char  nn = op & 0x00FF;
    unsigned short nnn= op & 0x0FFF;
    unsigned char  x  =(op>>8)&0xF, y=(op>>4)&0xF;
    switch(op>>12){
        case 0x0:
            if(nn==0xE0) cls();
            else if(nn==0xEE){ if(sp>0) pc=stack[--sp]; }
            break;
        case 0x1: pc=nnn; break;
        case 0x2: if(sp<16) stack[sp++]=pc; pc=nnn; break;
        case 0x3: if(V[x]==nn) pc+=2; break;
        case 0x4: if(V[x]!=nn) pc+=2; break;
        case 0x5: if(V[x]==V[y]) pc+=2; break;
        case 0x6: V[x]=nn; break;
        case 0x7: V[x]+=nn; break;
        case 0x8:
            switch(n){
                case 0x0: V[x]=V[y]; break;
                case 0x1: V[x]|=V[y]; break;
                case 0x2: V[x]&=V[y]; break;
                case 0x3: V[x]^=V[y]; break;
                case 0x4:{ unsigned short s=V[x]+V[y]; V[0xF]=(s>255)?1:0; V[x]=s&0xFF; break;}
                case 0x5:{ V[0xF]=(V[x]>=V[y])?1:0; V[x]-=V[y]; break;}
                case 0x6:{ V[0xF]=V[x]&1; V[x]>>=1; break;}
                case 0x7:{ V[0xF]=(V[y]>=V[x])?1:0; V[x]=V[y]-V[x]; break;}
                case 0xE:{ V[0xF]=(V[x]&0x80)?1:0; V[x]<<=1; break;}
            }
            break;
        case 0x9: if(V[x]!=V[y]) pc+=2; break;
        case 0xA: I=nnn; break;
        case 0xB: pc=nnn+V[0]; break;
        case 0xC: V[x]=(unsigned char)(rand()&nn); break;
        case 0xD: drw(V[x],V[y],n); break;
        case 0xE:
            if(nn==0x9E){ if(key[V[x]&0xF]) pc+=2; }
            else if(nn==0xA1){ if(!key[V[x]&0xF]) pc+=2; }
            break;
        case 0xF:
            switch(nn){
                case 0x07: V[x]=delayT; break;
                case 0x0A: break;                 // wait key: skip (blocking)
                case 0x15: delayT=V[x]; break;
                case 0x18: soundT=V[x]; break;
                case 0x1E: I+=V[x]; break;
                case 0x29: I=0x050+V[x]*5; break;
                case 0x33: mem[I]=V[x]/100; mem[I+1]=(V[x]/10)%10; mem[I+2]=V[x]%10; break;
                case 0x55: for(int i=0;i<=x;i++) mem[I+i]=V[i]; break;
                case 0x65: for(int i=0;i<=x;i++) V[i]=mem[I+i]; break;
            }
            break;
    }
    if(delayT) delayT--;
    if(soundT){ soundT--; if(soundT==0) beep(); }
}

// ---- WinCE GUI -------------------------------------------------------------
#define SCALE 10
static const int CW = 64*SCALE;    // 640
static const int CH = 32*SCALE;    // 320
static const wchar_t CN[] = L"Chip8WinCE";
static HWND g_hwnd=0;

static void paint(HWND h){
    PAINTSTRUCT ps; HDC dc=BeginPaint(h,&ps);
    RECT rc; GetClientRect(h,&rc);
    HBRUSH bb=CreateSolidBrush(RGB(0,0,0)); FillRect(dc,&rc,bb); DeleteObject(bb);
    HBRUSH on=CreateSolidBrush(RGB(120,255,120));
    int ox=(rc.right-CW)/2; if(ox<0)ox=0;
    int oy=(rc.bottom-CH)/2; if(oy<0)oy=0;
    for(int y=0;y<32;y++){
        for(int x=0;x<64;x++){
            if(disp[y*64+x]){
                RECT r={ox+x*SCALE,oy+y*SCALE,ox+x*SCALE+SCALE,oy+y*SCALE+SCALE};
                FillRect(dc,&r,on);
            }
        }
    }
    DeleteObject(on);
    SetTextColor(dc,RGB(180,180,255)); SetBkMode(dc,TRANSPARENT);
    DrawTextW(dc,L"CHIP-8 for WinCE (LLVM/Clang)",-1,&rc,
              DT_TOP|DT_CENTER|DT_SINGLELINE);
    EndPaint(h,&ps);
}

static LRESULT CALLBACK WndProc(HWND h,UINT m,WPARAM w,LPARAM l){
    switch(m){
        case WM_PAINT: paint(h); return 0;
        case WM_TIMER:
            for(int s=0;s<stepRate;s++) step();
            if(gfxDirty){ gfxDirty=0; InvalidateRect(h,0,FALSE); }
            return 0;
        case WM_DESTROY: KillTimer(h,1); PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(h,m,w,l);
}

int WINAPI WinMain(HINSTANCE hi,HINSTANCE,LPWSTR lp,int){
    // Deterministic embedded IBM-logo demo. (A ROM file on the device can be
    // wired here later; for the emulator launch test the demo is enough.)
    rom_init(0,0);

    WNDCLASSW wc={};
    wc.lpfnWndProc=WndProc; wc.hInstance=hi; wc.lpszClassName=CN;
    wc.hbrBackground=(HBRUSH)(COLOR_WINDOW+1);
    wc.hCursor=0;
    RegisterClassW(&wc);
    HWND h=CreateWindowExW(0,CN,L"Chip8WinCE (LLVM/Clang)",
        WS_VISIBLE|WS_CAPTION|WS_SYSMENU,0,0,CW+8,CH+8,0,0,hi,0);
    if(!h) return 1;
    g_hwnd=h;
    SetTimer(h,1,16,0);
    MSG msg; while(GetMessageW(&msg,0,0,0)>0){ TranslateMessage(&msg); DispatchMessageW(&msg); }
    return (int)msg.wParam;
}

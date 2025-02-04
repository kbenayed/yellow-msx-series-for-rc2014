#ifndef __APPMSX
#define __APPMSX

#include <stdlib.h>

#define NTMSXP_ADDR __at(0xF417)
#define JIFFY_ADDR  __at(0xFC9E)
#define NEWKEY_ADDR __at(0xFBE5)
#define PUTPNT_ADDR __at(0xF3F8)
#define GETPNT_ADDR __at(0xF3FA)
#define TXTNAM_ADDR __at(0xF3B3)
#define CSRY_ADDR   __at(0xF3DC)
#define CSRX_ADDR   __at(0xF3DD)
#define LINLEN_ADDR __at(0xF3B0)
#define CSRSW_ADDR  __at(0xFCA9)
#define LINL40_ADDR __at(0xF3AE)
#define LINL32_ADDR __at(0xF3AF)
#define RG8SAV_ADDR __at(0xFFE7)
#define LOWLIM_ADDR __at(0xFCA4)
#define WINWID_ADDR __at(0xFCA5)
#define KEYBUF_ADDR __at(0xFBF0)
#define MEMSIZ_ADDR __at(0xF672)
#define STKTOP_ADDR __at(0xF674)
#define BOTTOM_ADDR __at(0xFC48)
#define HIMEM_ADDR  __at(0xFC4A)
#define SCNCNT_ADDR __at(0xF3F6)
#define SCRMOD_ADDR __at(0xFCAF)

#define HOKVLD_ADDR __at(0xFB20)
#define EXTBIO_ADDR __at(0xFFCA)

#define RG0SAV_ADDR  __at(0xF3DF)
#define RG1SAV_ADDR  __at(0xF3E0)
#define RG2SAV_ADDR  __at(0xF3E1)
#define RG3SAV_ADDR  __at(0xF3E2)
#define RG4SAV_ADDR  __at(0xF3E3)
#define RG5SAV_ADDR  __at(0xF3E4)
#define RG6SAV_ADDR  __at(0xF3E5)
#define RG7SAV_ADDR  __at(0xF3E6)
#define RG8SAV_ADDR  __at(0xFFE7)
#define RG25SAV_ADDR __at(0xFFFA)

extern uint8_t HOKVLD_ADDR HOKVLD;
extern uint8_t EXTBIO_ADDR EXTBIO[5];

// F417: switch indicating if hooked up printer is an MSX printer or not
// values: 0: MSX-Printer, 1: no MSX-Printer
// if the printer is no MSX-Printer, non-ASCII (>=128) characters are replaced
// by spaces before sending them to the printer (ini: 0)
extern uint8_t NTMSXP_ADDR NTMSXP;

// FCA4-FCA5: parameter used at tap input, given a value during
// reading of a headerblock from tape
extern uint8_t LOWLIM_ADDR LOWLIM;
extern uint8_t WINWID_ADDR WINWID;

// FC9E-FC9F: software clock, updated at each VDP interrupt
extern uint16_t JIFFY_ADDR JIFFY;

// FBE5-FBEF: current state of the keyboard matrix
extern uint8_t NEWKEY_ADDR NEWKEY[10];

// F3F8-F3F9: first free space in the inputbuffer of the keyboard
// everytime a key is added to the inputbuffer, this address is incremented,
// when it equals to GETPNT, the buffer is full
// the buffer is located at KEYBUF
extern char *PUTPNT_ADDR PUTPNT;

// F3FA-F3FB: address in inputbuffer of first character that is not yet read
// everytime a key is read from the buffer it is incremented
// the buffer is located at KEYBUF
extern char *GETPNT_ADDR GETPNT;

// F3B3-F3B4: BASE(0): name table address for SCREEN 0 (ini:$0000)
// used to initialize NAMBAS when SCREEN 0 is activated
extern uint16_t TXTNAM_ADDR TXTNAM;

// F3DC: line where the cursor is located
// starts to count at 1 for the topmost line
extern uint8_t CSRY_ADDR CSRY;

// F3DD: column where the cursor is located
// starts to count at 1 for the leftmost column
extern uint8_t CSRX_ADDR CSRX;

// F3B0: # of actually used positions in the current screenmodus (ini:39)
extern uint8_t LINLEN_ADDR LINLEN;

// FCA9: show cursor; 0 = no, 1 = yes
// can be changed with escape sequences x5 and y5
extern uint8_t CSRSW_ADDR CSRSW;

// F3AE: # of positions on a line in SCREEN 0 (ini:39)
extern uint8_t LINL40_ADDR LINL40;

// F3AF: # of positions on a line in SCREEN 1 (ini:29)
extern uint8_t LINL32_ADDR LINL32;

// keyboard buffer; each char entered via the keyboard ends up here
extern char KEYBUF_ADDR KEYBUF[240];

// F672-F673: upper limit of memory area reserved for strings, contains the upper address
// that is allowed to be used
extern uint16_t MEMSIZ_ADDR MEMSIZ;

// F674-F675: top of stack; also first byte below string area
extern uint16_t STKTOP_ADDR STKTOP;

// FC48-FC49: lowest address of the RAM memory; initialized at startup
// and not changed normally
extern uint16_t BOTTOM_ADDR BOTTOM;

// FC4A-FC4B: highest address of the RAM memory that is not reserved by
// the OS; string area, filebuffers and stack are below this address
// initialized at startup and not changed normally
extern uint16_t HIMEM_ADDR HIMEM;

// F3F6: VDP-interupt counter that counts from 3 to 0, when it reaches zero, the
// keyboard matrix is scanned, and the counters is reset at 3
extern uint8_t SCNCNT_ADDR SCNCNT;

extern uint8_t SCRMOD_ADDR SCRMOD;

// F3DF-D3E6: storage for the last written value towards VDP registers 0 till 7
// this is needed because these registers are write only
extern uint8_t RG0SAV_ADDR RGS0TO7AV[8];
extern uint8_t RG0SAV_ADDR RG0SAV;
extern uint8_t RG1SAV_ADDR RG1SAV;
extern uint8_t RG2SAV_ADDR RG2SAV;
extern uint8_t RG3SAV_ADDR RG3SAV;
extern uint8_t RG4SAV_ADDR RG4SAV;
extern uint8_t RG5SAV_ADDR RG5SAV;
extern uint8_t RG6SAV_ADDR RG6SAV;
extern uint8_t RG7SAV_ADDR RG7SAV;

// FFE7-FFF6: storage of VDP 8-23
extern uint8_t RG8SAV_ADDR RG8SAV[23 - 8];

// FFFA-FFFC: storage of VDP 25-27
extern uint8_t RG25SAV_ADDR RG25SAV[27 - 25];

#define msxJiffy  JIFFY
#define msxNewKey NEWKEY
#define msxPutPtr PUTPNT
#define msxGetPtr GETPNT

#define VDP_FREQUENCY 50

// FFE7-FFF6: storage of VDP 8-23
extern uint8_t RG8SAV_ADDR RG8SAV[23 - 8];

#define GET_VDP_REGISTER(a) ((a >= 8 && a <= 23) ? RG8SAV[a] : 0)

#define GET_VDP_FREQUENCY() (GET_VDP_REGISTER(9) & 2 ? 60 : 50)

__sfr __at(0x98) VDP_VRAM;
__sfr __at(0x99) VDP_REG;
__sfr __at(0x9A) VDP_PALETTE;
__sfr __at(0x9B) VDP_REG_INDIRECT;

#endif

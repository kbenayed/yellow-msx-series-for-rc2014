#include <stdlib.h>
#include <stdbool.h>
#include "v9958.h"



#define DI __asm \
  DI \
  __endasm;

#define EI __asm \
  EI \
  __endasm;


void outPal(uint8_t b) __z88dk_fastcall {
  (void*)b;
  __asm
  LD  A, L
  OUT (0x9A), A
  __endasm;
}

void outRegIndByte(uint8_t b) __z88dk_fastcall {
  (void*)b;
  __asm
  LD  A, L
  OUT (0x9B), A
  __endasm;
}

void outRegIndInt(uint16_t b) __z88dk_fastcall {
  (void*)b;
  __asm
  LD  A, L
  OUT (0x9B), A
  LD  A, H
  OUT (0x9B), A
  __endasm;
}

uint8_t inDat() __naked __z88dk_fastcall {
  __asm
  IN A, (0x98)
  LD  L, A
  RET
  __endasm;
}

uint8_t readStatus(uint8_t r) __naked __z88dk_fastcall {
  writeRegister(15, r);
  __asm
	IN    A, (0x99)
  PUSH  AF
  __endasm;
  writeRegister(15, 0);
  __asm
  POP   AF
  LD    L, A
  RET
  __endasm;
}

void _writeRegister(uint16_t rd) __z88dk_fastcall {
  (void)rd;
  __asm
	LD	A, L
	OUT	(0x99), a

	LD	A, 128
  OR  H
	OUT	(0x99), A
  __endasm;
}

void setBaseRegisters(uint8_t* pReg) __z88dk_fastcall {
  DI

  for (uint8_t i = 0; i < REGISTER_COUNT; i++)
    writeRegister(i, *pReg++);

  EI
}

void setVideoSignal(uint8_t* pReg, uint8_t lines, uint8_t mode) {
  if (lines == 212)
    pReg[9] |= 0x80;

  if (mode == PAL)
    pReg[9] |= 0x02;
}

uint8_t mode6Reg[REGISTER_COUNT] = {
  0x0A,   // R0 - M5 = 1, M4 = 0, M3 = 1
  0x60,		// R1 - ENABLE SCREEN, ENABLE INTERRUPTS, M1 = 0, M2 = 0
  0x1F,		// R2 - PATTERN NAME TABLE := 0, A16 = 0
	0x00,		// R3 - NO COLOR TABLE
	0x00,		// R4 - N/A???
	0xF7,		// R5 - SPRITE ATTRIBUTE TABLE -> FA00
	0x1E,		// R6 - SPRITE PATTERN => F000
	0x00,		// R7 - a background colour?
	0x8A,   // R8 - COLOUR BUS INPUT, DRAM 64K, DISABLE SPRITE
	0x00,   // R9 - LN = 1(212 lines), S1, S0 = 0, IL = 0, EO = 0, NT = 1 (PAL), DC = 0
	0x00,   // R10 - color table - n/a
	0x01    // R11 - SPRITE ATTRIBUTE TABLE -> FA00
};

void setMode6(uint8_t lines, uint8_t mode) {
  setVideoSignal(mode6Reg, lines, mode);
  setBaseRegisters(mode6Reg);
}

uint8_t mode7Reg[REGISTER_COUNT] = {
  0x0E,   // R0 - M5 = 1, M4 = 1, M3 = 1
  0x60,		// R1 - ENABLE SCREEN, ENABLE INTERRUPTS, M1 = 0, M2 = 0
  0x1F,		// R2 - PATTERN NAME TABLE := 0, A16 = 0
	0x00,		// R3 - NO COLOR TABLE
	0x00,		// R4 - N/A???
	0xF7,		// R5 - SPRITE ATTRIBUTE TABLE -> FA00
	0x1E,		// R6 - SPRITE PATTERN => F000
	0x00,		// R7 - a background colour?
	0x8A,   // R8 - COLOUR BUS INPUT, DRAM 64K, DISABLE SPRITE
	0x00,   // R9 LN = 1(212 lines), S1, S0 = 0, IL = 0, EO = 0, NT = 1 (PAL), DC = 0
	0x00,   // R10 - color table - n/a
	0x01    // R11 - SPRITE ATTRIBUTE TABLE -> FA00
};

void setMode7(uint8_t lines, uint8_t mode) {
  setVideoSignal(mode7Reg, lines, mode);
  setBaseRegisters(mode7Reg);
}

RGB palette[16] = {
  {0, 0, 0},
  {1, 0, 0},
  {4, 0, 0},
  {4, 1, 1},
  {15, 0, 0},
  {0, 1, 0},
  {0, 4, 0},
  {1, 4, 1},
  {1, 8, 1},
  {0, 0, 1},
  {0, 0, 4},
  {1, 1, 4},
  {1, 1, 8},
  {10, 0, 10},
  {0, 15, 15},
  {15, 15, 15},
};
void setPalette() {
  DI
  writeRegister(16, 0);
  for(uint8_t c = 0; c < 16; c++) {
    outPal(palette[c].red * 16 + palette[c].blue);
    outPal(palette[c].green);
  }
  EI
}

void clearAllMemory() {
  DI
  writeRegister(14, 0);
  outCmd(0);
  outCmd(0x40);
  for(long i = 0; i < 0x10000; i++)
    outDat(0x00);
  for(long i = 0x10000; i < 0x20000; i++)
    outDat(0x00);
  EI
}


void clearScreenBank0(uint8_t color) __z88dk_fastcall {
  DI
  // // Clear bitmap data from 0x0000 to 0x3FFF

  writeRegister(17, 36);  // Set Indirect register Access
  outRegIndInt(0);      // DX
  outRegIndInt(0);      // DY
  outRegIndInt(512);    // NX
  outRegIndInt(212);    // NY
  outRegIndByte(color * 16 + color);  // COLOUR for both pixels (assuming G7 mode)
  outRegIndByte(0);     // Direction: VRAM, Right, Down
  outRegIndByte(CMD_VDP_TO_VRAM);
  EI

  waitForCommandCompletion();
}

void clearScreenBank1(uint8_t color) __z88dk_fastcall {
  DI
  // // Clear bitmap data from 0x0000 to 0x3FFF

  writeRegister(17, 36);  // Set Indirect register Access
  outRegIndInt(512);      // DX
  outRegIndInt(212);      // DY
  outRegIndInt(512);    // NX
  outRegIndInt(212);    // NY
  outRegIndByte(color * 16 + color);  // COLOUR for both pixels (assuming G7 mode)
  outRegIndByte(0x0);     // Direction: ExpVRAM, Right, Down
  outRegIndByte(CMD_VDP_TO_VRAM);
  EI

  waitForCommandCompletion();
}

static uint16_t t;
static uint16_t y;
static uint16_t x;
uint16_t _toX;
uint16_t _toY;

void _drawLine() {
  if (_fromY > _toY) {
    t = _fromY;
    _fromY = _toY;
    _toY = t;
  };
  if (_fromX > _toX) {
    t = _fromX;
    _fromX = _toX;
    _toX = t;
  };
  y = _toY - _fromY;
  x = _toX - _fromX;
  dir = (y > x);

  if (y > x) {
    longSide = y;
    shortSide = x;
  } else {
    longSide = x;
    shortSide = y;
  }

  commandDrawLine();
}

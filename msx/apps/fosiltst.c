
#include "fossil.h"
#include "xstdio.h"
#include <extbio.h>
#include <msxdos.h>
#include <stdio.h>

typedef struct {
  uint8_t *pHead;
  uint8_t *pTail;
  uint8_t  data[];
} rs232Buff;

uint8_t  __at(0xFB03) RS_TMP;
uint8_t  __at(0xFB1A) RS_ERRORS;
uint8_t  __at(0xFB17) RS_DATCNT;
uint8_t  __at(0xFB1C) RS_ESTBLS; // RTSON:		EQU	$		; Bit boolean. (RS-232C)
uint8_t  __at(0xFB1B) RS_FLAGS;  // RS-232C bit flags
uint8_t *__at(0xFB18) RS_BUFEND;

rs232Buff *__at(0xFB04) RS_FCB;

void extern debugBreak(void);
void extern enableVdpInterrupts(void);
void extern disableVdpInterrupts(void);

void main(void) {
  bool stat;

  xprintf("RS_TMP %02X\r\n", RS_TMP);

  printf("fossil_link should return false before install %d\r\n", fossil_link());

  void *p = extbio_fossil_install(FOSSIL_FOR_SIO2);

  printf("fossil_link should return true after %d\r\n", fossil_link());

  xprintf("Address %p\r\n", p);

  fossil_link();

  uint16_t version = fossil_get_version();

  xprintf("Version %04X\r\n", version);

  uint16_t b = fossil_set_baud(7 * 256 + 7); // 19200
  printf("Baud %04X\r\n", b);

  fossil_init();
  xprintf("RS_TMP %02X\r\n", RS_TMP);

  xprintf("BUF AT %p, head: %p, tail: %p\r\n", RS_FCB, RS_FCB->pHead, RS_FCB->pTail);
  fossil_rs_out('A');
  fossil_rs_out('T');
  fossil_rs_out('\r');
  fossil_rs_out('\n');

  stat = fossil_rs_in_stat();
  printf("sent AT.  Stat: %02X\r\n", stat);

  stat = fossil_rs_in_stat();

  while (stat) {
    uint16_t count = fossil_chars_in_buf();
    // printf(">> H: %p, T: %p, ST: %d\r\n", RS_FCB->pHead, RS_FCB->pTail, stat);
    printf("count: %d, ", count);
    char ch = fossil_rs_in();
    printf("%c\r\n", ch);
    // printf(">> H: %p, T: %p, ST: %d, ch: %c,\r\n", RS_FCB->pHead, RS_FCB->pTail, stat, ch);

    stat = fossil_rs_in_stat();
  }

exitApp:
  xprintf("RS_TMP %02X\r\n", RS_TMP);

  printf("RS_FLAGS: %02X\r\nClosing...\r\n", RS_FLAGS);
  fossil_deinit();
  printf("RS_FLAGS: %02X\r\nClosed\r\n", RS_FLAGS);
}

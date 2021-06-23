
RAMAD0	equ	0F341h	; Slot of the Main-Ram on page 0~3FFFh
EXTBIO	equ	0ffcah	; Call address to an extended Bios
CALSLT:      EQU    0001Ch
EXPTBL:      EQU    0FCC1h
RDSLT	EQU	0000CH

RS232_FN_COUNT:	EQU	13	; EXTENDED BIOS RS232 HAS 13 JUMP INSTRUCTIONS

	SECTION	CODE

;
; extern uint8_t extbio_get_dev(uint8_t* table) __z88dk_fastcall;
;
	PUBLIC	_extbio_get_dev
_extbio_get_dev:
	PUSH	IX
	CALL	GETSLT		; B = NUMBER THE SLOT OF THE TABLE
	LD	DE, 0		; BROAD-CAST, FUNCTION: 'GET DEVICE NUMBER'
	CALL	EXTBIO
	POP	IX
	RET

;
; extern void extbio_get_dev_info_table(uint8_t device_id, extbio_info* info_table);
;
	PUBLIC	_extbio_get_dev_info_table
_extbio_get_dev_info_table:
	PUSH	IX
	LD	IX, 0
	ADD	IX, SP

	CALL	GETSLT		; B = number the slot of the table

	LD	D, (IX+4) 	; DEVICE_ID
	LD	L, (IX+5)  	; INFO_TABLE
	LD	H, (IX+6)

	LD	E, 0		; FUNCTION 'GET INFO'
	CALL	EXTBIO

	POP	IX
	RET
;
; extern void* extbio_fossil_install()
;
	PUBLIC	_extbio_fossil_install
_extbio_fossil_install:
	PUSH	IX
	LD	D, 214		; RC2014 EXTENDED DRIVER
	LD	E, 1		; FUNCTION INSTALL
	CALL	EXTBIO
	POP	IX
	RET
;
; extern void rs232_link(extbio_info *p) __z88dk_fastcall;
;
	PUBLIC	_rs232_link
_rs232_link:
	LD	A, (HL)				; RETRIEVE SLOT ID
	ld	de, rs232_slot_init+1		; WRITE IT TO THE LINK FUNCTIONS
	ld	b,  RS232_FN_COUNT
loop1:
	ld	(de), a
	inc	de
	inc	de
	inc	de
	inc	de
	inc	de
	inc	de
	djnz	loop1

	INC	HL				; RETRIEVE THE JUMP TABLE ADDRESS
	LD	E, (HL)
	INC	HL
	LD	D, (HL)				; DE IS JUMP TABLE ADDR - FIRST 3 ARE IGNORED, FOLLOWED BY JUMPS
	INC	DE
	INC	DE
	INC	DE


	LD	HL, rs232_slot_init+2		; WRITE THE JUMP ADDRESSES
	LD	B, RS232_FN_COUNT
LOOP:
	ld	(hl), e				; WRITE JUMP TABLE REF TO LINK FUNCTION
	inc	hl
	ld	(hl), d
	inc	hl

	inc	hl
	inc	hl
	inc	hl
	inc	hl				; HL REFERENCES NEXT LOCAL LINK FUNCTION

	INC	DE
	INC	DE
	INC	DE				; DE NOW PTS TO NEXT JUMP INSTRUCTION

	DJNZ	LOOP

	RET
;
; extern void rs232_init(rs232_init_params*) __z88dk_fastcall;
;
	PUBLIC	_rs232_init
_rs232_init:
	CALL	GETSLT			; B = number the slot of the table
	JP	rs232_slot_init

; extern void rs232_open(uint8_t mode, uint8_t buffer_length, uint8_t* buffer);
	PUBLIC	_rs232_open
_rs232_open:
	ld b,b
	jr $+2
	PUSH	IX
	LD	IX, 0
	ADD	IX, SP

	LD	E, (IX+4)
	LD	C, (IX+5)
	LD	L, (IX+6)
	LD	H, (IX+7)
	CALL	rs232_slot_open

	POP	IX
	RET

	PUBLIC	_rs232_close
_rs232_close:
	JP	rs232_slot_close

;extern uint8_t rs232_sndchr(const char ch) __z88dk_fastcall;
	PUBLIC	_rs232_sndchr
_rs232_sndchr:
	ld b,b
	jr $+2
	LD	A, L
	CALL	rs232_slot_sndchr
	LD	L, 0
	RET	Z
	LD	L, 1
	RET

;
; extern uint16_t rs232_getchr();
;
	PUBLIC	_rs232_getchr
_rs232_getchr:
	CALL	rs232_slot_getchr
	LD	H, 0
	LD	L, A
	RET	Z
	LD	H, 1
	RET

;----------------------------------------------------------------
; ROUTINE GETSLT
; ENTRY: HL = ADDRESS IN RAM
; OUTPUT: B = SLOT NUMBER CORRESPONDING TO THE HL ADDRESS
; MODIFIES: A AND B

GETSLT:
	PUSH	HL
	LD	A,H
	RLA
	RLA
	RLA		; BIT 6-7 TO BIT 1-0
	AND	3	; RESET UNUSED BITS
	LD	C,A
	LD	B,0
	LD	HL,RAMAD0
	ADD	HL,BC
	LD	B,(HL)	; B = SLOT NUMBER OF MAIN RAM
	POP	HL
	RET

; extern uint8_t getSlotPage0(void* p) __z88dk_fastcall;
	PUBLIC	_getSlotPage0
_getSlotPage0:
	CALL	GETSLT
	LD	L, B
	LD	H, 0
	RET

rs232_slot_jumps:
rs232_slot_init:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_open:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_stat:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_getchr:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_sndchr:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_close:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_eof:
	RST	30H
	DB	0
	DW	0
	EI
	RET

;
; extern uint16_t rs232_loc();
;
	PUBLIC	_rs232_loc
_rs232_loc:
rs232_slot_loc:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_lof:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_backup:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_sndbrk:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_dtr:
	RST	30H
	DB	0
	DW	0
	EI
	RET

rs232_slot_setchn:
	RST	30H
	DB	0
	DW	0
	EI
	RET



; FOSSILE STUFF

; extern void fossil_link(void* jumpTable) __z88dk_fastcall
;
	PUBLIC	_fossil_link

_fossil_link:
	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(fossil_get_version_prt+1), de
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(fossil_init_ptr+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_deinit+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_setbaud+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_protocol+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_channel+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_rs_in+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(rs_out_ptr+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_rs_in_stat+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_rs_out_stat+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_dtr+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_rts+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_carrier+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_chars_in_buf+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_size_of_buf+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_flushbuf+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_fastint+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_hook38stat+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_chput_hook+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_keyb_hook+1), DE
	INC	HL

	INC	HL
	LD	E, (HL)
	INC	HL
	LD	D, (HL)
	LD	(_fossil_get_info+1), DE

	RET

	PUBLIC	_fossil_get_version
	PUBLIC	_fossil_init
	PUBLIC	_fossil_deinit
	PUBLIC	_fossil_setbaud
	PUBLIC	_fossil_channel
	PUBLIC	_fossil_rs_in
	PUBLIC	_fossil_rs_out
	PUBLIC	_fossil_rs_in_stat
	PUBLIC	_fossil_rs_out_stat
	PUBLIC	_fossil_dtr
	PUBLIC	_fossil_rts
	PUBLIC	_fossil_carrier
	PUBLIC	_fossil_chars_in_buf
	PUBLIC	_fossil_size_of_buf
	PUBLIC	_fossil_flushbuf
	PUBLIC	_fossil_fastint
	PUBLIC	_fossil_hook38stat
	PUBLIC	_fossil_chput_hook
	PUBLIC	_fossil_keyb_hook
	PUBLIC	_fossil_get_info

_fossil_get_version:
fossil_get_version_prt:
	JP	0

_fossil_init:
fossil_init_ptr:
	JP	0

_fossil_deinit:
	JP	0

_fossil_setbaud:
	JP	0

_fossil_protocol:
	JP	0

_fossil_channel:
	JP	0

_fossil_rs_in:
	CALL	0
	LD	L, A
	RET

_fossil_rs_out:
	LD	A, L
rs_out_ptr:
	JP	0

_fossil_rs_in_stat:
	JP	0

_fossil_rs_out_stat:
	JP	0

_fossil_dtr:
	JP	0

_fossil_rts:
	JP	0

_fossil_carrier:
	JP	0

_fossil_chars_in_buf:
	JP	0

_fossil_size_of_buf:
	JP	0

_fossil_flushbuf:
	JP	0

_fossil_fastint:
	JP	0

_fossil_hook38stat:
	JP	0

_fossil_chput_hook:
	JP	0

_fossil_keyb_hook:
	JP	0

_fossil_get_info:
	JP	0




RG1SAV:         equ     $F3E0
VDP_INTEN:     EQU     5
VDP_ADDR:       equ     $99             ; VDP address (write only)

       PUBLIC  _disableVdpInterrupts
_disableVdpInterrupts:
       DI
       LD      A, (RG1SAV)
       RES     VDP_INTEN, A            ; RESET INTERRUPT ENABLE BIT
       LD      (RG1SAV), A
       OUT     (VDP_ADDR), A
       NOP
       NOP
       LD      A, $81                  ; SELECT REGISTER 1
       OUT     (VDP_ADDR), A
       EI
       RET

       PUBLIC  _enableVdpInterrupts
_enableVdpInterrupts:
       DI
       LD      A, (RG1SAV)
       SET     VDP_INTEN, A            ; RESET INTERRUPT ENABLE BIT
       LD      (RG1SAV), A
       OUT     (VDP_ADDR), A
       NOP
       NOP
       LD      A, $81                  ; SELECT REGISTER 1
       OUT     (VDP_ADDR), A
       EI
       RET

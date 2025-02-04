
; ; TODO
; ; [ ] INIT FUNCTION SHOULD ATTEMPT TO SET STOP BITS/PARITY/ETC, SPEED
; ; [ ] OPEN - ERROR UNLESS RAW MODE, ERROR IF ALREADY OPENED, ENABLE RTS
; ; [ ] STAT - IMPLEMENT
; ; [ ] SNDCHR XON/XOFF FLOW CONTROL
; ; [x] CLOSE - DISABLE RTS
; ; [ ] EOF - ALWAYS FALSE
; ; [ ] LOF - IMPLEMENT
; ; [ ] SNDBRK - RESEARCH AND IMPLEMENT
; ; [ ] DTR - IMPLEMENT
; ; [ ] SETCHN - IMPLEMENT (SIO PORTS)

; ; INIT TABLE
; RSC_CHAR_LEN	EQU	0		; Character length '5'-'8'
; RSC_PARITY	EQU	1		; Parity 'E','O','I','N'
; RSC_STOP_BITS	EQU	2		; Stop bits '1','2','3'
; RSC_XON_XOFF	EQU	3		; XON/XOFF controll 'X','N'
; RSC_CTR_RTS	EQU	4		; CTR-RTS hand shake 'H','N'
; RSC_AUTO_RCV_LF	EQU	5		; Auto LF for receive 'A','N'
; RSC_AUTO_SND_LF	EQU	6		; Auto LF for send 'A','N'
; RSC_SI_SO_CTRL	EQU	7		; SI/SO control 'S','N'
; RSC_RCV_BAUD	EQU	8		; Receiver baud rate  50-19200
; RSC_SND_BAUD	EQU	10		; Transmitter baud rate 50-19200
; RSC_TIMEOUT_CNT	EQU	12		; Time out counter 0-255

; EXTBIO_RS2_JUMP_TABLE:
; 	DEFB	0		; MSX serial features (no TxReady INT, No Sync detect, No Timer INT, No CD, No RI)
; 	DEFB	1		; version number
; 	DEFB	0		; reserved for future expansion
; 	JP	RS_INIT		; initialize RS232C port
; 	JP	RS_OPEN		; open RS232C port
; 	JP	STAT		; ReaD STATus
; 	JP	GETCHR		; reveive data
; 	JP	RS_SNDCHR	; send data
; 	JP	CLOSE		; close RS232C port
; 	JP	EOF		; tell EOF code received
; 	JP	LOC		; reports number of characters in the receiver buffer
; 	JP	LOF		; reports number of free space left in the receiver buffer
; 	JP	BACKUP		; back up a character
; 	JP	SNDBRK		; send break character
; 	JP	DTR		; turn on/off DTR line
; 	JP	SETCHN		; set channel number


; ;------------------------------------
; 	; Entry:  [HL]= address of the parameter table
; 	;	 [B] = slot address of the parameter table
; 	; Return: carry flag is set if illegal parameters are contained
; 	; Modify: [AF]
; RS_INIT:				; initialize RS232C port
; 	EI

; 	PUSH	IX
; 	LD	IX, -13
; 	ADD	IX, SP
; 	LD	SP, IX
; 	PUSH	IX
; 	POP	DE

; 	; HL SOURCE OF INIT BUFFER
; 	; DE IS DEST ON STACK
; 	; B IS SLOT OF SOURCE INIT BUFFER

; 	LD	C, B
; 	LD	B, 13

; RS_INIT_CPY:
; 	PUSH	IX
; 	PUSH	DE
; 	PUSH	BC
; 	LD	A, C
; 	CALL	RDSLT
; 	EI
; 	POP	BC
; 	POP	DE
; 	POP	IX

; 	LD	(DE), A
; 	INC	DE
; 	INC	HL
; 	DJNZ	RS_INIT_CPY

; 	CALL	CFG_RS232_SETTINGS
; 	JR	NC, RS_INIT_CFG_OK
; 	LD	IX, 13
; 	ADD	IX, SP
; 	LD	SP, IX
; 	POP	IX

; 	JR	RET_WITH_C

; RS_INIT_CFG_OK:
; 	CALL	SIO_INIT

; 	LD	IX, 13
; 	ADD	IX, SP
; 	LD	SP, IX
; 	POP	IX

; RS_INIT_INSTALL:
; 	XOR	A
; 	LD	(RS_FLAGS), A

; 	; INSTALL INTERRUPT HOOK - IF NOT ALREADY DONE

; 	LD	DE, RS_OLDINT		; COPY HOOK FUNCTION FROM H_KEYI TO RS_OLDINT
; 	LD	A, (DE)
; 	OR	A
; 	JR	NZ, RS_INT_ALREADY_INSTALLED

; 	LD	HL, H_KEYI
; 	LD	BC, 5
; 	LDIR				; COPY THE OLD INT HOOK

; 	; INSTALL INTERRUPT HOOK TO SIO_INT
; 	LD	A, $C3                  ; JUMP
; 	LD	DE, (WORK)
; 	LD	HL, @SIO_INT             ; SET TO JUMP TO SIO_INIT IN PAGE 3 RAM
; 	ADD	HL, DE
; 	DI
; 	LD	(H_KEYI), A             ; SET JMP INSTRUCTION
; 	LD	(H_KEYI+1), HL          ; SET NEW INTERRUPT ENTRY POINT
; 	EI

; RS_INT_ALREADY_INSTALLED:
; 	XOR	A
; 	RET

; 	; IX => RS232 INIT SETTINGS
; CFG_RS232_SETTINGS:
; 	; CHECK IF BOTH TRANSMIT AND RECEIVE BAUD ARE THE SAME
; 	; REJECT IF NOT
; 	LD	A, (IX+RSC_RCV_BAUD)
; 	CP	(IX+RSC_SND_BAUD)
; 	JR	NZ, CFG_INVALID_BAUD
; 	LD	A, (IX+RSC_RCV_BAUD+1)
; 	CP	(IX+RSC_SND_BAUD+1)
; 	JR	NZ, CFG_INVALID_BAUD

; 	LD	L,  (IX+RSC_RCV_BAUD)
; 	LD	H,  (IX+RSC_RCV_BAUD+1)

; 	LD	A, 01000000B		; CLK DIV 16 FOR BAUD_HIGH (TYPICALLY 19200 BAUD)
; 	LD	(RS_SIO_CLK_DIV), A

; 	LD	DE, BAUD_HIGH
; 	OR	A
; 	SBC	HL, DE
; 	RET	Z

; 	LD	A, 10000000B		; CLK DIV 32 FOR BAUD_MID (TYPICALLY 9600 BAUD)
; 	LD	(RS_SIO_CLK_DIV), A

; 	ADD	HL, DE
; 	LD	DE, BAUD_MID
; 	OR	A
; 	SBC	HL, DE
; 	RET	Z

; 	LD	A, 11000000B		; CLK DIV 64 FOR BAUD_LOW (TYPICALLY 4800 BAUD)
; 	LD	(RS_SIO_CLK_DIV), A

; 	ADD	HL, DE
; 	LD	DE, BAUD_LOW
; 	OR	A
; 	SBC	HL, DE
; 	RET	Z

; CFG_INVALID_BAUD:
; RET_WITH_C:
; 	SCF
; 	RET

; SIO_INIT:
; 	DI
; 	SIO_CHIP_INIT	(RC_SIOA_CMD), SIO_RTSOFF
; 	SIO_CHIP_INIT	(RC_SIOB_CMD), SIO_RTSOFF
; 	EI
; 	RET

; ; ------------------------------------------------
; RS_OPEN:				; open RS232C port
; 	EI
; 	XOR	A
; 	LD	(RS_DATCNT), A
; 	LD	(RS_FLAGS), A

; 	LD	(RS_FCB), HL
; 	LD      A, C
; 	LD      (RS_IQLN),A

; 	LD	D, H		; FIRST 2 WORDS OF BUFFER AT THE HEAD AND TAIL PTRS
; 	LD	E, L		; THEY NEED TO BE INITIALISED TO START OF ACTUAL DATA BUFFER
; 	EX	DE, HL		; WHICH IS JUST AFTER THESE 4 BYTES
; 	INC	DE
; 	INC	DE
; 	INC	DE
; 	INC	DE
; 	LD	(HL), E		; LOAD FIRST 2 WORDS IN BUFFER TO POINT TO ADDRESS
; 	INC	HL		; AFTER FIRST 2 WORDS
; 	LD	(HL), D
; 	INC	HL
; 	LD	(HL), E
; 	INC	HL
; 	LD	(HL), D
; 	INC	HL

; 	EX	DE, HL
; 	LD	B, 0
; 	ADD	HL, BC
; 	LD	(RS_BUFEND), HL

; 	LD      HL, RS_FLAGS
; 	SET     3, (HL)			; SET RS232 OPEN FLAG
; 	SET	1, (HL)			; SET RTS ON FLAG
; 	SIO_CHIP_RTS	(RC_SIOB_CMD), SIO_RTSON
; 	RET

; STAT:				; Read Status
; 	RET

; GETCHR:				; reveive data
; 	EI
; 	JP	@SIO_RCBBYT

; RS_TRANSMIT_PENDING_MASK	EQU	$04	; BIT 2 OF SIO REGISTER 0
; RS_SNDCHR:					; SEND CHARACTER OUT
; 	EI
; 	LD	B, A				; SAVE CHAR TO BE TRANSMITTED
; RS_SNDCHR_WAIT:
; 	XOR	A				; SELECT READ REGISTER 0
; 	DI
; 	OUT	(RC_SIOB_CMD), A
; 	IN	A, (RC_SIOB_CMD)			; GET REGISTER 0 VALUE
; 	EI
; 	AND	RS_TRANSMIT_PENDING_MASK	; IS TRANSMIT PENDING?
; 	JR	Z, RS_SNDCHR_WAIT		; YES, THEN WAIT UNTIL TRANSMIT COMPLETED
; 	LD	A, B
; 	OUT	(RC_SIOB_CMD), A			; TRANSMIT BYTE
; 	OR	$FF				; RETURN NZ TO INDICATE NO TIMEOUT
; 	RET

; CLOSE:		 		; close RS232C port
; 	XOR	A		; MARK AS CLOSED AND RTS OFF
; 	LD	(RS_FLAGS), A
; 	SIO_CHIP_RTS	(RC_SIOB_CMD), SIO_RTSOFF
; 	RET


; EOF:			 	; tell EOF code received
; 	RET

; LOC:
; 	LD	A, (RS_DATCNT)	; BUFFER UTILIZATION COUNT
; 	ld	L, A
; 	ld	H, 0
; 	RET			; receiver buffer

; LOF:			 	; reports number of free space left in the
; 	RET			; receiver buffer

; BACKUP:				; back up a character
; 	RET

; SNDBRK:				; send break character
; 	RET

; DTR:				; turn on/off DTR line
; 	RET

; SETCHN:				; set channel number
; 	RET


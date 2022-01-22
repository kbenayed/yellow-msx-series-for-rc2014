
; SIO CHIP PROBE
; CHECK FOR PRESENCE OF SIO CHIPS AND POPULATE THE
; SIO_MAP BITMAP (ONE BIT PER CHIP).  THIS DETECTS
; CHIPS, NOT CHANNELS.  EACH CHIP HAS 2 CHANNELS.
; MAX OF TWO CHIPS CURRENTLY.  INT VEC VALUE IS TRASHED!
;
	MODULE	SIO
@SIO_PROBE:
	XOR	A
	LD	B, 2			; WR2 REGISTER (INT VEC)
	LD	C, RC_SIOB_CMD		; FIRST CHIP
	CALL	SIO_WR			; WRITE ZERO TO CHIP REG

	; CHECK FOR STD RC2014 PORT MAPPINGS
	LD	C, RC_SIOB_CMD		; FIRST CHIP CMD/STAT PORT
	CALL	SIO_PROBECHIP		; PROBE IT
	JR	NZ, TRY_NEXT_MAPPING	; NOT FOUND, TRY OTHER MAPPING

	LD	HL, RS_SIO_A_CMD	; STORE THE DISCOVERED PORT NUMBERS
	LD	(HL), RC_SIOA_CMD
	INC	HL			; RS_SIO_A_DAT
	LD	(HL), RC_SIOA_DAT
	INC	HL			; RS_SIO_B_CMD
	LD	(HL), RC_SIOB_CMD
	INC	HL			; RS_SIO_B_DAT
	LD	(HL), RC_SIOB_DAT

	LD	A, SIO_CLK_DIV_16	; DEFAULT TO DIV 16
	LD	(RS_SIO_CLK_DIV), A

	LD	A, 1			; RETURN PORT SET 1
	RET

TRY_NEXT_MAPPING:
	XOR	A
	LD	B, 2			; WR2 REGISTER (INT VEC)
	LD	C, YL_SIOB_CMD		; FIRST CHIP
	CALL	SIO_WR			; WRITE ZERO TO CHIP REG

	; CHECK FOR STD RC2014 PORT MAPPINGS
	LD	C, YL_SIOB_CMD		; FIRST CHIP CMD/STAT PORT
	CALL	SIO_PROBECHIP		; PROBE IT
	JR	NZ, SIO_PROBE_NOT_FOUND

	LD	HL, RS_SIO_A_CMD	; STORE THE DISCOVERED PORT NUMBERS
	LD	(HL), YL_SIOA_CMD
	INC	HL			; RS_SIO_A_DAT
	LD	(HL), YL_SIOA_DAT
	INC	HL			; RS_SIO_B_CMD
	LD	(HL), YL_SIOB_CMD
	INC	HL			; RS_SIO_B_DAT
	LD	(HL), YL_SIOB_DAT

	LD	A, SIO_CLK_DIV_16	; DEFAULT TO DIV 16
	LD	(RS_SIO_CLK_DIV), A

	LD	A, 2			; RETURN PORT SET 2
	RET

SIO_PROBE_NOT_FOUND:
	XOR	A
	RET
;
SIO_PROBECHIP:
	; READ WR2 TO ENSURE IT IS ZERO (AVOID PHANTOM PORTS)
	CALL	SIO_RD			; GET VALUE
	AND	$F0			; ONLY TOP NIBBLE
	RET	NZ			; ABORT IF NOT ZERO
	; WRITE INT VEC VALUE TO WR2
	LD	A,$FF			; TEST VALUE
	CALL	SIO_WR			; WRITE IT
	; READ WR2 TO CONFIRM VALUE WRITTEN
	CALL	SIO_RD			; REREAD VALUE
	AND	$F0			; ONLY TOP NIBBLE
	CP	$F0			; COMPARE
	RET

SIO_WR:
	OUT	(C),B			; SELECT CHIP REGISTER
	OUT	(C),A			; WRITE VALUE
	RET
;
SIO_RD:
	OUT	(C),B			; SELECT CHIP REGISTER
	IN	A,(C)			; GET VALUE
	RET

@SIO_RCBBYT:
	LD	A, (RS_IQLN)
	SRL	A
	SRL	A
	LD	D, A			; D IS QRT MARK OF BUFFER SIZE

	LD	HL, (RS_FCB)
	DI				; AVOID COLLISION WITH INT HANDLER
	LD	A, (RS_DATCNT)		; GET COUNT
	DEC	A			; DECREMENT COUNT
	LD	(RS_DATCNT), A		; SAVE UPDATED COUNT
	CP	D			; BUFFER LOW THRESHOLD
	JR	NZ, .SIO_IN1		; IF NOT, BYPASS SETTING RTS

	LD	A, (RS_SIO_B_CMD)
	LD	C, A
	SIO_CHIP_RTS	(C), SIO_RTSON
	LD	A, (RS_FLAGS)
	SET	1, A
	LD	(RS_FLAGS), A

.SIO_IN1:
	INC	HL
	INC	HL			; HL NOW HAS ADR OF TAIL PTR
	PUSH	HL			; SAVE ADR OF TAIL PTR
	LD	A, (HL)			; DEREFERENCE HL
	INC	HL
	LD	H, (HL)
	LD	L, A			; HL IS NOW ACTUAL TAIL PTR
	LD	C, (HL)			; C := CHAR TO BE RETURNED
	INC	HL			; BUMP TAIL PTR
	POP	DE			; RECOVER ADR OF TAIL PTR
	LD	A, (RS_BUFEND)		; GET BUFEND PTR LOW BYTE
	CP	L			; ARE WE AT BUFF END?
	JR	NZ, .SIO_IN2		; IF NOT, BYPASS
	LD	H, D			; SET HL TO
	LD	L, E			; ... TAIL PTR ADR
	INC	HL			; BUMP PAST TAIL PTR
	INC	HL			; ... SO HL NOW HAS ADR OF ACTUAL BUFFER START
.SIO_IN2:
	EX	DE, HL			; DE := TAIL PTR VAL, HL := ADR OF TAIL PTR
	LD	(HL), E			; SAVE UPDATED TAIL PTR
	INC	HL
	LD	(HL), D
	EI				; INTERRUPTS OK AGAIN
	LD	A, C			; MOVE CHAR TO RETURN TO A
	OR	A
	RET

	ENDMODULE

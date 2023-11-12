


EXTBIO_RS232_ID			EQU	8
EXTBIO_RS2_GET_INFO_TABLE_FN	EQU	0
EXTBIO_RC2014_ID		EQU	214

EXTBIO:
	PUSH	AF
	LD	A, D
	OR	E
	JR	Z, EXTBIO_GET_DEVICE_ID

	LD	A, D
	CP	EXTBIO_RS232_ID
	JR	Z, EXTBIO_RS232

	CP	EXTBIO_RC2014_ID
	JR	Z, EXTBIO_RC2014

	JR	EXBIO_EXIT		; NOT US

EXTBIO_RS232:
	LD	A, E
	CP	EXTBIO_RS2_GET_INFO_TABLE_FN
	JR	Z, EXTBIO_RS2_GET_INFO_TABLE

	JR	EXBIO_EXIT

EXTBIO_RC2014_GET_VERSION_FN			EQU	0
EXTBIO_RC2014_INSTALL_FOSSIL_INCORRECT_FN	EQU	1
EXTBIO_RC2014_SIO_GET_CLOCK_FN			EQU	2
EXTBIO_RC2014_SIO_SET_CLOCK_FN			EQU	3
EXTBIO_RC2014_SIO_GET_PRESENT_FN		EQU	4
EXTBIO_RC2014_INSTALL_FOSSIL_FN			EQU	5


EXTBIO_RC2014:
	LD	A, E
	CP	EXTBIO_RC2014_GET_VERSION_FN
	JR	Z, EXTBIO_RC_GET_VERSION

	CP	EXTBIO_RC2014_INSTALL_FOSSIL_INCORRECT_FN
	JR	Z, EXTBIO_RC_INSTALL_FOSSIL_INCORRECT

	CP	EXTBIO_RC2014_INSTALL_FOSSIL_FN
	JR	Z, EXTBIO_RC_INSTALL_FOSSIL

	CP	EXTBIO_RC2014_SIO_GET_CLOCK_FN
	JP	Z, EXTBIO_RC_SIO_GET_CLOCK

	CP	EXTBIO_RC2014_SIO_SET_CLOCK_FN
	JP	Z, EXTBIO_RC_SIO_SET_CLOCK

	CP	EXTBIO_RC2014_SIO_GET_PRESENT_FN
	JP	Z, EXTBIO_RC_SIO_GET_PRESENT

	JR	EXBIO_EXIT

EXTBIO_GET_DEVICE_ID:
	PUSH	DE
	PUSH	BC
	LD	E, EXTBIO_RS232_ID
	LD	A, B
	PUSH	AF
	CALL	WRSLT
	POP	AF
	PUSH	AF
	INC	HL
	LD	E, 00		; reserved byte
	CALL	WRSLT
	POP	AF
	PUSH	AF
	INC	HL

	LD	E, EXTBIO_RC2014_ID
	CALL	WRSLT
	POP	AF
	PUSH	AF
	INC	HL
	LD	E, 0		; reserved byte
	CALL	WRSLT
	POP	AF
	INC	HL
	POP	BC
	POP	DE

EXBIO_EXIT:
	POP	AF
	JP	RS_MEXBIH


EXTBIO_RS2_GET_INFO_TABLE:
	PUSH	DE
	PUSH	BC
	CALL	GETSL10

	LD	E, A
	LD	A, B
	PUSH	AF
	CALL	WRSLT
	POP	BC
	PUSH	BC
	INC	HL

	LD	E, EXTBIO_RS2_JUMP_TABLE & 255
	POP	AF
	PUSH	AF
	CALL	WRSLT
	POP	BC
	PUSH	BC
	INC	HL

	LD	E, EXTBIO_RS2_JUMP_TABLE / 256
	POP	AF
	CALL	WRSLT
	POP	BC
	INC	HL

	POP	DE
	POP	AF
	JP	RS_MEXBIH

EXTBIO_RC_GET_VERSION:
	POP	AF
	LD	HL, 1
	RET

; THIS API HAS BEEN DEPRECATED AT IT INSTALLED THE
; FOSSIL MARKERS IN THE INCORRECT ADDRESS
; ITS KEPT FOR EXISTING OLD APPS THAT USE IT
EXTBIO_RC_INSTALL_FOSSIL_INCORRECT:
	; INJECT FOSSIL MARKER
	LD	HL, 'R' * 256 + 'S'
	LD	(FSMARK_INCORRECT), HL

	; SET FOSSIL JUMP TABLE ADDRESS
	LD	HL, (WORK)
	LD	(FSTABL_INCORRECT), HL

	LD	HL, (WORK)
	POP	AF
	RET

EXTBIO_RC_INSTALL_FOSSIL:
	CALL	IS_FOSSIL_INSTALLED
	RET	Z

	; INJECT FOSSIL MARKER
	LD	HL, 'R' * 256 + 'S'
	LD	(FSMARK), HL

	; SET FOSSIL JUMP TABLE ADDRESS
	LD	HL, (WORK)
	LD	(FSTABL), HL

	LD	HL, (WORK)
	POP	AF
	RET

IS_FOSSIL_INSTALLED:
	LD	A, (FSMARK)
	CP	'R'
	RET	NZ
	LD	A, (FSMARK + 1)
	CP	'S'
	RET

EXTBIO_RC_SIO_GET_CLOCK:
	LD	A, (RS_SIO_CLK)
	LD	L, A
	POP	AF
	RET


EXTBIO_RC_SIO_SET_CLOCK:
	LD	A, (RS_SIO_CLK)
	LD	H, A

	LD	A, L
	LD	(RS_SIO_CLK), A
	LD	L, H
	LD	H, 0

	POP	AF
	RET

EXTBIO_RC_SIO_GET_PRESENT:
	LD	A, (RS_ESTBLS)
	AND	$80
	LD	L, 0
	JR	Z, EXTBIO_RC_SIO_GET_NOT_PRESENT
	LD	L, 1
EXTBIO_RC_SIO_GET_NOT_PRESENT:
	POP	AF
	RET

; MSX2ANSI ANSI V9938 Library v_1_7
;
; Original Code by Tobias Keizer (ANSI-DRV_BIN)
; Tobias has made this great piece of code and most of what is in it has been
; coded by him
;
; This version of code and conversion into SDCC library by Oduvaldo Pavan Junior
; ducasp@gmail.com
;
; Thanks to Piter Punk for his contribution on making this library also a great
; library to use for a remote terminal, he has fixed a few already implemented
; escape code behavior as well as adding several escape codes that are important
; for nCurses applications
;
; Comercial usage of this code or derivative works of this code are
; allowed ONLY upon agreement with the author.
; Non-comercial usage is free as long as you publish your code changes and give
; credits to the original authors
;
; Changelog:
;
; v1_7:
; OPJ - Minor improvments on unnecessary returns and unnecessary loading of
; parameters that do not change at all
; OPJ - Fix on LineFeed, the previous version would always return cursor column
; to 0 on LF which was not correct
; PK - Fix on Backspace behavior, when called as sub on the first column it was
; not behaving properly, causing the code to wander a print garbage
; PK - Fix on ErDis1, wrong opcodes used and it was not multiplying A contents
; PK - Fix on DO_HMMV, when doing a second pass, the second run would add the
; line offset again in DYL, being that the value was already adjusted
; OPJ - Ugly hack to fix Insert and Delete lines, work for now, beautyful code
; might come in another release :)
; OPJ - Synchronet started to send non ANSI escape sequences all over the place
; and as result, those codes are showing (as they should). I've disabled the
; output of unknown CSI sequences
;
; v1_6:
; OPJ - Changed the way HMMC is handled in the code, this resulted in 7% faster
; rendering of HISPAMSX MSX boot logo Ansi Art on a z80 at regular speeds_
; OPJ - Changed the way HMMM is handled in the code, it should be faster but it
; is difficult to determine the performance increase, anyway, code is cleaner
; and easier to understand as well
; OPJ - Changed how AnsiPrint and AnsiPutChar work, which results in 8% faster
; rendering of HISPAMSXMSX boot logo Ansi Art on a z80 at regular speeds. Total
; is a 15% speed improvment!
; Piter Punk - Made a draft of Ansi Delete Lines and YMMM function, not working
; on some scroll situations
; OPJ - Reworked YMMM function to start faster not having to calculate on the
; fly, doing all calculations before sending can save some time if VDP still is
; processing a command
; OPJ - Reworked CopyBlock as CopyBlockDown and made it work calculating before
; calling YMMM
; OPJ - Reworked Delete Lines, it was not taking into consideration when you
; are at the last line or if deleted lines exceed line capability
; OPJ - Created Insert Lines and CopyBlockUp
;
;
; v1_5:
; Piter Punk - Added scrolling support (ESC[S and ESC[T)
; Piter Punk - Added Support to ESC[X (ANSI ECH) and SGR 8 (Concealed),
; SGR 39 (Default Foreground Color), SGR 49 (Default Background Color)
; Piter Punk - Added Support to ESC[d (ANSI VPA),  ESC[e (ANSI VPR), ESC[G
; (ANSI CHA), ESC[I (ANSI CHT) and ESC[Z (ANSI CBT)
; Piter Punk - Added Support to ESC[nb, ANSI REP, which repeats the last char
; Piter Punk - Rewrite HorizontalTab routine to move cursor to a tabstop
; Piter Punk - Added back HorizontalTab (0x09) handling
; Piter Punk - Added save and restore cursor VT100 control codes
; OPJ - Fixed the issue with ESC[J, DO_HMMV was clearing memory that was not
; from its video page depending on the current line offset
; OPJ - Added the possibility of disabling cursor while putting text with
; AnsiPutChar through AnsiStartBuffer and AnsiEndBuffer, this might generate
; a more pleasant screen rendering without the cursor moving and also speed up
; certain operations like screen clearing and line deletions
; OPJ - Improved ESC[X to use VDP HMMV to delete as it is faster
; OPJ - Fixed Scroll Down, it was pushing the last line down and still visible
; OPJ - Fixed Scroll Up and Down and LineFeed, the line being excluded might be
; pushed into visible are, better have it in the border color than background
; color, as border color only changes when screen is cleared, using the
; same color as the background
; OPJ - Fixed quite a few characters below 0x20, those should be as faithful as
; 6x8 and my bad pixel art talent allows :D
; OPJ - Form Feed (12 or 0x0C) should clear screen and go to home, fixed that
; OPJ - Not all DO_HMMV commands were setting the desired color, causing that
; sometimes the color would be wrong after ANSI delete Commands
; OPJ - Added ESC[@ (Insert Chars)
;
; v1_4:
; OPJ - Control code BELL (7) now beeps
;
; v1_3:
; OPJ - Character code 16 was in code 18, fixed that
; Piter Punk - Fixed bad behavior of CSIm (no parameters) as well as a crash
; Piter Punk - Add support for reverse video mode
;
; v1_2:
; Added ESCx5 (turn off cursor) support
; Added ESCy5 (turn on cursor) support
; If a character is below 0x20 and not a screen control code, print it
; Fix characters code 16, 17, 24, 25, 26, 27, 30 and 31
; Probably not all characters below 0x20 (32) are correct...
;
; v1_1:
; Added ESC[J behavior when no parameter / 0 was choosen (delete from cursor on)
; Added ESC[1J (delete from cursor up to top of screen) and fixed ESC[2J support
; Fixed behavior when no parameters were given (it was not always correct)
; Added ESC[nP support for Linux telnet daemons

	SECTION CODE


;
; C Functions area
;
; In this section, we handle the calls from C code
;


; AnsiInit needs no parameters
;
; Will set the proper screen mode, clear screen, set cursor stuff
;
; You MUST call it, otherwise results might be unpredictable and crash
;
; void AnsiInit()
	PUBLIC	_AnsiInit
_AnsiInit:
	PUSH	IX					; Interslot call might mess with IX, IY and C expect it to be intact
	PUSH	IY
	CALL	V9938_Init			; Initialize screen mode, etc
	CALL	V9938_InitCursor	; Initialize cursor and return
	CALL	V9938_ClearScreen	; Clear screen
	POP	IY
	POP	IX						; Restore IX, IY so C won't have issues
	RET


; AnsiFinish needs no parameters
;
; Will restore MSX to Screen 0 and restore original palette
;
; You MUST call it before returning to MSX-DOS, otherwise user will face a
; static screen and think it has crashed (you can type MODE 80 and restore it
; manually). So MAKE SURE to handle CTRL+BREAK, CTRL+C, etc and call this function
; before returning_
;
; void AnsiFinish()
	PUBLIC	_AnsiFinish
_AnsiFinish:
	PUSH	IX					; Interslot call might mess with IX, IY and C expect it to be intact
	PUSH	IY
	CALL	V9938_Finish		; Restore
	POP	IY
	POP	IX						; Restore IX, IY so C won't have issues
	RET


; AnsiStartBuffer needs no parameters
;
; Will turn off sprite cursor if it is on, idea is to make rendering faster and
; there is no need to have the cursor enabled while rendering a live buffer. For
; some applications it is faster to use putchar than print, thus the need to indicate
; start and end of buffer printing
;
; void AnsiStartBuffer()
	PUBLIC	_AnsiStartBuffer
_AnsiStartBuffer:
StartBuffer:
	LD	A,(CursorOn)
	OR	A
	RET	Z
	CALL	DisCursorSub
	XOR	A
	LD	(CursorUpdt),A
	RET


; AnsiEndBuffer needs no parameters
;
; Will turn sprite cursor back on if it was on, idea is to make rendering faster and
; there is no need to have the cursor enabled while rendering a live buffer. For
; some applications it is faster to use putchar than print, thus the need to indicate
; start and end of buffer printing
;
; void AnsiEndBuffer()
	PUBLIC	_AnsiEndBuffer
_AnsiEndBuffer:
EndBuffer:
	LD	A,1
	LD	(CursorUpdt),A
	CALL	V9938_SetCursorX
	CALL	V9938_SetCursorY	; Set cursor position
	LD	A,(CursorOn)
	OR	A
	RET	Z
	CALL	EnCursorSub
	RET


; AnsiCallBack - Will call a __z88dk_fastcall function with Column/Line as a parameter
;
; This is useful to handle quickly ESC[6n cursor position requests, as it is up to
; the user program to determine how to send that information_
;
; void AnsiCallBack(unsigned int uiCallBackAddress) __z88dk_fastcall
	PUBLIC	_AnsiCallBack
_AnsiCallBack:
	LD	(ANSI_CGP_CALL_VEC + 1),HL	; Load the callback function address
	LD	A,0x01
	LD	(ANSI_CB),A			; Flag that have a callback function
	RET


; AnsiGetCursorPosition - Add possibility to get current cursor position
; unsigned int AnsiGetCursorPosition( )
; LSB will be current Column
; MSB will be current Row
_AnsiGetCursorPosition:
	LD	A,(CursorCol)			; Get Current Cursor Column Position
	INC	A						; Increment it (internally it is 0-79)
	LD	L,A						; Place column in L
	LD	A,(CursorRow)			; Get Current Cursor Row (line) Position
	INC	A						; Increment it (internally it is 0-24)
	LD	H,A						; Place row in H
	RET


; AnsiPutChar - will put the char in register L on screen or buffer if part of
; ANSI / VT sequence
;
; void AnsiPutChar(unsigned char ucChar) __z88dk_fastcall
	PUBLIC	_AnsiPutChar
_AnsiPutChar:
	LD	A,L						; Parameter is in L
BufferChar:
	OR	A
	RET	Z						; If 0, no need to print nor ANSI parameter
	LD	C,A						; Save char in C
	LD	A,(ANSI_M)
	OR	A
	JR	NZ,BufferChar_CNT		; Esc processing going on
	LD	A,C
	CP	27						; Is character ESC?
	JR	Z,BufferChar_ESC		; Yes, so treat ESC buffer
	; It is a printable character or control code, deal with it directly here
	CP	0x20
	JR	C,BufferChar_CCode		; If less than 0x20 (space), a control character
BufferChar_NotCCode:
	LD	(LastChar),A
	CALL	V9938_PrintChar		; Call the print routine for our chip
	LD	A,(CursorCol)			; Get Current Cursor Position
	INC	A						; Increment it
	LD	(CursorCol),A			; Save
	CP	80						; Time to line feed?
	JR	NC,BufferChar_LF		; If 80 or greater feed the line, and line feed will return to printtext loop
	; Otherwise
	JP	V9938_SetCursorX		; Set cursor on screen, it will return from there as it is done after this
BufferChar_LF:
	XOR	A
	LD	(CursorCol),A			; Save new cursor position
	JP	LFeedSub				; Feed the line and return from there
BufferChar_CCode:
	; Check if it is a control character and do the action, otherwise print it
	CP	13
	JP	Z,CarriageReturnSub
	CP	10
	JP	Z,LFeedSub
	CP	8
	JP	Z,BackSpaceSub
	CP	12						; FF, clear screen and home
	JP	Z,ANSI_ED_ED2Sub
	CP	9
	JP	Z,HTabSub
	CP	7
	JP	Z,BellSub
	JP	BufferChar_NotCCode
	; It is ESC
BufferChar_ESC:
	LD	(ANSI_M),A				; Indicate ESC is in progress
	LD	HL,ANSI_S
	LD	(HL),A					; Save in first buffer position
	INC	HL						; Next buffer position
	LD	(ANSI_P),HL			; Save in the pointer
	RET							; Done for now
BufferChar_CNT:
	LD	HL,(ANSI_P)			; Current buffer free position
	CP	27						; was ESC last byte?
	JR	Z,BufferChar_CH2		; Yes, check position 2
	; No
	CP	'x'					; ESC x?
	JR	Z,BufferChar_X			; Let's check if it is a parameter we know what to do
	CP	'y'					; ESC y?
	JR	Z,BufferChar_Y			; Let's check if it is a parameter we know what to do
	LD	A,C						; Restore character
	LD	(HL),A					; Store in buffer
	INC	HL
	LD	(ANSI_P),HL			; new buffer position
	CP	48
	JR	C,BufferChar_END		; Character is less than '0', not a parameter I understand, so finished buffering code
	; No, '0' or greater
	CP	'@'
	JR	NC,BufferChar_END		; If A > '@' not a parameter I understand, so finished buffering code
	;Otherwise it is between 0 and ; so ESC command has not finished yet
	RET
BufferChar_END:
	XOR	A
	LD	(HL),A
	LD	(ANSI_M),A				; No longer processing
BufferChar_RET:
	LD	HL,ANSI_S
	JP	PrintText_RLP			; Ok, print the buffer we did not process
BufferChar_CH2:
	LD	A,C						; Restore char
	LD	(HL),A					; Store it
	INC	HL						; Increment pointer
	CP	'['					; Just deal with ESC[ commands, other commands not supported at this moment
	JR	NZ,BufferChar_XorY		; So if the second character is not [, check if it is x or y
BufferChar_CH2a:
	LD	(ANSI_M),A				; Ok, now we are gathering parameters for the command
	LD	(ANSI_P),HL			; Save pointer
	RET							; Done

BufferChar_XorY:
	CP	'x'					; modify cursor behavior / disable?
	JR	Z,BufferChar_CH2a		; So if the second character is x, let's move on
	CP	'y'					; modify cursor behavior / enable?
	JR	Z,BufferChar_CH2a		; So if the second character is not y won't jump
	; print the ESC sequence and life goes on
	JR	NZ,BufferChar_END		; So if the second character is not [, print the ESC sequence and life goes on
BufferChar_X:
	LD	A,C						; Restore character
	CP	'5'					; ESC x5?
	LD	A,0					; Do not want to clear flag
	LD	(ANSI_M),A				; No longer processing
	JP	Z,VT52_DISCURSOR		; yes, disable cursor
	JR BufferChar_Y_END			; no, print the contents and end processing
BufferChar_Y:
	LD	A,C						; Restore character
	CP	'5'					; ESC x5?
	LD	A,0					; Do not want to clear flag
	LD	(ANSI_M),A				; No longer processing
	JP	Z,VT52_ENCURSOR			; yes, enaable cursor
BufferChar_Y_END:
	LD	(HL),A					; Store in buffer
	INC	HL
	LD	(ANSI_P),HL			; new buffer position
	JR	BufferChar_END			; not a parameter I understand, so print on the screen


; AnsiPrint - will proccess and print the string whose address is in HL (zero terminated)
; void __z88dk_fastcall AnsiPrint(unsigned char * ucString)
	PUBLIC	_AnsiPrint
_AnsiPrint:
	CALL	StartBuffer			; Disable sprite to render faster, if needed
BufferText:
	LD	A,(HL)					; Load the character
	INC	HL						; Increment pointer
	OR 	A						; 0?
	JP	Z,EndBuffer				; Yes, end of string, endbuffer will return for us
	PUSH	HL					; Save pointer
	CALL	BufferChar			; Process or print it
	POP	HL						; Restore pointer
	JP	BufferText				; Continue


; PrintText - Will handle text in address pointed by HL, zero terminated
PrintText:
PrintText_RLP:
	LD	A,(HL)					; Load the character
	INC	HL						; Increment the pointer
	CP	0x20
	JR	C,PrintText_RLP_CC		; If less than 0x20 (space), a control character
PrintText_RLP_NOCC:
	LD	(LastChar),A
	PUSH	HL					; Save Pointer
	CALL	V9938_PrintChar		; Call the print routine for our chip
	POP	HL						; Restore Pointer
	LD	A,(CursorCol)			; Get Current Cursor Position
	INC	A						; Increment it
	LD	(CursorCol),A			; Save
	CP	80						; Time to line feed?
	JR	NC,PrintText_RLP_LFeed	; If 80 or greater feed the line, and line feed will return to printtext loop
	; Otherwise
	CALL	V9938_SetCursorX	; Set cursor on screen
	JP	PrintText_RLP			; If up to position 80, done
PrintText_RLP_LFeed:
	XOR	A
	LD	(CursorCol),A
	JP	LineFeed
PrintText_RLP_CC:
	; Check if it is a control character and do the action, otherwise print it
	OR	A
	RET	Z						; If 0, done
	CP	13
	JP	Z,CarriageReturn
	CP	10
	JP	Z,LineFeed
	CP	8
	JP	Z,BackSpace
	CP	12						; FF, clear screen and home
	JP	Z,ANSI_ED_ED2
	CP	27
	JP	Z,EscapeCode			; If an Escape code, let's check it
	CP	9
	JP	Z,HorizontalTab
	CP	7
	JP	Z,Bell
	JP	PrintText_RLP_NOCC


;
; Internal Functions area
;
; In this section, functions for the rendering engine use
;
Bell:
	CALL BellSub
	JP	PrintText_RLP
BellSub:
	PUSH	HL
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	IY
	PUSH	IX
	LD	IX,0x017D
	CALL	CALSUB			; Interslot call to beep
	POP	IX
	POP	IY
	POP	DE
	POP	BC
	POP	AF
	POP	HL
	RET


EscapeCode:
	LD	A,(HL)
	INC	HL
	CP	'['
	JP	Z,Parameters
	CP	'A'
	JP	Z,VT52_UP
	CP	'B'
	JP	Z,VT52_DW
	CP	'C'
	JP	Z,VT52_RI
	CP	'D'
	JP	Z,VT52_LE
	CP	'H'
	JP	Z,VT52_HOME
	CP	'7'
	JP	Z,VT100_SCP
	CP	'8'
	JP	Z,VT100_RCP
	JP	PrintText_RLP


Parameters:
	LD	(OrgAddress),HL
	LD	DE,Parameters_PRM
	LD	(Parameters_PPT),DE
	XOR	A
	LD	(Parameters_PCT),A
Parameters_RLP:
	LD	DE,Parameters_PST		; PARAMETER STRING
	LD	C,0
Parameters_SCN:
	LD	A,(HL)
	INC	HL
	CP	';'
	JR	Z,Parameters_END
	CP	'0'
	JR	C,Parameters_END
	CP	'@'
	JR	NC,Parameters_END
	INC	C
	LD	(DE),A
	INC	DE
	JR	Parameters_SCN
Parameters_END:
	LD	(Parameters_TRM),A		; SAVE TERMINATING CHAR
	LD	A,C
	OR	A
	JR	Z,Parameters_SETOMT
	CP	1
	JR	Z,Parameters_RD1		; READ ONE DIGIT
	CP	2
	JR	Z,Parameters_RD2		; READ TWO DIGITS
	CP	3
	JR	Z,Parameters_RD3		; READ THREE DIGITS
	; More than three digits, just ignore for now
	PUSH	AF
	LD	A,'?'					; A command we do not support to make sure this is ignored
	LD	(Parameters_TRM),A		; TERMINATING CHARACTER
	POP	AF
	JR	Parameters_SET
Parameters_ERR:
	LD	HL,(EndAddress)		; Do not print sequences we do not handle
	XOR	A
	JP	PrintText_RLP
Parameters_RD1:
	LD	A,(Parameters_PST)
	SUB	48
	JR	Parameters_SET
Parameters_RD2:
	LD	A,(Parameters_PST)
	SUB	48
	ADD	A,A
	LD	C,A
	ADD	A,A
	ADD	A,A
	ADD	A,C
	LD	C,A
	LD	A,(Parameters_PST+1)
	SUB	48
	ADD	A,C
	JR	Parameters_SET
Parameters_RD3:
	LD	A,(Parameters_PST)
	SUB	48
	ADD	A,A
	LD	C,A
	ADD	A,A
	ADD	A,A
	ADD	A,C
	LD	C,A
	LD	A,(Parameters_PST+1)
	SUB	48
	ADD	A,C
	ADD	A,A
	LD	C,A
	ADD	A,A
	ADD	A,A
	ADD	A,C
	LD	C,A
	LD	A,(Parameters_PST+2)
	SUB	48
	ADD	A,C
Parameters_SET:
	LD	DE,(Parameters_PPT)	; PARAMETER POINTER
	LD	(DE),A
	INC	DE
	LD	(Parameters_PPT),DE
	LD	A,(Parameters_PCT)		; PARAMETER COUNT
	INC	A
Parameters_SETOMT:
	LD	B,A
	LD	(Parameters_PCT),A
	LD	A,(Parameters_TRM)		; TERMINATING CHARACTER
	CP	';'
	JP	Z,Parameters_RLP
	LD	(EndAddress),HL
	CP	20
	JP	C,Parameters_ERR
	CP	'H'
	JP	Z,ANSI_CUP
	CP	'f'
	JP	Z,ANSI_CUP
	CP	'R'
	JP	Z,ANSI_CUP
	CP	'A'
	JP	Z,ANSI_CUU
	CP	'B'
	JP	Z,ANSI_CUD
	CP	'C'
	JP	Z,ANSI_CUF
	CP	'D'
	JP	Z,ANSI_CUB
	CP	's'
	JP	Z,ANSI_SCP
	CP	'u'
	JP	Z,ANSI_RCP
	CP	'J'
	JP	Z,ANSI_ED
	CP	'K'
	JP	Z,ANSI_EL
	CP	'L'
	JP	Z,ANSI_IL
	CP	'M'
	JP	Z,ANSI_DL
	CP	'm'
	JP	Z,ANSI_SGR
	CP	'n'
	JP	Z,ANSI_CGP
	CP	'P'
	JP	Z,ANSI_DCH
	CP	'b'
	JP	Z,ANSI_REP
	CP	'd'
	JP	Z,ANSI_VPA
	CP	'e'
	JP	Z,ANSI_CUD
	CP	'G'
	JP	Z,ANSI_CHA
	CP	'I'
	JP	Z,ANSI_CHT
	CP	'Z'
	JP	Z,ANSI_CBT
	CP	'X'
	JP	Z,ANSI_ECH
	CP	'S'
	JP	Z,ANSI_SU
	CP	'T'
	JP	Z,ANSI_SD
	CP	'@'
	JP	Z,ANSI_ICH
	JP	Parameters_ERR


; OPJ - Add possibility to current cursor position be sent to a callback function
ANSI_CGP:						; ANSI Cursor Get Position
	LD	A,B
	CP	1
	JR	NZ,ANSI_CGP_END			; Not only 1 parameter, not 6n, done
	LD	A,(Parameters_PRM)
	CP	6						; Is it 6?
	JR	NZ,ANSI_CGP_END			; Not 6, so it is not 6N
	; Ok, ESC[6n, do we have a callback to report cursor position?
	LD	A,(ANSI_CB)			; Is there a callback programmed?
	OR	A
	JR	Z,ANSI_CGP_END			; Nope, sorry, nothing to do
	; So, lets report the position
	LD	A,(CursorCol)
	INC	A
	LD	L,A						; Column goes in L
	LD	A,(CursorRow)
	INC	A
	LD	H,A						; Row goes in H
ANSI_CGP_CALL_VEC:
	CALL	0					; This address will change when someone wants to receive callbacks
ANSI_CGP_END:
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_CUP:						; ANSI Cursor Position
	LD	A,B
	OR	A
	JR	Z,ANSI_CUP_HOM
	DEC	A
	JR	Z,ANSI_CUP_ROW
	LD	A,(Parameters_PRM+1)
	DEC	A
	LD	(CursorCol),A
ANSI_CUP_ROW:
	LD	A,(Parameters_PRM+0)
ANSI_CUP_ROW1:
	DEC	A
	LD	(CursorRow),A
	JR	ANSI_CUP_RET
ANSI_CUP_HOM:
	XOR	A
	LD	(CursorRow),A
	LD	(CursorCol),A
ANSI_CUP_RET:
	CALL	V9938_SetCursorX
	CALL	V9938_SetCursorY
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_CUU:						; ANSI Cursor Up
	LD	A,B
	LD	B,1
	OR	A
	JR	Z,ANSI_CUU_SET
ANSI_CUU_GTC:
	LD	A,(Parameters_PRM+0)
	LD	B,A
ANSI_CUU_SET:
	LD	A,(CursorRow)
	SUB	A,B
	JR	NC,ANSI_CUU_SCP
	XOR	A
ANSI_CUU_SCP:
	LD	(CursorRow),A
	CALL	V9938_SetCursorY
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_VPA:				; ANSI Vertical Position Absolute
	LD	A,255
	LD	(CursorRow),A
ANSI_CUD:				; ANSI Cursor Down
	LD	A,B
	LD	B,1
	OR	A
	JR	Z,ANSI_CUD_SET
ANSI_CUD_GTC:
	LD	A,(Parameters_PRM+0)
;OPJ - Fix for 255 so cursor row won't overlap and have a low value when it should be > 24
	CP	26
	JR	C,ANSI_CUD_SAV
	LD	A,25
ANSI_CUD_SAV:
	LD	B,A
ANSI_CUD_SET:
	LD	A,(CursorRow)
	ADD	A,B
; OPJ changes to allow 25 lines
	CP	25
	JR	C,ANSI_CUD_SCP
	LD	A,24
ANSI_CUD_SCP:
	LD	(CursorRow),A
	CALL	V9938_SetCursorY
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_CHA:				; ANSI Cursor Horizontal Absolute
	LD	A,255
	LD	(CursorCol),A
ANSI_CUF:						; ANSI Cursor Forward
	LD	A,B
	LD	B,1
	OR	A
	JR	Z,ANSI_CUF_SET
ANSI_CUF_GTC:
	LD	A,(Parameters_PRM+0)
;OPJ - Fix for 255 so cursor column won't overlap and have a low value when it should be > 24
	CP	81
	JR	C,ANSI_CUF_SAV
	LD	A,80
ANSI_CUF_SAV:
	LD	B,A
ANSI_CUF_SET:
	LD	A,(CursorCol)
	ADD	A,B
	CP	80
	JR	C,ANSI_CUF_SCP
	LD	A,79
ANSI_CUF_SCP:
	LD	(CursorCol),A
	CALL	V9938_SetCursorX
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_CUB:						; ANSI Cursor Back
	LD	A,B
	LD	B,1
	OR	A
	JR	Z,ANSI_CUB_SET
ANSI_CUB_GTC:
	LD	A,(Parameters_PRM+0)
	LD	B,A
ANSI_CUB_SET:
	LD	A,(CursorCol)
	SUB	A,B
	JR	NC,ANSI_CUB_SCP
	XOR	A
ANSI_CUB_SCP:
	LD	(CursorCol),A
	CALL	V9938_SetCursorX
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_SCP:						; ANSI Save Cursor Position
	LD	A,(CursorCol)
	LD	(SavedCol),A
	LD	A,(CursorRow)
	LD	(SavedRow),A
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_RCP:						; ANSI Restore Cursor Position
	LD	A,(SavedCol)
	LD	(CursorCol),A
	LD	A,(SavedRow)
	LD	(CursorRow),A
	CALL	V9938_SetCursorX
	CALL	V9938_SetCursorY
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_DCH:						; ANSI Delelete Characters
	LD	A,B
	OR	A
	JR	NZ,ANSI_DCH_GP
	; Default is delete one char if no number is given
	INC	A
	JP	V9938_DelChr
ANSI_DCH_GP:
	LD	A,(Parameters_PRM+0)	; Load parameter, number of characters to delete
	JP	V9938_DelChr


ANSI_REP:						; ANSI Repeat Last Character
	LD	A,B
	LD	B,1					; No parameter means repeat once
	OR	A
	JR	Z,ANSI_REP_RLP
	LD	A,(Parameters_PRM)
	LD	B,A						; Load the number of repeats
ANSI_REP_RLP:
	LD	A,(LastChar)
	PUSH	BC
	PUSH	HL
	CALL	V9938_PrintChar		; Call the print routine for our chip
	LD	A,(CursorCol)			; Get Current Cursor Position
	INC	A						; Increment it
	LD	(CursorCol),A			; Save
	PUSH	AF
	CALL	V9938_SetCursorX	; Set cursor on screen
	POP	AF
	CP	80
	JR	C,ANSI_REP_ELP			; If up to position 80, done
	XOR	A
	LD	(CursorCol),A			; Otherwise cursor is back to position 0
	CALL	LFeedSub			; And feed the line
ANSI_REP_ELP:
	POP	HL
	POP	BC
	DJNZ	ANSI_REP_RLP		; It's the end? No? Repeat!
	JP	PrintText_RLP


ANSI_ED:						; ANSI Erase in display
	LD	A,B
	OR	A
	JR	Z,ANSI_ED_ED0 			; Default is delete from current position on
	LD	A,(Parameters_PRM+0)
	CP	0
	JR	Z,ANSI_ED_ED0
	CP	1
	JR	Z,ANSI_ED_ED1
	CP	2
	JR	Z,ANSI_ED_ED2
ANSI_ED_ED0:
	JP	V9938_ErDis0
ANSI_ED_ED1:
	JP	V9938_ErDis1
ANSI_ED_ED2:
	CALL	ANSI_ED_ED2Sub
	LD	HL,(EndAddress)
	JP	PrintText_RLP

ANSI_ED_ED2Sub:
	CALL	V9938_ClearScreen
	; Usually should end-up here, but MS-DOS ANSI_SYS legacy place cursor on top left after ED
	; Norm is cursor should be where it was, but, no one follows it, thanks to MS :D
	XOR	A
	LD	(CursorRow),A
	LD	(CursorCol),A
	CALL	V9938_SetCursorX
	CALL	V9938_SetCursorY
	RET


ANSI_EL:						; ANSI Erase in Line
	LD	A,B
	OR	A
	JP	Z,V9938_ErLin0
	LD	A,(Parameters_PRM+0)
	CP	1
	JP	Z,V9938_ErLin1
	CP	2
	JP	Z,V9938_ErLin2
	JP	V9938_ErLin0

ANSI_IL:
	LD	A,B
	LD	B,1					; No number is one Row
	OR	A
	JR	Z,ANSI_IL_RUN
	LD	A,(Parameters_PRM)		; Read how many Rows
	LD	B,A
ANSI_IL_RUN:
	LD	A,(CursorRow)
	LD	C,A						; Copy Origin C (CursorRow)
	ADD	A,B
	CP	25
	JR	C,ANSI_IL_CONTINUE		; If less than 25, mean we need to move data before inserting lines
	; If number of lines to move reach the end of screen or more, set cursor to first column and Erase Display 0, then return cursor, it is faster
	LD	A,(CursorCol)
	PUSH	AF					; Save current Cursor Column
	XOR	A
	LD	(CursorCol),A			; For now in first column
	CALL	V9938_ErDis0Sub		; Make ED0
	POP	AF						; Restore column
	LD	(CursorCol),A			; Back to the right column
	JP	ANSI_IL_END				; And done
ANSI_IL_CONTINUE:
	; Ok, so we will need to move, delete and clear
	PUSH	BC					; Save B (how many rows)
	LD	B,A						; Copy Destination B
	LD	A,25					; 	(CursorRow + Rows)
	SUB	B						; RowsToCopy in A
								;	(25 - Destination Row)
	CALL	V9938_CopyBlockYUp
	POP	BC						; Load How many Rows
	LD	C,B						; Put Rows in C
	LD	B,0					; Indicates to use background color
	LD	A,(CursorRow)			; From current cursor row
	CALL	V9938_ClearBlock
ANSI_IL_END:
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_DL:						; ANSI Delete Lines
	LD	A,B
	LD	B,1					; No number is one Row
	OR	A
	JR	Z,ANSI_DL_RUN
	LD	A,(Parameters_PRM)		; Read how many Rows
	LD	B,A
ANSI_DL_RUN:
	LD	A,(CursorRow)
	LD	C,A						; CopyDestination C (CursorRow)
	ADD	A,B
	CP	25
	JR	C,ANSI_DL_CONTINUE		; If number of lines to move cursor to first column and Erase Display 0, then return cursor
	LD	A,(CursorCol)
	PUSH	AF					; Save current Cursor Column
	XOR	A
	LD	(CursorCol),A			; For now in first column
	CALL	V9938_ErDis0Sub		; Make ED0
	POP	AF						; Restore column
	LD	(CursorCol),A			; Back to the right column
	JP	ANSI_DL_END				; And done
ANSI_DL_CONTINUE:
	; Ok, so we will need to move, delete and clear
	PUSH	BC					; Save B (how many rows)
	LD	B,A						; Copy Source B
	LD	A,26					; 	(CursorRow + Rows)
	SUB	B						; RowsToCopy A
								;	(26 - CopySource)
	CALL	V9938_CopyBlockYDown
	POP	BC						; Load How many Rows
	LD	A,25
	SUB	B						; Clear from the End Of Screen
	LD	C,B						; Put Rows in C
	LD	B,0					; Indicates to use background color
	CALL	V9938_ClearBlock
ANSI_DL_END:
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_CHT:						; ANSI Horizontal Tab
	LD	A,B
	LD	B,1					; No number is one Tab
	OR	A
	JR	Z,ANSI_CHT_RLP
	LD	A,(Parameters_PRM)
	LD	B,A						; Load the number of repeats
ANSI_CHT_RLP:
	PUSH	BC
	PUSH	HL
	CALL	HTabSub
	POP	HL
	POP	BC
	DJNZ	ANSI_CHT_RLP		; It's the end? No? Repeat!
	JP	PrintText_RLP


ANSI_CBT:						; ANSI Cursor Backwards Tabulation
	LD	A,B
	LD	B,1					; No number is one Tab
	OR	A
	JR	Z,ANSI_CBT_RLP
	LD	A,(Parameters_PRM)
	LD	B,A						; Load the number of repeats
ANSI_CBT_RLP:
	PUSH	BC
	PUSH	HL
	CALL	CBTabSub
	POP	HL
	POP	BC
	DJNZ	ANSI_CBT_RLP		; It's the end? No? Repeat!
	JP	PrintText_RLP


ANSI_ECH:						; ANSI Erase Character
	LD	A,B
	LD	C,1					; No parameter means erase one character
	OR	A
	JR	Z,ANSI_ECH_DO			; No parameter, no need to calculate, just do it
	LD	A,(CursorCol)
	LD	C,A						; Cursor Position in C
	LD	A,(Parameters_PRM)		; How many chars to delete in A
	ADD	C						;
	CP	80						; Let's check if it is lower than 80 (meaning is within our line)
	JR	C,ANSI_ECH_SLP			; If carry, ok, within, so no need to adjust value
	LD	A,80					; Otherwise let's just say it is 80 to adjust value
ANSI_ECH_SLP:
	SUB	C						; Subtract cursor position, this will be original B or what would be the chars up to the 80th character to keep it in the same line
	LD	C,A						; Characters to be erased in C
ANSI_ECH_DO:
	JP	V9938_ErChar0			; Erase those characters


ANSI_ICH:						; ANSI Insert Characters
	LD	A,B
	LD	C,1					; No number is one char inserted
	OR	A
	JR	Z,ANSI_ICH_RLP
	LD	A,(Parameters_PRM)
	LD	C,A
ANSI_ICH_RLP:
	JP	V9938_InsertChars

ANSI_SD:						; ANSI Scroll Down
	LD	A,B
	LD	B,1					; No number is one line scroll
	OR	A
	JR	Z,ANSI_SD_RLP
	LD	A,(Parameters_PRM)
	LD	B,A						; Load the number of lines to scroll
ANSI_SD_RLP:
	PUSH	BC
	CALL	V9938_ScrollDown
	POP	BC
	DJNZ	ANSI_SD_RLP			; It's the end? No? Repeat!
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_SU:						; ANSI Scroll Up
	LD	A,B
	LD	B,1					; No number is one line scroll
	OR	A
	JR	Z,ANSI_SU_RLP
	LD	A,(Parameters_PRM)
	LD	B,A						; Load the number of lines to scroll
ANSI_SU_RLP:
	PUSH	BC
	CALL	V9938_ScrollUp
	POP	BC
	DJNZ	ANSI_SU_RLP			; It's the end? No? Repeat!
	LD	HL,(EndAddress)
	JP	PrintText_RLP


ANSI_SGR:						; ANSI Set Graphics Rendition
	LD	A,B
	OR	A
	LD	DE,Parameters_PRM
	; OPJ: Zero parameters -> Reset attributes,
	JR	NZ,ANSI_SGR_RLP
	LD	(DE),A
	LD	B,0x01
ANSI_SGR_RLP:
	PUSH	BC
	LD	A,(DE)
	INC	DE
	OR	A
	JR	Z,ANSI_SGR_RES			; RESET ATTRIBUTES
	CP	1
	JR	Z,ANSI_SGR_BLD			; SET FONT TO BOLD
	CP	7
	JR	Z,ANSI_SGR_REV			; REVERSE COLORS
	CP	8
	JR 	Z,ANSI_SGR_CON			; CONCEALED (INVISIBLE)
	CP	27
	JR	Z,ANSI_SGR_URV			; UN-REVERSE COLORS
	CP	30
	JR	C,ANSI_SGR_UNK			; UNKNOWN / UNSUPPORTED
	CP	38
	JR	C,ANSI_SGR_SFC			; SET FOREGROUND COLOR
	CP	39
	JR	Z,ANSI_SGR_RFC			; RESET FOREGROUND COLOR
	CP	40
	JR	C,ANSI_SGR_UNK			; UNKNOWN / UNSUPPORTED
	CP	48
	JR	C,ANSI_SGR_SBC			; SET BACKGROUND COLOR
	CP	49
	JR	Z,ANSI_SGR_RBC			; RESET BACKGROUND COLOR
ANSI_SGR_UNK:
	POP	BC
	DJNZ	ANSI_SGR_RLP
ANSI_SGR_RET:
	LD	HL,(EndAddress)
	JP	PrintText_RLP
ANSI_SGR_RES:					; RESET ATTRIBUTES
	; PK: Reset text attributes, they
	;     are:
	;	1 Bold
	;	4 Underscore
	;	5 Blink on
	;	7 Reverse Video on
	;	8 Concealed on
	;     By now, this library supports
	;     BOLD, CONCEALED and REVERSE
	XOR	A
	LD	(HiLighted),A
	LD	(Reversed),A
	LD	(Concealed),A
	; PK: Some softwares expects that
	;     reset restore the text and
	;     background colors to a sane
	;     default
	LD	(BackColor),A
	LD	A,0x07
	LD	(ForeColor),A
	JR	ANSI_SGR_CLR
ANSI_SGR_BLD:
	LD	A,0x01
	LD	(HiLighted),A
	JR	ANSI_SGR_CLR
ANSI_SGR_REV:
	LD	A,(Reversed)
	OR	A
	JR	NZ,ANSI_SGR_CLR
	LD	A,0x01
	LD	(Reversed),A
	JR	ANSI_SGR_SWP
ANSI_SGR_CON:
	LD	A,0x01
	LD	(Concealed),A
	JR	ANSI_SGR_CLR
ANSI_SGR_URV:
	LD	A,(Reversed)
	OR	A
	JR	Z,ANSI_SGR_CLR
	XOR	A
	LD	(Reversed),A
	JR	ANSI_SGR_SWP
ANSI_SGR_RFC:
	LD	A,37
ANSI_SGR_SFC:
	SUB	30
	LD	(ForeColor),A
	JR	ANSI_SGR_CLR
ANSI_SGR_RBC:
	LD	A,40
ANSI_SGR_SBC:
	SUB	40
	LD	(BackColor),A
	JR	ANSI_SGR_CLR
ANSI_SGR_CLR:
	CALL	V9938_SetColors
	JR	ANSI_SGR_UNK
ANSI_SGR_SWP:
	LD	A,(ForeColor)
	LD	B,A
	LD	A,(BackColor)
	LD	(ForeColor),A
	LD	A,B
	LD	(BackColor),A
	JR	ANSI_SGR_CLR


VT52_ENCURSOR:
	LD	A,(CursorOn)
	OR	A
	RET	NZ						; If already on, nothing to do
	INC	A
	LD	(CursorOn),A			; Other than 0, on
	LD	(CursorUpdt),A			; Other than 0, update its position
EnCursorSub:
	DI
	LD	A,(VDP_08)				; Get a copy of register 8
	AND	0b11111101				; Clear bit to enable sprites
	LD	(VDP_08),A				; Save our value
	OUT	(0x99),A				; Send value to VDP
	LD	A,0x80+8
	OUT	(0x99),A				; Write to register 8
	EI
	RET


VT52_DISCURSOR:
	LD	A,(CursorOn)
	OR	A
	RET	Z						; If already off, nothing to do
	XOR	A
	LD	(CursorOn),A			; 0, off
	LD	(CursorUpdt),A			; 0, do not update its position
DisCursorSub:
	DI
	LD	A,(VDP_08)				; Get a copy of register 8
	OR	0b00000010				; Set bit to disable sprites
	LD	(VDP_08),A				; Save our value
	OUT	(0x99),A				; Send value to VDP
	LD	A,0x80+8
	OUT	(0x99),A				; Write to register 8
	EI
	RET


VT52_UP:
	LD	A,(CursorRow)
	OR	A
	JP	Z,PrintText_RLP
	DEC	A
	LD	(CursorRow),A
	CALL	V9938_SetCursorY
	JP	PrintText_RLP


VT52_DW:
	LD	A,(CursorRow)
	CP	24
	JP	NC,PrintText_RLP
	INC	A
	LD	(CursorRow),A
	CALL	V9938_SetCursorY
	JP	PrintText_RLP


VT52_LE:
	LD	A,(CursorCol)
	OR	A
	JP	Z,PrintText_RLP
	DEC	A
	LD	(CursorCol),A
	CALL	V9938_SetCursorX
	JP	PrintText_RLP


VT52_RI:
	LD	A,(CursorCol)
	CP	79
	JP	NC,PrintText_RLP
	INC	A
	LD	(CursorCol),A
	CALL	V9938_SetCursorX
	JP	PrintText_RLP


VT52_HOME:
	XOR	A
	LD	(CursorCol),A
	LD	(CursorRow),A
	CALL	V9938_SetCursorX
	CALL	V9938_SetCursorY
	JP	PrintText_RLP


VT100_SCP:
	LD	(EndAddress),HL
	JP	ANSI_SCP


VT100_RCP:
	LD	(EndAddress),HL
	JP	ANSI_RCP


BackSpace:
	CALL	BackSpaceSub
	JP	PrintText_RLP
BackSpaceSub:
	LD	A,(CursorCol)
	OR	A
	RET	Z
	DEC	A
	LD	(CursorCol),A
	JP	V9938_SetCursorX


HorizontalTab:
	CALL	HTabSub
	LD	HL,(EndAddress)
	JP	PrintText_RLP
HTabSub:
	LD	A,(CursorCol)			; Get the current column
	OR	7						; Goes to the next tabstop
								; Tabstops traditionally are
								; in each 8th column
	CP	79
	JP	Z,HTabSub_SCP
	INC	A						; Some adjusts here and there...
HTabSub_SCP:
	LD	(CursorCol),A
	CALL	V9938_SetCursorX
	RET


CBTabSub:
	LD	A,(CursorCol)			; Get the current column
	DEC	A
	AND	248					; Goes to the previous tabstop
								; Tabstops traditionally were
								; in each 8th column
	CP	248
	JP	NZ,CBTabSub_SCP
	XOR	A						; Positions belows 0 are 0
CBTabSub_SCP:
	JR	HTabSub_SCP


LineFeed:
	CALL	LFeedSub
	JP	PrintText_RLP
LFeedSub:
	LD	A,(CursorRow)
	INC	A
	CP	25
	JR	C,LFeedSub_NNL
	CALL	V9938_ScrollUp
	LD	A,24
LFeedSub_NNL:
	LD	(CursorRow),A
	CALL	V9938_SetCursorX
	CALL	V9938_SetCursorY
	RET


CarriageReturn:
	CALL	CarriageReturnSub;
	JP	PrintText_RLP
CarriageReturnSub:
	XOR	A
	LD	(CursorCol),A
	JP	V9938_SetCursorX


_BIOS_C:						; BIOS_C: [IX]
	LD	IY,(0xFCC0)
	JP	0x001C

;
;	V9938 Related Code
;
;	This is where all V9938 (MSX2/2+) specific routines and defines are
;
VDP_07	EQU	0xF3E6
VDP_08	EQU	0xFFE7
VDP_09	EQU	0xFFE8
VDP_23	EQU	0xFFF6
VDP_01	EQU	0xF3E0
VDP_06	EQU	0xF3E5
VDP_05	EQU	0xF3E4
VDP_11	EQU	0xFFEA
VDP_14	EQU	0xFFED
VDP_16	EQU	0xFFEF

; SUB-ROM entries
;
iniPlt	EQU	0x0141
rstPlt	EQU	0x0145

; CALSUB
;
; In: IX = address of routine in MSX2 SUBROM
;     AF, HL, DE, BC = parameters for the routine
;
; Out: AF, HL, DE, BC = depending on the routine
;
; Changes: IX, IY, AF', BC', DE', HL'
;
; Call MSX2 subrom from MSXDOS. Should work with all versions of MSXDOS_
;
; Notice: NMI hook will be changed. This should pose no problem as NMI is
; not supported on the MSX at all_
;
CALSLT	EQU	0x001C
NMI	EQU	0x0066
EXTROM	EQU	0x015F
EXPTBL	EQU	0xFCC1
H_NMI	EQU	0xFDD6
;
CALSUB:
	EXX
	EX     AF,AF'       		; store all registers
	LD     HL,EXTROM
	PUSH   HL
	LD     HL,0xC300
	PUSH   HL         			; push NOP ; JP EXTROM
	PUSH   IX
	LD     HL,0x21DD
	PUSH   HL					; push LD IX,<entry>
	LD     HL,0x3333
	PUSH   HL					; push INC SP; INC SP
	LD     HL,0
	ADD    HL,SP				; HL = offset of routine
	LD     A,0xC3
	LD     (H_NMI),A
	LD     (H_NMI+1),HL		; JP <routine> in NMI hook
	EX     AF,AF'
	EXX							; restore all registers
	LD     IX,NMI
	LD     IY,(EXPTBL-1)
	CALL   CALSLT				; call NMI-hook via NMI entry in ROMBIOS
								; NMI-hook will call SUBROM
	EXX
	EX     AF,AF'				; store all returned registers
	LD     HL,10
	ADD    HL,SP
	LD     SP,HL				; remove routine from stack
	EX     AF,AF'
	EXX							; restore all returned registers
	RET


V9938_Init:
	LD	A,0x07
	LD	IX,0x005F
	CALL	_BIOS_C				; Interslot call to set screen 7
	; Now let's set a lot of registers :)
	LD	A,0x00
	LD	(VDP_23),A				; R23, first line to draw is 0
	DI
	LD	A,0xF0					; Text1 and Text2 color 15, Border and Background color 0
	LD	(VDP_07),A				; R7 status
	OUT	(0x99),A
	LD	A,0x80+7
	OUT	(0x99),A				; Write to register 7

	LD	A,(VDP_08)				; Get a copy of register 8
	OR	0b00100010				; Set bit so color 0 is 0 in palette and disable sprites
	LD	(VDP_08),A				; Save our value
	OUT	(0x99),A				; Send value to VDP
	LD	A,0x80+8
	OUT	(0x99),A				; Write to register 8

	LD	A,(VDP_09)				; Get a copy of register 9
	OR	0b10000000				; 212 Lines by seting 8th bit
	LD	(VDP_09),A				; Save our new value
	OUT	(0x99),A				; Send value to VDP
	LD	A,0x80+9
	OUT	(0x99),A				; Write to register 9

	LD	A,0x00					; Palette register pointer set to 0
	LD	(VDP_16),A				; Save R16 status
	OUT	(0x99),A				; Send value to VDP
	LD	A,0x80+16
	OUT	(0x99),A				; Write to register 16, new palette pointer

	EI						; Ok to have interrupts now
	LD	HL,ANSI_PAL				; Address of our palette
	LD	BC,0x209A				; 32 bytes to move to port 0x9a which will auto-increment palette registers
	OTIR						; Send it
	RET							; Done!


V9938_Finish:
	DI
	LD	A,0x00
	OUT	(0x99),A
	LD	A,0x80+23
	OUT	(0x99),A				; Register 23 goes to 0 to reset vertical offset
	LD	(VDP_23),A				; R23, first line to draw is 0
	LD	IX,0xD2
	LD	IY,(0xFCC0)			; Call TOTEXT bios function
	CALL CALSLT
	EI
	LD	IX,iniPlt
	CALL	CALSUB
	LD	IX,rstPlt				; Restore the saved palette
	CALL CALSUB
	EI
	RET							; Done!


;OPJ - Sprite Cursor initialization
V9938_InitCursor:
	DI
	; First Set Pattern Table Address
	LD	A,0b00111111			; sprite pattern table = 1F800-1FFFF
	LD	(VDP_06),A				; Save our value
	OUT	(0x99),A				; Send value
	LD	A,0x80+6
	OUT	(0x99),A				; Write in register
	; Now Set Sprite Attribute Table Address
	LD	A,0b11101111			; sprite attribute table = 1F600 / So Color Table will be 1F400 (14 - 10 and 3 1s)
	LD	(VDP_05),A				; Save our value
	OUT	(0x99),A				; Send value
	LD	A,0x80+5
	OUT	(0x99),A				; Write in register
	LD	A,0b00000011			; A16 - 1 And A15 - 1
	LD	(VDP_11),A				; Save our value
	OUT	(0x99),A				; Send value
	LD	A,0x80+11
	OUT	(0x99),A				; Write in register
	;SET VDP TO WRITE @ Color Table starting at Sprite 0 (1F400)
	LD	A,0b00000111			; A16, A15 and A14 set to 1
	LD	(VDP_14),A				; Save our value
	OUT	(0x99),A				; Send value
	LD	A,0x80+14
	OUT	(0x99),A				; Write in register
	LD	A,0b00000000			; Now A7 to A0, all 0's
	OUT	(0x99),A				; Low Address
	LD	A,0b01110100			; Write (bit 6), A13/A12 to 1(1F) / A11 to 0 and A10 to 1 and A9-A8 to 0 (4)
	OUT	(0x99),A				; High Address
	;Colors for 2 sprites is 32 bytes long
	LD	HL,SPRITE_COLORS
	LD	BC,0x2098
V9938_InitCursor_COLRLOOP:
	OUTI
	NOP
	NOP
	JR	NZ,V9938_InitCursor_COLRLOOP
	;SET VDP TO WRITE @ Pattern Table starting at Sprite 0 (1F800)
	LD	A,0b00000111			; A16/15/14 set to 1
	LD	(VDP_14),A				; Save our value
	OUT	(0x99),A				; Send value
	LD	A,0x80+14
	OUT	(0x99),A				; Write in register
	LD	A,0b00000000			; Now A7 to A0, all 0's
	OUT	(0x99),A				; Low Address
	LD	A,0b01111000			; Write (bit 6),  A12 1
	OUT	(0x99),A				; High Address
	;Patterns for 2 sprites is 16 bytes long
	LD	HL,PATTERN_CURSOR
	LD	BC,0x1098
V9938_InitCursor_PATRNLOOP:
	OUTI
	NOP
	NOP
	JR	NZ,V9938_InitCursor_PATRNLOOP
	;SET VDP TO WRITE @ Attribute Table starting at Sprite 0 (1F600)
	LD	A,0b00000111			; A16, A15 and A14 set to 1
	LD	(VDP_14),A				; Save our value
	OUT	(0x99),A				; Send value
	LD	A,0x80+14
	OUT	(0x99),A				; Write in register
	LD	A,0b00000000			; Now A7 to A0, all 0's
	OUT	(0x99),A				; Low Address
	LD	A,0b01110110			; Write (bit 6), A13/A12 to 1(1F) / A11 to 0 and A10/A9 to 1 and A8 to 0 (6)
	OUT	(0x99),A				; High Address
	;Attributes for 2 sprites is 8 bytes long
	LD	HL,SPRITE_TABLE
	LD	BC,0x0898
V9938_InitCursor_ATTRLOOP:
	OUTI
	NOP
	NOP
	JR	NZ,V9938_InitCursor_ATTRLOOP
	; Done with setting
	DI
	LD	A,(VDP_08)				; Get a copy of register 8
	AND 0b11111101				; Enable Sprites (cursor)
	LD	(VDP_08),A				; Save our value
	OUT	(0x99),A				; Send value to VDP
	LD	A,0x80+8
	OUT	(0x99),A				; Write to register 8
	EI
	LD	(CursorOn),A			; Other than 0, on
	LD	(CursorUpdt),A			; Other than 0, update it's position
	RET


V9938_CursorColor:
	;SET VDP TO WRITE @ Color Table starting at Sprite 0 Line 6 (1F405)
	LD	A,0b00000111			; A16, A15 and A14 set to 1
	DI
	LD	(VDP_14),A				; Save our value
	OUT	(0x99),A				; Send value
	LD	A,0x80+14
	OUT	(0x99),A				; Write in register
	LD	A,0b00000101			; Now A7 to A0
	OUT	(0x99),A				; Low Address
	LD	A,0b01110100			; Write (bit 6), A13/A12 to 1(1F) / A11 to 0 and A10 to 1 and A9-A8 to 0 (4)
	OUT	(0x99),A				; High Address
	LD	A,(HiLighted)
	OR	A
	LD	A,(ForeColor)
	JR	Z,V9938_CursorColor_NHA
	ADD	0x08
V9938_CursorColor_NHA:
	OR	0x20					; Color attribute
	LD	B,2
V9938_CursorColor_CCLRLOOP:
	;Update 1st line
	OUT	(0x98),A
	NOP
	NOP
	DJNZ	V9938_CursorColor_CCLRLOOP
	EI
	RET


V9938_PrintChar:
	LD	B,A
	LD	A,(Concealed)
	OR	A
	JR	NZ,V9938_PrintChar_SPC	; Concealed = not visible -> space
	LD	A,B
	CP	0x20
	JR	Z,V9938_PrintChar_SPC	; Space -> just blank / background color
	CP	0xDB
	JR	Z,V9938_PrintChar_FIL	; Fill -> just filled / foreground color
	LD	DE,FontData			; Otherwise, let's get from our font
	LD	L,A
	LD	H,0					; Character in HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL					; Each caracter is composed of 8 bytes, thus multiply by 8
	ADD	HL,DE					; Add to font table start address and we got our character
	LD	DE,ColorTable			; Color Table address in DE
	LD	A,(HL)					; First line of this character in A
	AND	0b11000000				; Dealing with the 8th and 7th bits, we are going to print every two pixels, left to right
	RLCA
	RLCA
	ADD	A,ColorTable & 255			; Ok, so this is the base of color table (back/back, back/fore, fore/back, fore/fore) depending on each pixel
	LD	E,A						; move it to E
	LD	A,(DE)					; And A has the result of the two pixels
	LD	(HMMC_CMD_CLR),A		; Move it to HMMC color pair (the first two pixels of HMMC operation)
	CALL	DO_HMMC				; Move this to VDP
	LD	BC,0x089B				; now going to do for the remaining 7 bytes
	JR	V9938_PrintChar_BP1
V9938_PrintChar_BP0:	LD	A,(HL)
	AND	0b11000000				; Dealing with the 8th and 7th bits, we are going to print every two pixels, left to right
	RLCA
	RLCA
	ADD	A,ColorTable & 255			; Ok, so this is the base of color table (back/back, back/fore, fore/back, fore/fore) depending on each pixel
	LD	E,A						; move it to E
	LD	A,(DE)					; And A has the result of the two pixels
	OUT	(C),A					; Send it
V9938_PrintChar_BP1:	LD	A,(HL)
	AND	0b00110000				; Now we are dealing with the 5th and 6th bits
	RRCA
	RRCA
	RRCA
	RRCA
	ADD	A,ColorTable & 255			; Ok, so this is the base of color table (back/back, back/fore, fore/back, fore/fore) depending on each pixel
	LD	E,A						; move it to E
	LD	A,(DE)					; And A has the result of the two pixels
	OUT	(C),A					; Send it
V9938_PrintChar_BP2:	LD	A,(HL)
	AND	0b00001100				; Now we are dealing with the 3rd and 4th bits
	RRCA
	RRCA
	ADD	A,ColorTable & 255			; Ok, so this is the base of color table (back/back, back/fore, fore/back, fore/fore) depending on each pixel
	LD	E,A						; move it to E
	LD	A,(DE)					; And A has the result of the two pixels
	OUT	(C),A					; Send it (characters are contained in bits 8 to 3 (including), bits 1 and 2 are not used, 6 bits wide font
V9938_PrintChar_RLP:	INC	HL	; Next row of pixels for this character
	DJNZ	V9938_PrintChar_BP0	; If not fineshed, let's start for the next row of pixels (B has the count)
	RET							; Otherwise, finished printing all 8 rows
V9938_PrintChar_SPC:
	LD	A,(ColorTable+0)
	LD	(HMMC_CMD_CLR),A		; Space is background and background
	CALL	DO_HMMC				; setup HMMC and do the first two pixels
	LD	A,(ColorTable+0)		; Again, background on background
V9938_PrintChar_OUT:
	LD	BC,0x179B				; 8*3 (double pixels) = 24, lets do the reamaining 23
V9938_PrintChar_SPL:
	OUT	(C),A					; Send it
	DJNZ	V9938_PrintChar_SPL	; Decrement counter, if not zero, do it again
	RET							; Done
V9938_PrintChar_FIL:
	LD	A,(ColorTable+3)
	LD	(HMMC_CMD_CLR),A		; Fill is foreground and foreground
	CALL	DO_HMMC				; setup HMMC and do the first two pixels
	LD	A,(ColorTable+3)		; Again foreground and foreground
	JR	V9938_PrintChar_OUT		; Repeat the remaining pixels


V9938_ScrollUp:
	PUSH	HL
	LD	A,25
	LD	B,0					;Indicates to use background color
	CALL	V9938_ClearLine
	; OPJ - To avoid previous lines to show in the bottom when rolling multiple lines
	LD	B,1					;Indicates to use border color
	CALL	V9938_ClearTop
	POP	HL
	LD	A,(VDP_23)
	ADD	0x08
	LD	(VDP_23),A
	DI
	OUT	(0x99),A
	LD	A,0x80+23
	OUT	(0x99),A
	EI
	RET


V9938_ScrollDown:
	PUSH	HL
	LD	A,24
	LD	B,1					;Indicates to use border color
	CALL	V9938_ClearLine
	POP	HL
	LD	A,(VDP_23)
	SUB	0x08
	LD	(VDP_23),A
	DI
	OUT	(0x99),A
	LD	A,0x80+23
	OUT	(0x99),A
	EI
	; Make sure the first line now has the correct color attribute
	LD	B,0					;Indicates to use background color
	CALL	V9938_ClearTop
	RET



V9938_SetCursorX:
	LD	A,(CursorCol)
	LD	B,A
	ADD	A,A
	ADD	A,B
	ADD	A,8					; Border offset 16 pixels
	LD	(SPRITEPOS_X),A
	ADD	A,A						; HMMC work with real pixel count, not double pixels
	LD	(HMMC_CMD_DXL),A
	LD	A,0					; Do not want to change carry
	JR	NC,V9938_SetCursorX_SETDXH
	INC	A						; If carry it is 1
V9938_SetCursorX_SETDXH:
	LD	(HMMC_CMD_DXH),A
	LD	A,(CursorUpdt)			; If cursor is being updated, update its position in the table
	OR	A
	RET	Z
	;SET VDP TO WRITE @ 0x1F601 - Attribute Table
	LD	A,0b00000111			; A16, A15 and A14 set to 1
	LD	(VDP_14),A				; Save our value
	DI
	OUT	(0x99),A				; Send value
	LD	A,0x80+14
	OUT	(0x99),A				; Write in register
	LD	A,0b00000001			; Now A7 to A0, all 0's
	OUT	(0x99),A				; Low Address
	LD	A,0b01110110			; Write (bit 6), A13/A12 to 1(1F) / A11 to 0 and A10/A9 to 1 and A8 to 0 (6)
	OUT	(0x99),A				; High Address
	; X Position
	LD	A,(SPRITEPOS_X)
	OUT	(0x98),A				; Set X
	EI
	RET



V9938_SetCursorY:
	LD	A,(CursorRow)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A						; Copy IYL to B
	LD	A,(VDP_23)				; Get current vertical offset
	ADD	A,B						; Add our IYL to it
	LD	(HMMC_CMD_DYL),A
	LD	A,(CursorUpdt)			; If cursor is being updated, update its position in the table
	OR	A
	RET	Z
	;SET VDP TO WRITE @ 0x1F600 - Attribute Table
	LD	A,0b00000111			; A16, A15 and A14 set to 1
	LD	(VDP_14),A				; Save our value
	DI
	OUT	(0x99),A				; Send value
	LD	A,0x80+14
	OUT	(0x99),A				; Write in register
	LD	A,0b00000000			; Now A7 to A0, all 0's
	OUT	(0x99),A				; Low Address
	LD	A,0b01110110			; Write (bit 6), A13/A12 to 1(1F) / A11 to 0 and A10/A9 to 1 and A8 to 0 (6)
	OUT	(0x99),A				; High Address
	; Y Position
	LD	A,(HMMC_CMD_DYL)
	LD	B,A						; Copy IYL to B
	OUT	(0x98),A				; Set Y
	EI
	RET


V9938_ClearLine:
	LD	C,1
V9938_ClearBlock:
;
; A <- SourceRow
; B <- 0 fill w/ back color otherwise fill w/ border color
; C <- Rows
;
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_DYL),A		; Number of lines * 8 = position of the last line
	LD	A,C
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_NYL),A		; Will paint a rectangle with C*8 pixels on the Y axys
	XOR	A
	LD	(HMMV_CMD_DXL),A
	LD	A,0xE0
	LD	(HMMV_CMD_NXL),A
	LD	A,0x01
	LD	(HMMV_CMD_NXH),A		; The rectangle is 480 pixels on the X axis
	LD	A,B
	OR	A
	LD	A,(BackColor)
	JR	Z,V9938_ClearBlock_Cont
	LD	A,(BorderColor)
V9938_ClearBlock_Cont:
	LD	(ClearColor),A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A
	LD	A,(ClearColor)
	OR	B						; Adjust color in the right format
	LD	(HMMV_CMD_CLR),A		; Color to paint the rectangle
	JP	DO_HMMV


; OPJ - To avoid previous lines to show in the bottom when rolling multiple lines
V9938_ClearTop:
	XOR	A
	LD	(HMMV_CMD_DYL),A		; position of the first line
	LD	A,0x08
	LD	(HMMV_CMD_NYL),A		; Will paint a rectangle with 8 pixels on the Y axys
	XOR	A
	LD	(HMMV_CMD_DXL),A
	LD	A,0xE0
	LD	(HMMV_CMD_NXL),A
	LD	A,0x01
	LD	(HMMV_CMD_NXH),A		; The rectangle is 480 pixels on the X axis
	LD	A,B
	OR	A
	LD	A,(BackColor)
	JR	Z,V9938_ClearTop_Cont
	LD	A,(BorderColor)
V9938_ClearTop_Cont:
	LD	(ClearColor),A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A
	LD	A,(ClearColor)
	OR	B						; Adjust color in the right format
	LD	(HMMV_CMD_CLR),A		; Color to paint the rectangle
	JP	DO_HMMV


V9938_ClearScreen:
	CALL	V9938_WaitCmd		; Make sure VDP is not processing any command
	DI
	;OPJ - Set border color same as back color
	LD	A,(BackColor)			; Text1 and Text2 color 15, Border and Background color 0
	LD	(BorderColor),A			; Save the new border color
	LD	(VDP_07),A
	OUT	(0x99),A
	LD	A,0x80+7
	OUT	(0x99),A				; Write to register 7
	;OPJ - End
	LD	A,0x24
	OUT	(0x99),A
	LD	A,0x91
	OUT	(0x99),A				; Indirect access to registers, starting at 36
	EI
	LD	C,0x9B					;Now indirect writes starting at register 36
	XOR	A
	OUT	(C),A					; DXL = 0
	NOP
	OUT	(C),A					; DXH = 0
	NOP
	OUT	(C),A					; DYL = 0
	NOP
	OUT	(C),A					; DYH = 0
	NOP
	OUT	(C),A					; NXL  = 0
	LD	A,0x02
	OUT	(C),A					; NXH = 2 (512 dots)
	XOR	A
	OUT	(C),A					; NYL = 0
	INC	A
	OUT	(C),A					; NYH = 1 (256 dots)
	LD	A,(BackColor)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A
	LD	A,(BackColor)
	OR	B
	OUT	(C),A					; CLR
	LD	A,0x00
	OUT	(C),A					; ARG
	LD	A,0xC0
	OUT	(C),A					; CMD
	RET

V9938_InsertChars:
	; Number of characters to insert in C
	LD	A,(CursorCol)			;
	LD	B,A						; Cursor column in B
	ADD	A,C						; Lets Check if cursor pos + inserted characters equals or exceed a line limit
	CP	79						; So, if 79 (80 columns) or less, will carry
	JP	NC,V9938_ErLin0			; If no carry, no need to move blocks, we can just use a line deletion that will be way faster
	; If here cursor pos + inserted characters less than a line, so we need to do the following:
	; - Calculate the size of the block to move (End of screen - (Cursor Position + Inserted Chars))
	; - Move the block (it should be a move to the left, from right edge - inserted chars
	; - Erase  of Inserted Chars beginning in the cursor position
	LD	A,79
	SUB	A,B						; Ok, how many characters do we have including the one in cursor?
	SUB	A,C						; And this is how many characters we need to move to cursor position + inserted chars
	INC	A
	LD	B,A						; B contains character width of block being moved
	ADD	A,A
	ADD	A,B						; Multiply it by 3, number of "double pixels" (6 pixel width, 3 double pixels width)
	ADD	A,A						; And now double it to adjust, length is in pixels
	LD	(HMMM_CMD_NXL),A		; Store as NX lower byte
	LD	A,0x00					; Probably will be 0 NX higher byte
	JR	NC,V9938_InsChr_NXH		; But if carry, means it is 1
	INC	A						; If carry, NXh is 1
V9938_InsChr_NXH:
	LD	(HMMM_CMD_NXH),A		; Store it
	LD	A,0x08
	LD	(HMMM_CMD_NYL),A		; A line has 8 pixels, so NYL is 8
	; No need to change NYH, always 0
	LD	A,C
	ADD	A,A
	ADD	A,C
	LD	D,A						; Number of chars to insert *3 in D
	LD	A,0xEE					; Rightmost edge in pixels is 0x01DE
	LD	(HMMM_CMD_DXL),A		; Now destination is rightmost edge
	LD	A,0x01					; Rightmost edge in pixels is 0x01DE
	LD	(HMMM_CMD_DXH),A		; Now destination is rightmost edge
	LD	A,247					; Rightmost edge in double pixels 239 + 8 pixels from the border = 247
	SUB	A,D						; This is our source, rightmost edge - number of chars to insert
	ADD	A,A						; Multiply by 2
	LD	(HMMM_CMD_SXL),A		; Save source
	LD	A,0x00					; XH could be 0
	JR	NC,V9938_InsChr_SXH		; If no carry, it is 0
	INC	A						; Otherwise it is 1
V9938_InsChr_SXH:
	LD	(HMMM_CMD_SXH),A		; Save XH
	LD	A,(CursorRow)			; Current cursor line
	ADD	A,A
	ADD	A,A
	ADD	A,A						; Multiply it by 8, it is the first line of that character line (8 pixels high character)
	LD	B,A						; Copy Y to B
	LD	A,(VDP_23)				; Get current vertical offset
	ADD	A,B						; Add our Y to it
	LD	(HMMM_CMD_DYL),A		; This is the Y destination
	LD	(HMMM_CMD_SYL),A		; As well as the Y source
	LD	A,0x04					; We need the direction of move to be to the left, otherwise it won't work properly
	LD	(HMMM_CMD_ARG),A		;
	PUSH	BC					; Save Number of chars to insert
	CALL	DO_HMMM				; All set, let's move
	POP	BC						; Restore Number of chars to insert
	; Number of chars to erase (where characters will be inserted) is in C, ErChar will do the rest and return
	JP	V9938_ErChar0



	; Observing Windows 10 terminal behavior as well as XTERM, Del Char only deletes characters in the same line
	; Lines below are left untouched even if  of chars to delete surpass the  of chars in the line, and it does
	; not shift lines below up_
V9938_DelChr:
	LD	C,A						; Number of characters to delete in C
	LD	A,(CursorCol)			;
	LD	B,A						; Cursor column in B
	ADD	A,C						; Lets Check if cursor pos + deleted characters equals or exceed a line limit
	CP	79						; So, if 78 (79 columns) or less, will carry
	JP	NC,V9938_ErLin0			; If no carry, no need to move blocks, we can just use a line deletion that will be way faster
	; If here cursor pos + deleted characters less than a line, so we need to do the following:
	; - Calculate the size of the block to move (End of screen - (Cursor Position + Deleted Chars))
	; - Move the block
	; - Erase  of Deleted Chars after the end of the block
	LD	A,80
	SUB	A,B						; Ok, how many characters do we have including the one in cursor?
	SUB	A,C						; And this is how many characters we need to copy to cursor position
	INC A						;
	PUSH	AF					; Save this, we will use it later to delete characters by fake positioning cursor @ cursor pos + moved characters +1 and deleting from there to the end of line :)
	LD	B,A						; B contains character width of block being moved
	ADD	A,A
	ADD	A,B						; Multiply it by 3, number of "double pixels" (6 pixel width, 3 double pixels width)
	ADD	A,A						; And now double it to adjust lsb not considered
	LD	(HMMM_CMD_NXL),A		; Store as NX lower byte
	LD	A,0x00					; Probably will be 0 NX higher byte
	LD	(HMMM_CMD_ARG),A		; Take this chance to load CMD ARG we need for this operation (00)
	JR	NC,V9938_DelChr_NXH		; But if carry, means it is 1
	INC	A						; If carry, NXh is 1
V9938_DelChr_NXH:
	LD	(HMMM_CMD_NXH),A		; Store it
	LD	A,0x08
	LD	(HMMM_CMD_NYL),A
	; No need to change NYH, always 0
	LD	A,(CursorCol)
	LD	B,A
	ADD	A,A
	ADD	A,B						; Just adjust to count of "double pixels", HMMM function will handle DXH and shifting it
	LD	D,A						; Save A in D
	ADD	0x08					; Add 8 to X (A) - Border of 16 pixels
	ADD	A,A						; Multiply by 2
	LD	(HMMM_CMD_DXL),A		; Destination is current cursor position
	LD	A,0x00					; XH could be 0
	JR	NC,V9938_DelChr_DXH		; If no carry, it is 0
	INC	A						; Otherwise it is 1
V9938_DelChr_DXH:
	LD	(HMMM_CMD_DXH),A		; Save XH
	LD	A,C						; Now source is what is in D + 3 times what is in C
	ADD	A,A
	ADD	A,C						; A contains 3xdeleted characters
	ADD A,D						; + cursor position, this is the position of source X :D
	ADD	0x08					; Add 8 to X (A) - Border of 16 pixels
	ADD	A,A						; Multiply by 2
	LD	(HMMM_CMD_SXL),A		; Source is current cursor position + deleted characters
	LD	A,0x00					; XH could be 0
	JR	NC,V9938_DelChr_SXH		; If no carry, it is 0
	INC	A						; Otherwise it is 1
V9938_DelChr_SXH:
	LD	(HMMM_CMD_SXH),A		; Save XH
	LD	A,(CursorRow)			; Current cursor line
	ADD	A,A
	ADD	A,A
	ADD	A,A						; Multiply it by 8, it is the first line of that character line (8 pixels high character)
	LD	B,A						; Copy Y to B
	LD	A,(VDP_23)				; Get current vertical offset
	ADD	A,B						; Add our Y to it
	LD	(HMMM_CMD_DYL),A		; This is the Y destination
	LD	(HMMM_CMD_SYL),A		; As well as the Y source
	CALL	DO_HMMM				; All set, let's move
	POP	BC						; What we need to Add to Cursor is restored in B
	LD	A,(CursorCol)			; Current Cursor Column
	ADD	A,B						; Our fake cursor position
	JP	V9938_ErLin0_1			; Erase Line, but using what is in A, our fake cursor position, and return to processing after done
V9938_DelChr_SL:	LD	HL,(EndAddress)
	JP	PrintText_RLP


V9938_ErDis0:
	CALL 	V9938_ErDis0Sub
	LD	HL,(EndAddress)
	JP	PrintText_RLP
V9938_ErDis0Sub:
	LD	A,(CursorCol)
	LD	B,A
	ADD	A,A
	ADD	A,B
	LD	(HMMV_CMD_DXL),A		; DX = Number of column * 3 (this mode has doubled pixels in X axis)
	LD	B,A
	LD	A,240					; We draw up to 240 double-pixels (6 pixels wide characters * 80 columns)
	SUB	A,B						; Except the  pixels data up to the cursor position
	ADD	A,A						; And now double  it
	LD	(HMMV_CMD_NXL),A		; Store as NX lower byte
	LD	A,0x00					; Probably will be 0 NX higher byte
	JR	NC,V9938_ErDis0_NXH		; But if carry, means it is 1
	INC	A						; If carry, NXh is 1
V9938_ErDis0_NXH:
	LD	(HMMV_CMD_NXH),A		; Store it
	LD	A,(CursorRow)			; Now get the row / line
	ADD	A,A						; 8 pixels height each character, multiply it per 8
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_DYL),A		; This is the Y axys start
	LD	A,0x08
	LD	(HMMV_CMD_NYL),A		; To clear a single line it is 8 pixels height number of dots height
	LD	A,(BackColor)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A
	LD	A,(BackColor)
	OR	B						; Adjust color in the right format
	LD	(HMMV_CMD_CLR),A		; Color to paint the rectangle
	CALL	DO_HMMV				; Aaaand.... Clear!
	; Now, do we need to clear below cursor?
	LD	A,(CursorRow)			; Let's see how many pixels we need to fill
	LD	B,A						; Now get the row / line in B
	LD	A,24					; Up to 25 lines, 0 is first, 24 is the 25th line
	SUB	A,B						; Let's check how many extra lines need to be cleared
	RET	Z						; If last line, done
	; Not last, so multiply it per 8
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_NYL),A		; To clear remaining lines it is 8 pixels height multiplied by number of lines
	XOR	A
	LD	(HMMV_CMD_DXL),A		; DXL 0
	LD	A,0xE0					; We draw 240 double-pixels (6 pixels wide characters * 80 columns), 480 pixels, 0x01E0
	LD	(HMMV_CMD_NXL),A		; Store as NX lower byte
	LD	A,1
	LD	(HMMV_CMD_NXH),A		; Store NX higher byte
	LD	A,(CursorRow)			; Now get the row / line
	INC	A						; Next line
	ADD	A,A						; 8 pixels height each character, multiply it per 8
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_DYL),A		; This is the Y axys start
	CALL	DO_HMMV				; Aaaand.... Clear!
	RET



V9938_ErDis1:
	XOR	A
	LD	(HMMV_CMD_DXL),A		; DX = Beginning of line, 0
	LD	(HMMV_CMD_DXH),A		; DX = Beginning of line, 0
	LD	A,(CursorCol)
	LD	B,A
	ADD	A,A
	ADD	A,B						; Column * 6 = X coordinate of current cursor position
	ADD	A,A						; And now double  it
	LD	(HMMV_CMD_NXL),A		; Store as NX lower byte
	LD	A,0x00					; Probably will be 0 NX higher byte
	JR	NC,V9938_ErDis1_NXH		; But if carry, means it is 1
	INC	A						; If carry, NXh is 1
V9938_ErDis1_NXH:
	LD	(HMMV_CMD_NXH),A		; Store it
	LD	A,(CursorRow)			; Now get the row / line
	ADD	A,A						; 8 pixels height each character, multiply it per 8
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_DYL),A		; This is the Y axys start
	LD	A,0x08
	LD	(HMMV_CMD_NYL),A		; To clear a single line it is 8 pixels height number of dots height
	LD	A,(BackColor)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A
	LD	A,(BackColor)
	OR	B						; Adjust color in the right format
	LD	(HMMV_CMD_CLR),A		; Color to paint the rectangle
	CALL	DO_HMMV				; Aaaand.... Clear!
	; Now, do we need to clear above cursor?
	LD	A,(CursorRow)			; Let's see how many pixels we need to fill
	OR	A						; First row/line?
	JR	Z,V9938_ErDis1_SL		; If first line, done
	; Not first, so multiply it per 8
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_NYL),A		; To clear remaining lines it is 8 pixels height multiplied by number of lines - 1 (which is cursor row)
	XOR	A
	LD	(HMMV_CMD_DYL),A		; DYL, DXL ,DXH 0
	LD	(HMMV_CMD_DXL),A
	LD	(HMMV_CMD_DXH),A
	LD	A,0xE0					; We draw 240 double-pixels (6 pixels wide characters * 80 columns), 480 pixels, 0x01E0
	LD	(HMMV_CMD_NXL),A		; Store as NX lower byte
	LD	A,1
	LD	(HMMV_CMD_NXH),A		; Store NX higher byte
	CALL	DO_HMMV				; Aaaand.... Clear!
V9938_ErDis1_SL:	LD	HL,(EndAddress)
	JP	PrintText_RLP


V9938_ErChar0:
	LD	A,(CursorCol)			; Will start from current column
	LD	B,A
	ADD	A,A
	ADD	A,B						; A has column * 3
	LD	(HMMV_CMD_DXL),A		; Store in the destination X
	LD	A,C						; Characters to delete in C
	ADD	A,A
	ADD	A,C
	ADD	A,A						; And now double it, chars * 6
	LD	(HMMV_CMD_NXL),A		; This is the number of pixels to erase
	LD	A,0x00					; High byte could be 0
	JR	NC,V9938_ErChar0_NXH	; If did not carry, it is
	INC	A						; Otherwise it is 1
V9938_ErChar0_NXH:
	LD	(HMMV_CMD_NXH),A		; High Byte number of pixels to erase
	LD	A,(CursorRow)			; Now calculate destination Y
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	(HMMV_CMD_DYL),A		; Row * 8 is the Y position
	LD	A,0x08
	LD	(HMMV_CMD_NYL),A		; And delete 8 pixels in Y direction, one line
	LD	A,(BackColor)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A
	LD	A,(BackColor)
	OR	B						; Adjust color in the right format
	LD	(HMMV_CMD_CLR),A		; Color to paint the rectangle
	CALL	DO_HMMV				; And erase this
	LD	HL,(EndAddress)
	JP	PrintText_RLP


V9938_ErLin0:
	LD	A,(CursorCol)			; Will start from current column
V9938_ErLin0_1:
	LD	B,A						; Cursor column in B
	ADD	A,A
	ADD	A,B						; A has column * 3
	LD	(HMMV_CMD_DXL),A		; Store in the destination X
	LD	B,A						; Save it in B (this is a value in double pixels)
	LD	A,240					; 240 double pixels is a line width (80x6)
	SUB	A,B						; Subtract the total width from the current width
	ADD	A,A						; Now this information is need in real pixels, so double it
	LD	(HMMV_CMD_NXL),A		; And this the X axys lenght of the command
	LD	A,0x00					; High Byte could be 0
	JR	NC,V9938_ErLin0_NXH		; And it is zero if no carry
	INC	A						; Ok, carry, so it is 1
V9938_ErLin0_NXH:
	LD	(HMMV_CMD_NXH),A		; High Byte of X axys lenght
	LD	A,(CursorRow)			; Now get the current line
	ADD	A,A
	ADD	A,A
	ADD	A,A						; Multiply per 8 as each line is 8 pixelslarge
	LD	(HMMV_CMD_DYL),A		; This is the destination Y
	LD	A,0x08
	LD	(HMMV_CMD_NYL),A		; a line is 8 pixes, so this the Y axys lenght of the command
	LD	A,(BackColor)
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	B,A
	LD	A,(BackColor)
	OR	B						; Adjust color in the right format
	LD	(HMMV_CMD_CLR),A		; Color to paint the rectangle
	CALL	DO_HMMV				; and perform the HMMV command to delete it
	LD	HL,(EndAddress)
	JP	PrintText_RLP


V9938_ErLin1:
	XOR	A
	LD	(HMMV_CMD_DXL),A
	LD	(HMMV_CMD_DXH),A
	LD	A,(CursorCol)
	LD	B,A
	ADD	A,A
	ADD	A,B
	LD	C,0
	ADD	A,A
	JR	NC,V9938_ErLin1_CNT
	INC	C
V9938_ErLin1_CNT:	LD	(HMMV_CMD_NXL),A
	LD	A,C
	JP	V9938_ErLin0_NXH


V9938_ErLin2:
	LD	A,(CursorRow)			; Clear Entire Line
	LD	B,0					; Background color
	CALL	V9938_ClearLine
	XOR	A
	LD	(CursorCol),A
	CALL	V9938_SetCursorX
	LD	HL,(EndAddress)
	JP	PrintText_RLP


V9938_SetColors:
	LD	A,(HiLighted)			; Let's check if HiLighted
	OR	A
	LD	A,(ForeColor)			; And get the foreground color
	JR	Z,V9938_SetColors_NHA	; If not HiLighted, move on
	ADD	0x08					; Otherwise, different color, add 8 to get colors 9 to 16 of our pallete
V9938_SetColors_NHA:	LD	B,A ; Ok, palete color index in B
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A						; Multiply by 16 -> Shift left 4 times -> Value in MSB
	OR	B						; And value now in LSB as well, colors are pairs for G6
	LD	(FontColor),A			; And this is our font color (Fore / Fore)
	LD	A,(BackColor)			; Do the same to background color
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A						; Multiply by 16 -> Shift left 4 times -> Value in MSB
	LD	B,A						; B has background color in MSB and 0 in LSB
	LD	A,(BackColor)			; A has background color in LSB
	OR	B						; And value now in LSB as well, colors are pairs for G6
	LD	(ColorTable+00),A		; ColorTable 0 -> Background and BackGround
	LD	A,(FontColor)
	AND	0x0F					; Foreground color on LSB
	OR	B						; Background color on MSB
	LD	(ColorTable+01),A		; Color table 1 ->Background and Foreground
	LD	A,(FontColor)
	AND	0xF0					; Foreground color on MSB
	LD	B,A						; Move it to B
	LD	A,(BackColor)			; Background color on LSC
	OR	B
	LD	(ColorTable+02),A		; Color table 2 -> Foreground and Background
	LD	A,(FontColor)
	LD	(ColorTable+03),A		; Color table 3 -> Foreground and Foreground
	;OPJ - Sprite Cursor added
	JP	V9938_CursorColor


V9938_CopyBlockYUp:
;
; A <- HowManyRows
; B <- DestinationRow
; C <- SourceRow
;
; Not really proud of this code, but gonna do for this moment
; There is a possibility of two splits on YMMM of large blocks, one for destination and other
; for source. When both occur at the same time, YMMM code is not handling it properly. And it
; might take a while until I figure out a sane way to do this, so, for the moment, we do it
; every line, as this guarantees that only one of them will cross boundaries, not beautiful
; but it works
	PUSH DE						; Save it, we are gonna mess w/ it and not sure if other code depends on it
	DEC	A						; As it is up, we need to adjust source and dest to figure out the last of each one
	LD	D,A						; Save as we are going to re-use it
	ADD	A,B						; A now has the last destination row
	LD	B,A						; and save it back to B
	LD	A,D						; Back with the value in A
	ADD	A,C						; A now has the last source row
	LD	C,A						; and save it back to C
	LD	A,D						; Back wit how many rows - 1
	INC	A						; How many rows again
	POP	DE						; Restore DE
V9938_CopyBlockYUp_1:
	PUSH	AF					; Save registers, those are going to be messed in CopyBlockYUpLine
	PUSH	BC
	LD	A,1					; We are going to do line per line
	CALL	V9938_CopyBlockYUpLine
	POP	BC						; Restore Dest and Source
	POP	AF						; Restore how many lines
	DEC	A						; Decrease how many lines
	RET	Z						; If no more lines, done
	DEC	B						; Otherwise, next destination line
	DEC	C						; Next source line to copy
	JP	V9938_CopyBlockYUp_1	; Wash, Rinse and repeat.... :-P


V9938_CopyBlockYUpLine:
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	(YMMM_CMD_NYL),A		; Will copy a rectangle with A*8 pixels on the Y axis
	LD	D,A						; Save NYL  in D
	DEC	D						; Adjust for our math
	LD	A,C						; Get Source Row
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	HL,(VDP_23)			; Get current vertical offset
	ADD	A,L						; Add it
	ADD	A,D						; And add how many lines, as we are going from bottom to top, start at the last line
	LD	(YMMM_CMD_SYL),A		; Source Y coordinate
	LD	H,A						; Save SYL in H
	LD	A,B
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,L						; Add current vertical offset to it
	ADD	A,D						; And add how many lines, as we are going from bottom to top, start at the last line
	LD	(YMMM_CMD_DYL),A		; To
	; There are three possible splits here:
	; 1st - SY - NY carry.... Then we have to split in two operations with different SY, DY and NY
	;		1st operation will be: SY and DY as is with NY being the NY - remainder after carry
	;		2nd operation will be: SY as 0, DY as DY - 1st NY and NY being the remainder after carry
	;
	; 2nd - DY - NY carry.... Then we have to split in two operations with different SY, DY and NY
	;		1st operation will be: SY and DY as is with NY being the NY - remainder after carry
	;		2nd operation will be: DY as 0, SY as SY - 1st NY and NY being the remainder after carry
	;
	; 3rd - 1st and 2nd at the same time.... Then we have to split in three operations with different SY, DY and NY
	;		First need to figure out which operation will overlap first, DY or NY
	;
	;		1st operation will be: SY and DY as is with NY being the NY - remainder after carry
	;		2nd operation will be: DY as 0, SY as SY - 1st NY and NY being the remainder after carry
	;
	; Need to test the 1st hypothesis
	LD	A,H						; Source Y coordinate in A
	SUB	A,D						; SY - NY
	JR	C,V9938_CopyBlockYUp_DO1; If Carry, this is split case 1,do it
	LD	A,(YMMM_CMD_DYL)		; DY
	SUB	A,D						; NY - DY
	; If Carry, this is split case 2,do it
	JR	C,V9938_CopyBlockYUp_DO2
	; Otherwise, it is a single operation so...
	LD	A,8
	LD	(YMMM_CMD_ARG),A		; Direction is Up
	LD	(YMMM_CMD_DXL),A		; And this is our X starting source point as well
	JP	DO_YMMM					; Do the single operation and YMMM will return for us
V9938_CopyBlockYUp_DO1:
	; Here we are, source - number of lines will overflow
	; Whatever is in A now is how much SY we need to do the second time
	LD	B,A						; Save this in B for now
	LD	A,D						; NYL in A
	SUB	A,B						; This is our first NYL
	LD	(YMMM_CMD_NYL),A		; First rectangle of split operation
	LD	A,B						; Restore the overflow  of lines
	LD	(YMMM_CMD_NYL2),A		; Second rectangle of split operation
	LD	A,8					; Direction is Up
	LD	(YMMM_CMD_ARG),A
	LD	(YMMM_CMD_DXL),A		; And this is our X starting source point as well
	CALL	DO_YMMM				; Do the first operation
	XOR	A
	LD	(YMMM_CMD_SYL),A		; Second round Source
	LD	A,(YMMM_CMD_NYL)		; of lines of 1st operation in A
	LD	B,A						; Save it in B
	LD	A,(YMMM_CMD_DYL)		; line of 1st operation destination
	SUB	A,B						; Subtract first SYL to it
	LD	(YMMM_CMD_DYL),A		; line of 2nd operation destination
	LD	A,(YMMM_CMD_NYL2)		; Second rectangle of split operation in A
	OR	A						; Check if zero
	RET	Z						; If it is, dones
	LD	(YMMM_CMD_NYL),A		; Save it for next YMMM, so it will be done with DY as 0, SY added w/  of lines already copied and NYL with the remaining lines to copy
	JP	DO_YMMM					; Do the second operation and then done, so return from there
V9938_CopyBlockYUp_DO2:
	; Here we are, destination - number of lines will overflow
	; Whatever is in A now is how much NY we need to do the second time
	LD	B,A						; Save this in B for now
	LD	A,D						; NYL in A
	SUB	A,B						; This is our first NYL
	LD	(YMMM_CMD_NYL),A		; First rectangle of split operation
	LD	A,B						; Restore the overflow  of lines
	LD	(YMMM_CMD_NYL2),A		; Second rectangle of split operation
	LD	A,8					; Direction is Up
	LD	(YMMM_CMD_ARG),A
	LD	(YMMM_CMD_DXL),A		; And this is our X starting source point as well
	CALL	DO_YMMM				; Do the first operation
	XOR	A
	LD	(YMMM_CMD_DYL),A		; Second round To
	LD	A,(YMMM_CMD_NYL)		; of lines of 1st operation in A
	LD	B,A						; Save it in B
	LD	A,(YMMM_CMD_SYL)		; of starting source lines of 1st operation in A
	SUB	A,B						; Subtract both
	LD	(YMMM_CMD_SYL),A		; of starting source lines of 2nd operation
	LD	A,(YMMM_CMD_NYL2)		; Second rectangle of split operation in A
	OR	A						; Check if zero
	RET	Z						; If it is, dones
	LD	(YMMM_CMD_NYL),A		; Save it for next YMMM, so it will be done with DY as 0, SY added w/  of lines already copied and NYL with the remaining lines to copy
	JP	DO_YMMM					; Do the second operation and then done, so return from there


V9938_CopyBlockYDown:
;
; A <- HowManyRows
; B <- SourceRow
; C <- DestinationRow
;
;
; Not really proud of this code, but gonna do for this moment
; There is a possibility of two splits on YMMM of large blocks, one for destination and other
; for source. When both occur at the same time, YMMM code is not handling it properly. And it
; might take a while until I figure out a sane way to do this, so, for the moment, we do it
; every line, as this guarantees that only one of them will cross boundaries, not beautiful
; but it works
	PUSH	AF					; Save registers, those are going to be messed in CopyBlockYUpLine
	PUSH	BC
	LD	A,1					; We are going to do line per line
	CALL	V9938_CopyBlockYDownLine
	POP	BC						; Restore Dest and Source
	POP	AF						; Restore how many lines
	DEC	A						; Decrease how many lines
	RET	Z						; If no more lines, done
	INC	B						; Otherwise, next destination line
	INC	C						; Next source line to copy
	JP	V9938_CopyBlockYDown	; Wash, Rinse and repeat.... :-P


V9938_CopyBlockYDownLine:
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	(YMMM_CMD_NYL),A		; Will copy a rectangle with A*8 pixels on the Y axis
	LD	D,A						; Save NYL  in D
	LD	A,B
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	HL,(VDP_23)			; Get current vertical offset
	ADD	A,L						; Add it
	LD	(YMMM_CMD_SYL),A		; Source Y coordinate
	LD	E,A						; Save SYL in E
	LD	A,C
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,L						; Add current vertical offset to it
	LD	(YMMM_CMD_DYL),A		; To
	; There are two possible splits here:
	; 1st - SY + NY carry.... Then we have to split in two operations with different SY, DY and NY
	;		1st operation will be: SY and DY as is with NY being the NY - remainder after carry
	;		2nd operation will be: SY as 0, DY as DY + 1st NY and NY being the remainder after carry
	;
	; 2nd - DY + NY carry.... Then we have to split in two operations with different SY, DY and NY
	;		1st operation will be: SY and DY as is with NY being the NY - remainder after carry
	;		2nd operation will be: DY as 0, SY as SY + 1st NY and NY being the remainder after carry
	; Need to test the 1s hypothesis
	LD	A,E						; Source Y coordinate in A
	ADD	A,D						; SY + NY
	JR	C,V9938_CopyBlockYDown_DO1	; If Carry, this is split case 1,do it
	LD	A,(YMMM_CMD_DYL)		; DY
	ADD	A,D						; NY + DY
	JR	C,V9938_CopyBlockYDown_DO2	; If Carry, this is split case 2,do it
	; Otherwise, it is a single operation so...
	XOR	A
	LD	(YMMM_CMD_ARG),A		; Direction is down
	LD	A,8					; Skip the first 16 pixels as those do not matter (our border)
	LD	(YMMM_CMD_DXL),A		; And this is our X starting source point
	JP	DO_YMMM					; Do the single operation and YMMM will return for us
V9938_CopyBlockYDown_DO1:
	; Here we are, source + number of lines will overflow
	; Whatever is in A now is how much SY we need to do the second time
	LD	B,A						; Save this in B for now
	LD	A,D						; NYL in A
	SUB	A,B						; This is our first NYL
	LD	(YMMM_CMD_NYL),A		; First rectangle of split operation
	LD	A,B						; Restore the overflow  of lines
	LD	(YMMM_CMD_NYL2),A		; Second rectangle of split operation
	XOR	A
	LD	(YMMM_CMD_ARG),A		; Direction is down
	LD	A,8					; Skip the first 16 pixels as those do not matter (our border)
	LD	(YMMM_CMD_DXL),A		; And this is our X starting source point
	CALL	DO_YMMM				; Do the first operation
	XOR	A
	LD	(YMMM_CMD_SYL),A		; Second round Source
	LD	A,(YMMM_CMD_NYL)		; of lines of 1st operation in A
	LD	B,A						; Save it in B
	LD	A,(YMMM_CMD_DYL)		; line of 1st operation destination
	ADD	A,B						; Add first SYL to it
	LD	(YMMM_CMD_DYL),A		; line of 2nd operation destination
	LD	A,(YMMM_CMD_NYL2)		; Second rectangle of split operation in A
	OR	A						; Check if zero
	RET	Z						; If it is, dones
	LD	(YMMM_CMD_NYL),A		; Save it for next YMMM, so it will be done with DY as 0, SY added w/  of lines already copied and NYL with the remaining lines to copy
	JP	DO_YMMM					; Do the second operation and then done, so return from there
V9938_CopyBlockYDown_DO2:
	; Here we are, destination + number of lines will overflow
	; Whatever is in A now is how much NY we need to do the second time
	LD	B,A						; Save this in B for now
	LD	A,D						; NYL in A
	SUB	A,B						; This is our first NYL
	LD	(YMMM_CMD_NYL),A		; First rectangle of split operation
	LD	A,B						; Restore the overflow  of lines
	LD	(YMMM_CMD_NYL2),A		; Second rectangle of split operation
	XOR	A
	LD	(YMMM_CMD_ARG),A		; Direction is down
	LD	A,8					; Skip the first 16 pixels as those do not matter (our border)
	LD	(YMMM_CMD_DXL),A		; And this is our X starting source point
	CALL	DO_YMMM				; Do the first operation
	XOR	A
	LD	(YMMM_CMD_DYL),A		; Second round To
	LD	A,(YMMM_CMD_NYL)		; of lines of 1st operation in A
	LD	B,A						; Save it in B
	LD	A,(YMMM_CMD_SYL)		; of starting source lines of 1st operation in A
	ADD	A,B						; Add both
	LD	(YMMM_CMD_SYL),A		; of starting source lines of 2nd operation
	LD	A,(YMMM_CMD_NYL2)		; Second rectangle of split operation in A
	OR	A						; Check if zero
	RET	Z						; If it is, dones
	LD	(YMMM_CMD_NYL),A		; Save it for next YMMM, so it will be done with DY as 0, SY added w/  of lines already copied and NYL with the remaining lines to copy
	JP	DO_YMMM					; Do the second operation and then done, so return from there


V9938_WaitCmd:
	LD	A,0x02
	DI
	OUT	(0x99),A
	LD	A,0x80+15
	OUT	(0x99),A
	IN	A,(0x99)
	RRA
	LD	A,0x00
	OUT	(0x99),A
	LD	A,0x80+15
	OUT	(0x99),A
	EI
	RET	NC
	JR	V9938_WaitCmd


DO_HMMC:
	EXX
	DI
	LD	A,0x24					; Register 36 as value for...
	OUT	(0x99),A
	LD	A,0x91					; Register 17 (indirect register access auto increment)
	OUT	(0x99),A
	EI
	LD	HL,HMMC_CMD				; The HMMC buffer
	LD	C,0x9B					; And port for indirect access
	CALL	V9938_WaitCmd				; Wait if any command is pending
	OUTI						; And now send the buffer
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	DI
	LD	A,0xAC
	OUT	(0x99),A
	LD	A,0x91
	OUT	(0x99),A				; Write to register 17 disabling auto incrementing and pointing to 44 (color register), next pixels are sent through R44
	EI
	EXX
	RET


DO_HMMV:
	CALL	V9938_WaitCmd		; Wait if any command is pending
	DI
	LD	A,0x24					; Register 36 as value for...
	OUT	(0x99),A
	LD	A,0x91					; Register 17 (indirect register access auto increment)
	OUT	(0x99),A
	LD	HL,HMMV_CMD			; The HMMV buffer
	LD	C,0x9B					; And port for indirect access
	LD	A,(HL)					; LD DXL in A
	INC	HL
	INC	HL						; HL pointing to DYL
	ADD	0x08					; Add 8 to DXL (A) - Border of 16 pixels
	ADD	A,A						; Multiply by 2
	OUT	(C),A					; And send DXL to 36
	LD	A,0x00					; DXH could be 0
	JR	NC,DO_HMMV_DXH			; If no carry, it is 0
	INC	A						; Otherwise it is 1
DO_HMMV_DXH:
	OUT	(C),A		; And send DXH to 37
	LD	A,(HL)					; Load DYL in A
	INC	HL
	INC	HL						; HL pointing @ NXL
	LD	B,A						; Copy DYL to B
	LD	A,(HMMV_CMD_NYL2)		; It's the second step?
	OR	A
	LD	A,(VDP_23)				; Get current vertical offset
	JR	Z,DO_HMMV_FIRST
	XOR	A
DO_HMMV_FIRST:
	ADD	A,B						; Add our DYL to it
	OUT	(C),A					; Send it to 38
	LD	B,A						; Copy adjusted DYL to B
	LD	A,(HMMV_CMD_NYL)		; NYL
	ADD	A,B						; Ok, now let's check if there is an overflow
	LD	(HMMV_CMD_NYL2),A		; Save just in case it is a split operation :D
	JR	NC,DO_HMMV_ONESTEP		; If not carry, last line is within the page constraints so it is a single step
	JR	Z,DO_HMMV_ONESTEP		; If zero, no second step
	LD	B,A						; This is the remainder
	LD	A,(HMMV_CMD_NYL)		; NYL
	SUB	A,B						; First step length
	LD	(HMMV_CMD_NYL),A		; New NYL
	;Now finish first step here, and follow-up with a second step
	XOR	A						; DYH always 0
	OUT	(C),A					; Send it
	OUTI						; And now send the rest of buffer
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	EI
	; Ok, so now for the second step
	XOR	A						; So DY went up to 255, it will now start at 0
	LD	(HMMV_CMD_DYL),A		; New DYL
	LD	A,(HMMV_CMD_NYL2)		; The remaining lenght at Y
	LD	(HMMV_CMD_NYL),A		; Now at NYL
	JP	DO_HMMV					; And go execute the second step, that won't overflow and will exit cleanly :)
DO_HMMV_ONESTEP:
	XOR	A						; DYH always 0
	OUT	(C),A					; Send it
	OUTI						; And now send the rest of buffer
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	EI
	LD	(HMMV_CMD_NYL2),A		; Clear NYL2
	RET


; This function is safe for a single line only, if spanning over more than one line, it might potentially miss data
DO_HMMM:
	DI
	LD	A,0x20					; Register 32 as value for...
	OUT	(0x99),A
	LD	A,0x91					; Register 17 (indirect register access auto increment)
	OUT	(0x99),A
	EI
	LD	HL,HMMM_CMD			; The HMMC buffer
	LD	C,0x9B					; And port for indirect access
	CALL	V9938_WaitCmd		; Wait if any command is pending
	OUTI						; And now send the buffer
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	RET


DO_YMMM:
	DI
	LD	A,0x22					; Register 34 as value for...
	OUT	(0x99),A
	LD	A,0x91					; Register 17 (indirect register access auto increment)
	OUT	(0x99),A
	EI
	LD	HL,YMMM_CMD			; The YMMM buffer
	LD	C,0x9B					; And port for indirect access
	CALL	V9938_WaitCmd		; Wait if any command is pending
	OUTI						; And now send the buffer
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	OUTI
	RET


;
;	DATA Portion
;
;	This is where our data is defined
;

OrgAddress:	DW	0x0000

EndAddress:	DW	0x0000

SavedCol:	DB	0x00

SavedRow:	DB	0x00

CursorCol:	DB	0x00

CursorRow:	DB	0x00

CursorOn:	DB	0x00

CursorUpdt:	DB	0x00

BackColor:	DB	0x00

BorderColor:DB	0x00

ClearColor:	DB	0x00

ForeColor:	DB	0x07

FontColor:	DB	0x07

HiLighted:	DB	0x00

Reversed:	DB	0x00

Concealed:	DB	0x00

LastChar:	DB	0x65

ANSI_M:		DB	0x00			; If ESC was the previous character will hold ESC, if processing ESC command, will hold [, otherwise 00
ANSI_P:		DW	ANSI_S			; Point the next free position in buffer
ANSI_S:		DS	0x10			; Buffer to hold the ANSI command or data received to print
ANSI_CB:	DB	0x00			; Wheter we have a callback for cursor position requests or not

Parameters_PST:	DB	"0123456789ABCDEF0123456789ABCDEF"
Parameters_TRM:	DB	0x00
Parameters_PCT:	DB	0x00
Parameters_PPT:	DW	Parameters_PRM
Parameters_PRM:	DB	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

ColorTable:	DB	0x00,0x0F,0xF0,0xFF

SPRITEPOS_X:	DB 0x00

HMMC_CMD:
HMMC_CMD_DXL:	DB	0x10
HMMC_CMD_DXH:	DB	0x00
HMMC_CMD_DYL:	DB	0x00
HMMC_CMD_DYH:	DB	0x00
HMMC_CMD_NXL:	DB	0x06
HMMC_CMD_NXH:	DB	0x00
HMMC_CMD_NYL:	DB	0x08
HMMC_CMD_NYH:	DB	0x00
HMMC_CMD_CLR:	DB	0x00
HMMC_CMD_ARG:	DB	0x00
HMMC_CMD_CMD:	DB	0xF0



HMMV_CMD:
HMMV_CMD_DXL:	DB	0x00
HMMV_CMD_DXH:	DB	0x00
HMMV_CMD_DYL:	DB	0x00
HMMV_CMD_DYH:	DB	0x00
HMMV_CMD_NXL:	DB	0x00
HMMV_CMD_NXH:	DB	0x00
HMMV_CMD_NYL:	DB	0x00
HMMV_CMD_NYH:	DB	0x00
HMMV_CMD_CLR:	DB	0x00
HMMV_CMD_ARG:	DB	0x00
HMMV_CMD_CMD:	DB	0xC0
HMMV_CMD_NYL2:	DB 0x00

HMMM_CMD:
HMMM_CMD_SXL:	DB	0x00
HMMM_CMD_SXH:	DB	0x00
HMMM_CMD_SYL:	DB	0x00
HMMM_CMD_SYH:	DB	0x00
HMMM_CMD_DXL:	DB	0x00
HMMM_CMD_DXH:	DB	0x00
HMMM_CMD_DYL:	DB	0x00
HMMM_CMD_DYH:	DB	0x00
HMMM_CMD_NXL:	DB	0x00
HMMM_CMD_NXH:	DB	0x00
HMMM_CMD_NYL:	DB	0x00
HMMM_CMD_NYH:	DB	0x00
HMMM_CMD_CLR:	DB	0x00		; HMMM doesn't use it, but it is faster to send 0 here and not stop sending incremental registers, two outs total, vs 3 outs to skip color and write inc on ARG
HMMM_CMD_ARG:	DB	0x00
HMMM_CMD_CMD:	DB	0xD0

YMMM_CMD:
YMMM_CMD_SYL:	DB	0x00		; R34
YMMM_CMD_SYH:	DB	0x00		; R35
YMMM_CMD_DXL:	DB	0x00		; R36
YMMM_CMD_DXH:	DB	0x00		; R37
YMMM_CMD_DYL:	DB	0x00		; R38
YMMM_CMD_DYH:	DB	0x00		; R39
YMMM_CMD_NXL:	DB	0x00		; R40, YMMM doesn't use but it is faster to send 0 here
YMMM_CMD_NXH:	DB	0x00		; R41, YMMM doesn't use but it is faster to send 0 here
YMMM_CMD_NYL:	DB	0x00		; R42
YMMM_CMD_NYH:	DB	0x00		; R43
YMMM_CMD_CLR:	DB	0x00		; R44, YMMM doesn't use but it is faster to send 0 here
YMMM_CMD_ARG:	DB	0x00		; R45
YMMM_CMD_CMD:	DB	0xE0		; R46
YMMM_CMD_NYL2:	DB	0x00		; R42 for split operation second step

ANSI_PAL:
	DB	0x00,0x00,0x50,0x00,0x00,0x05,0x50,0x02,0x05,0x00,0x55,0x00,0x05,0x05,0x55,0x05
	DB	0x22,0x02,0x72,0x02,0x22,0x07,0x72,0x07,0x27,0x02,0x77,0x02,0x27,0x07,0x77,0x07

SPRITE_TABLE:
	DB	0x00,0x00,0x00,0x00	; Cursor is first, start at line 0, colum 0, uses pattern 0 reserved byte whatever
	DB	0xD8,0x00,0x01,0x00	; Next line D8 to make invisible, use pattern 1 (all 0)

PATTERN_CURSOR:
	DB	0x00,0x00,0x00,0x00,0x00,0xE0,0xE0,0x00

PATTERN_INVISIBLE:
	DB	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

SPRITE_COLORS:
	DB	0x20,0x20,0x20,0x20,0x20,0x27,0x27,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20
	DB	0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20

FontData:
	DB 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	;000 / 0x00 - NUL - Not printable
	DB 0x3C,0x40,0xA4,0x80,0xA4,0x98,0x40,0x3C	;001 / 0x01 - Smile face
	DB 0x78,0xFC,0xB4,0xFC,0xB4,0xCC,0xFC,0x00 ;002 / 0x02 - Dark Smile Face
	DB 0x6C,0xFC,0xFC,0xFC,0x7C,0x38,0x10,0x00 ;003 / 0x03 - Heart
	DB 0x10,0x38,0x7C,0xFC,0x7C,0x38,0x10,0x00 ;004 / 0x04 - Diamond
	DB 0x10,0x38,0x54,0xFC,0x54,0x10,0x38,0x00 ;005 / 0x05 - Club
	DB 0x10,0x38,0x7C,0xFC,0xFC,0x10,0x38,0x00 ;006 / 0x06 - Spade
	DB 0x00,0x00,0x00,0x30,0x30,0x00,0x00,0x00 ;007 / 0x07 - Bell, not printable
	DB 0xFC,0xFC,0xFC,0xE4,0xE4,0xFC,0xFC,0xFC ;008 / 0x08 - Backspace, not printable
	DB 0x38,0x44,0x80,0x80,0x80,0x44,0x38,0x00 ;009 / 0x09 - Tab, not printable
	DB 0xC4,0xB8,0x7C,0x7C,0x7C,0xB8,0xC4,0xFC ;010 / 0x0A - Line Feed, not printable
	DB 0x38,0x08,0x28,0x70,0x88,0x88,0x88,0x70 ;011 / 0x0B - Male Sign
	DB 0x38,0x44,0x44,0x44,0x38,0x10,0x7C,0x10 ;012 / 0x0C - Form Feed, not printable, clear screen
	DB 0x30,0x28,0x24,0x24,0x28,0x20,0xE0,0xC0 ;013 / 0x0D - Carriage Return, not printable
	DB 0x3C,0x24,0x3C,0x24,0x24,0xE4,0xDC,0x18 ;014 / 0x0E - Beamed note
	DB 0x10,0x54,0x38,0xEC,0x38,0x54,0x10,0x00 ;015 / 0x0F - Sun Ray
	DB 0x40,0x60,0x70,0x78,0x70,0x60,0x40,0x00 ;016 / 0x10 - Arrow tip to right
	DB 0x10,0x30,0x70,0xF0,0x70,0x30,0x10,0x00 ;017 / 0x11 - Arrow tip to left
	DB 0x20,0x70,0xA8,0x20,0x20,0xA8,0x70,0x20 ;018 / 0x12 - UpDown arrow
	DB 0x48,0x48,0x48,0x48,0x00,0x48,0x48,0x00 ;019 / 0x13 - Double Exclamation Mark
	DB 0x7C,0xE1,0xE1,0x28,0x28,0x28,0x28,0x00 ;020 / 0x14 - Pilcrow
	DB 0x18,0x24,0x30,0x48,0x48,0x30,0x90,0x60 ;021 / 0x15 - Section Sign
	DB 0x00,0x00,0x00,0xFC,0xFC,0x00,0x00,0x00 ;022 / 0x16 - Black Rectangle
	DB 0x20,0x70,0xA8,0x20,0x20,0xA8,0x70,0xFC ;023 / 0x17 - UpDown arrow with base
	DB 0x20,0x70,0xA8,0x20,0x20,0x20,0x20,0x00 ;024 / 0x18 - Arrow Up
	DB 0x20,0x20,0x20,0x20,0xA8,0x70,0x20,0x00 ;025 / 0x19 - Arrow Down
	DB 0x00,0xC0,0x30,0xF8,0x30,0xC0,0x00,0x00 ;026 / 0x1A - Arrow Right
	DB 0x00,0x18,0x60,0xF8,0x60,0x18,0x00,0x00 ;027 / 0x1B - ESC, not printables
	DB 0x00,0x40,0x40,0x40,0x40,0x7C,0x00,0x00 ;028 / 0x1C - Right Angle
	DB 0x00,0x00,0x20,0x48,0xFC,0x48,0x10,0x00 ;029 / 0x1D - Left-Right Arrow
	DB 0x20,0x20,0x70,0x70,0xF8,0xF8,0x00,0x00 ;030 / 0x1E - Arrow tip up
	DB 0xF8,0xF8,0x70,0x70,0x20,0x20,0x00,0x00 ;031 / 0x1F - Arrow tip down
	DB 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 ;032 / 0x20 - Space
	DB 0x20,0x20,0x20,0x20,0x00,0x00,0x20,0x00 ;033 / 0x21 -
	DB 0x50,0x50,0x50,0x00,0x00,0x00,0x00,0x00 ;034 / 0x22 -
	DB 0x50,0x50,0xF8,0x50,0xF8,0x50,0x50,0x00 ;035 / 0x23 -
	DB 0x20,0x78,0xA0,0x70,0x28,0xF0,0x20,0x00 ;036 / 0x24 -
	DB 0xC0,0xC8,0x10,0x20,0x40,0x98,0x18,0x00 ;037 / 0x25 -
	DB 0x40,0xA0,0x40,0xA8,0x90,0x98,0x60,0x00 ;038 / 0x26 -
	DB 0x10,0x20,0x40,0x00,0x00,0x00,0x00,0x00 ;039 / 0x27 -
	DB 0x10,0x20,0x40,0x40,0x40,0x20,0x10,0x00 ;040 / 0x28 -
	DB 0x40,0x20,0x10,0x10,0x10,0x20,0x40,0x00 ;041 / 0x29 -
	DB 0x20,0xA8,0x70,0x20,0x70,0xA8,0x20,0x00 ;042 / 0x2A -
	DB 0x00,0x20,0x20,0xF8,0x20,0x20,0x00,0x00 ;043 / 0x2B -
	DB 0x00,0x00,0x00,0x00,0x00,0x20,0x20,0x40 ;044 / 0x2C -
	DB 0x00,0x00,0x00,0x78,0x00,0x00,0x00,0x00 ;045 / 0x2D -
	DB 0x00,0x00,0x00,0x00,0x00,0x60,0x60,0x00 ;046 / 0x2E -
	DB 0x00,0x00,0x08,0x10,0x20,0x40,0x80,0x00 ;047 / 0x2F -
	DB 0x70,0x88,0x98,0xA8,0xC8,0x88,0x70,0x00 ;048 / 0x30 -
	DB 0x20,0x60,0xA0,0x20,0x20,0x20,0xF8,0x00 ;049 / 0x31 -
	DB 0x70,0x88,0x08,0x10,0x60,0x80,0xF8,0x00 ;050 / 0x32 -
	DB 0x70,0x88,0x08,0x30,0x08,0x88,0x70,0x00 ;051 / 0x33 -
	DB 0x10,0x30,0x50,0x90,0xF8,0x10,0x10,0x00 ;052 / 0x34 -
	DB 0xF8,0x80,0xE0,0x10,0x08,0x10,0xE0,0x00 ;053 / 0x35 -
	DB 0x30,0x40,0x80,0xF0,0x88,0x88,0x70,0x00 ;054 / 0x36 -
	DB 0xF8,0x88,0x10,0x20,0x20,0x20,0x20,0x00 ;055 / 0x37 -
	DB 0x70,0x88,0x88,0x70,0x88,0x88,0x70,0x00 ;056 / 0x38 -
	DB 0x70,0x88,0x88,0x78,0x08,0x10,0x60,0x00 ;057 / 0x39 -
	DB 0x00,0x00,0x20,0x00,0x00,0x20,0x00,0x00 ;058 / 0x3A -
	DB 0x00,0x00,0x20,0x00,0x00,0x20,0x20,0x40 ;059 / 0x3B -
	DB 0x18,0x30,0x60,0xC0,0x60,0x30,0x18,0x00 ;060 / 0x3C -
	DB 0x00,0x00,0xF8,0x00,0xF8,0x00,0x00,0x00 ;061 / 0x3D -
	DB 0xC0,0x60,0x30,0x18,0x30,0x60,0xC0,0x00 ;062 / 0x3E -
	DB 0x70,0x88,0x08,0x10,0x20,0x00,0x20,0x00 ;063 / 0x3F -
	DB 0x70,0x88,0x08,0x68,0xA8,0xA8,0x70,0x00 ;064 / 0x40 -
	DB 0x20,0x50,0x88,0x88,0xF8,0x88,0x88,0x00 ;065 / 0x41 -
	DB 0xF0,0x48,0x48,0x70,0x48,0x48,0xF0,0x00 ;066 / 0x42 -
	DB 0x30,0x48,0x80,0x80,0x80,0x48,0x30,0x00 ;067 / 0x43 -
	DB 0xE0,0x50,0x48,0x48,0x48,0x50,0xE0,0x00 ;068 / 0x44 -
	DB 0xF8,0x80,0x80,0xF0,0x80,0x80,0xF8,0x00 ;069 / 0x45 -
	DB 0xF8,0x80,0x80,0xF0,0x80,0x80,0x80,0x00 ;070 / 0x46 -
	DB 0x70,0x88,0x80,0xB8,0x88,0x88,0x70,0x00 ;071 / 0x47 -
	DB 0x88,0x88,0x88,0xF8,0x88,0x88,0x88,0x00 ;072 / 0x48 -
	DB 0x70,0x20,0x20,0x20,0x20,0x20,0x70,0x00 ;073 / 0x49 -
	DB 0x38,0x10,0x10,0x10,0x90,0x90,0x60,0x00 ;074 / 0x4A -
	DB 0x88,0x90,0xA0,0xC0,0xA0,0x90,0x88,0x00 ;075 / 0x4B -
	DB 0x80,0x80,0x80,0x80,0x80,0x80,0xF8,0x00 ;076 / 0x4C -
	DB 0x88,0xD8,0xA8,0xA8,0x88,0x88,0x88,0x00 ;077 / 0x4D -
	DB 0x88,0xC8,0xC8,0xA8,0x98,0x98,0x88,0x00 ;078 / 0x4E -
	DB 0x70,0x88,0x88,0x88,0x88,0x88,0x70,0x00 ;079 / 0x4F -
	DB 0xF0,0x88,0x88,0xF0,0x80,0x80,0x80,0x00 ;080 / 0x50 -
	DB 0x70,0x88,0x88,0x88,0xA8,0x90,0x68,0x00 ;081 / 0x51 -
	DB 0xF0,0x88,0x88,0xF0,0xA0,0x90,0x88,0x00 ;082 / 0x52 -
	DB 0x70,0x88,0x80,0x70,0x08,0x88,0x70,0x00 ;083 / 0x53 -
	DB 0xF8,0x20,0x20,0x20,0x20,0x20,0x20,0x00 ;084 / 0x54 -
	DB 0x88,0x88,0x88,0x88,0x88,0x88,0x70,0x00 ;085 / 0x55 -
	DB 0x88,0x88,0x88,0x88,0x50,0x50,0x20,0x00 ;086 / 0x56 -
	DB 0x88,0x88,0x88,0xA8,0xA8,0xD8,0x88,0x00 ;087 / 0x57 -
	DB 0x88,0x88,0x50,0x20,0x50,0x88,0x88,0x00 ;088 / 0x58 -
	DB 0x88,0x88,0x88,0x70,0x20,0x20,0x20,0x00 ;089 / 0x59 -
	DB 0xF8,0x08,0x10,0x20,0x40,0x80,0xF8,0x00 ;090 / 0x5A -
	DB 0x70,0x40,0x40,0x40,0x40,0x40,0x70,0x00 ;091 / 0x5B -
	DB 0x00,0x00,0x80,0x40,0x20,0x10,0x08,0x00 ;092 / 0x5C -
	DB 0x70,0x10,0x10,0x10,0x10,0x10,0x70,0x00 ;093 / 0x5D -
	DB 0x20,0x50,0x88,0x00,0x00,0x00,0x00,0x00 ;094 / 0x5E -
	DB 0x00,0x00,0x00,0x00,0x00,0x00,0xF8,0x00 ;095 / 0x5F -
	DB 0x40,0x20,0x10,0x00,0x00,0x00,0x00,0x00 ;096 / 0x60 -
	DB 0x00,0x00,0x70,0x08,0x78,0x88,0x78,0x00 ;097 / 0x61 -
	DB 0x80,0x80,0xB0,0xC8,0x88,0xC8,0xB0,0x00 ;098 / 0x62 -
	DB 0x00,0x00,0x70,0x88,0x80,0x88,0x70,0x00 ;099 / 0x63 -
	DB 0x08,0x08,0x68,0x98,0x88,0x98,0x68,0x00 ;100 / 0x64 -
	DB 0x00,0x00,0x70,0x88,0xF8,0x80,0x70,0x00 ;101 / 0x65 -
	DB 0x10,0x28,0x20,0xF8,0x20,0x20,0x20,0x00 ;102 / 0x66 -
	DB 0x00,0x00,0x68,0x98,0x98,0x68,0x08,0x70 ;103 / 0x67 -
	DB 0x80,0x80,0xF0,0x88,0x88,0x88,0x88,0x00 ;104 / 0x68 -
	DB 0x20,0x00,0x60,0x20,0x20,0x20,0x70,0x00 ;105 / 0x69 -
	DB 0x10,0x00,0x30,0x10,0x10,0x10,0x90,0x60 ;106 / 0x6A -
	DB 0x40,0x40,0x48,0x50,0x60,0x50,0x48,0x00 ;107 / 0x6B -
	DB 0x60,0x20,0x20,0x20,0x20,0x20,0x70,0x00 ;108 / 0x6C -
	DB 0x00,0x00,0xD0,0xA8,0xA8,0xA8,0xA8,0x00 ;109 / 0x6D -
	DB 0x00,0x00,0xB0,0xC8,0x88,0x88,0x88,0x00 ;110 / 0x6E -
	DB 0x00,0x00,0x70,0x88,0x88,0x88,0x70,0x00 ;111 / 0x6F -
	DB 0x00,0x00,0xB0,0xC8,0xC8,0xB0,0x80,0x80 ;112 / 0x70 -
	DB 0x00,0x00,0x68,0x98,0x98,0x68,0x08,0x08 ;113 / 0x71 -
	DB 0x00,0x00,0xB0,0xC8,0x80,0x80,0x80,0x00 ;114 / 0x72 -
	DB 0x00,0x00,0x78,0x80,0xF0,0x08,0xF0,0x00 ;115 / 0x73 -
	DB 0x40,0x40,0xF0,0x40,0x40,0x48,0x30,0x00 ;116 / 0x74 -
	DB 0x00,0x00,0x90,0x90,0x90,0x90,0x68,0x00 ;117 / 0x75 -
	DB 0x00,0x00,0x88,0x88,0x88,0x50,0x20,0x00 ;118 / 0x76 -
	DB 0x00,0x00,0x88,0xA8,0xA8,0xA8,0x50,0x00 ;119 / 0x77 -
	DB 0x00,0x00,0x88,0x50,0x20,0x50,0x88,0x00 ;120 / 0x78 -
	DB 0x00,0x00,0x88,0x88,0x98,0x68,0x08,0x70 ;121 / 0x79 -
	DB 0x00,0x00,0xF8,0x10,0x20,0x40,0xF8,0x00 ;122 / 0x7A -
	DB 0x18,0x20,0x20,0x40,0x20,0x20,0x18,0x00 ;123 / 0x7B -
	DB 0x20,0x20,0x20,0x00,0x20,0x20,0x20,0x00 ;124 / 0x7C -
	DB 0xC0,0x20,0x20,0x10,0x20,0x20,0xC0,0x00 ;125 / 0x7D -
	DB 0x40,0xA8,0x10,0x00,0x00,0x00,0x00,0x00 ;126 / 0x7E -
	DB 0x00,0x20,0x50,0x88,0x88,0x88,0xF8,0x00 ;127 / 0x7F -
	DB 0x70,0x88,0x80,0x80,0x88,0x70,0x20,0x60 ;128 / 0x80 -
	DB 0x90,0x00,0x00,0x90,0x90,0x90,0x68,0x00 ;129 / 0x81 -
	DB 0x10,0x20,0x70,0x88,0xF8,0x80,0x70,0x00 ;130 / 0x82 -
	DB 0x20,0x50,0x70,0x08,0x78,0x88,0x78,0x00 ;131 / 0x83 -
	DB 0x48,0x00,0x70,0x08,0x78,0x88,0x78,0x00 ;132 / 0x84 -
	DB 0x20,0x10,0x70,0x08,0x78,0x88,0x78,0x00 ;133 / 0x85 -
	DB 0x20,0x00,0x70,0x08,0x78,0x88,0x78,0x00 ;134 / 0x86 -
	DB 0x00,0x70,0x80,0x80,0x80,0x70,0x10,0x60 ;135 / 0x87 -
	DB 0x20,0x50,0x70,0x88,0xF8,0x80,0x70,0x00 ;136 / 0x88 -
	DB 0x50,0x00,0x70,0x88,0xF8,0x80,0x70,0x00 ;137 / 0x89 -
	DB 0x20,0x10,0x70,0x88,0xF8,0x80,0x70,0x00 ;138 / 0x8A -
	DB 0x50,0x00,0x00,0x60,0x20,0x20,0x70,0x00 ;139 / 0x8B -
	DB 0x20,0x50,0x00,0x60,0x20,0x20,0x70,0x00 ;140 / 0x8C -
	DB 0x40,0x20,0x00,0x60,0x20,0x20,0x70,0x00 ;141 / 0x8D -
	DB 0x50,0x00,0x20,0x50,0x88,0xF8,0x88,0x00 ;142 / 0x8E -
	DB 0x20,0x00,0x20,0x50,0x88,0xF8,0x88,0x00 ;143 / 0x8F -
	DB 0x10,0x20,0xF8,0x80,0xF0,0x80,0xF8,0x00 ;144 / 0x90 -
	DB 0x00,0x00,0x6C,0x10,0x7C,0x90,0x6C,0x00 ;145 / 0x91 -
	DB 0x3C,0x50,0x90,0x9C,0xF0,0x90,0x9C,0x00 ;146 / 0x92 -
	DB 0x60,0x90,0x00,0x60,0x90,0x90,0x60,0x00 ;147 / 0x93 -
	DB 0x90,0x00,0x00,0x60,0x90,0x90,0x60,0x00 ;148 / 0x94 -
	DB 0x40,0x20,0x00,0x60,0x90,0x90,0x60,0x00 ;149 / 0x95 -
	DB 0x40,0xA0,0x00,0xA0,0xA0,0xA0,0x50,0x00 ;150 / 0x96 -
	DB 0x40,0x20,0x00,0xA0,0xA0,0xA0,0x50,0x00 ;151 / 0x97 -
	DB 0x90,0x00,0x90,0x90,0xB0,0x50,0x10,0xE0 ;152 / 0x98 -
	DB 0x50,0x00,0x70,0x88,0x88,0x88,0x70,0x00 ;153 / 0x99 -
	DB 0x50,0x00,0x88,0x88,0x88,0x88,0x70,0x00 ;154 / 0x9A -
	DB 0x20,0x20,0x78,0x80,0x80,0x78,0x20,0x20 ;155 / 0x9B -
	DB 0x18,0x24,0x20,0xF8,0x20,0xE0,0x5C,0x00 ;156 / 0x9C -
	DB 0x88,0x50,0x20,0xF8,0x20,0xF8,0x20,0x00 ;157 / 0x9D -
	DB 0xC0,0xA0,0xA0,0xC8,0x9C,0x88,0x88,0x8C ;158 / 0x9E -
	DB 0x18,0x20,0x20,0xF8,0x20,0x20,0x20,0x40 ;159 / 0x9F -
	DB 0x10,0x20,0x70,0x08,0x78,0x88,0x78,0x00 ;160 / 0xA0 -
	DB 0x10,0x20,0x00,0x60,0x20,0x20,0x70,0x00 ;161 / 0xA1 -
	DB 0x20,0x40,0x00,0x60,0x90,0x90,0x60,0x00 ;162 / 0xA2 -
	DB 0x20,0x40,0x00,0x90,0x90,0x90,0x68,0x00 ;163 / 0xA3 -
	DB 0x50,0xA0,0x00,0xA0,0xD0,0x90,0x90,0x00 ;164 / 0xA4 -
	DB 0x28,0x50,0x00,0xC8,0xA8,0x98,0x88,0x00 ;165 / 0xA5 -
	DB 0x00,0x70,0x08,0x78,0x88,0x78,0x00,0xF8 ;166 / 0xA6 -
	DB 0x00,0x60,0x90,0x90,0x90,0x60,0x00,0xF0 ;167 / 0xA7 -
	DB 0x20,0x00,0x20,0x40,0x80,0x88,0x70,0x00 ;168 / 0xA8 -
	DB 0x00,0x00,0x00,0xF8,0x80,0x80,0x00,0x00 ;169 / 0xA9 -
	DB 0x00,0x00,0x00,0xF8,0x08,0x08,0x00,0x00 ;170 / 0xAA -
	DB 0x84,0x88,0x90,0xA8,0x54,0x84,0x08,0x1C ;171 / 0xAB -
	DB 0x84,0x88,0x90,0xA8,0x58,0xA8,0x3C,0x08 ;172 / 0xAC -
	DB 0x20,0x00,0x00,0x20,0x20,0x20,0x20,0x00 ;173 / 0xAD -
	DB 0x00,0x00,0x24,0x48,0x90,0x48,0x24,0x00 ;174 / 0xAE -
	DB 0x00,0x00,0x90,0x48,0x24,0x48,0x90,0x00 ;175 / 0xAF -
	DB 0x90,0x48,0x24,0x90,0x48,0x24,0x90,0x48 ;176 / 0xB0 -
	DB 0xA8,0x54,0xA8,0x54,0xA8,0x54,0xA8,0x54 ;177 / 0xB1 -
	DB 0x6C,0xB4,0xD8,0x6C,0xB4,0xD8,0x6C,0xB4 ;178 / 0xB2 -
	DB 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20 ;179 / 0xB3 -
	DB 0x20,0x20,0x20,0xE0,0x20,0x20,0x20,0x20 ;180 / 0xB4 -
	DB 0x20,0x20,0xE0,0x20,0xE0,0x20,0x20,0x20 ;181 / 0xB5 -
	DB 0x50,0x50,0x50,0xD0,0x50,0x50,0x50,0x50 ;182 / 0xB6 -
	DB 0x00,0x00,0x00,0xF0,0x50,0x50,0x50,0x50 ;183 / 0xB7 -
	DB 0x00,0x00,0xE0,0x20,0xE0,0x20,0x20,0x20 ;184 / 0xB8 -
	DB 0x50,0x50,0xD0,0x10,0xD0,0x50,0x50,0x50 ;185 / 0xB9 -
	DB 0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50 ;186 / 0xBA -
	DB 0x00,0x00,0xF0,0x10,0xD0,0x50,0x50,0x50 ;187 / 0xBB -
	DB 0x50,0x50,0xD0,0x10,0xF0,0x00,0x00,0x00 ;188 / 0xBC -
	DB 0x50,0x50,0x50,0xF0,0x00,0x00,0x00,0x00 ;189 / 0xBD -
	DB 0x20,0x20,0xE0,0x20,0xE0,0x00,0x00,0x00 ;190 / 0xBE -
	DB 0x00,0x00,0x00,0xE0,0x20,0x20,0x20,0x20 ;191 / 0xBF -
	DB 0x20,0x20,0x20,0x3C,0x00,0x00,0x00,0x00 ;192 / 0xC0 -
	DB 0x20,0x20,0x20,0xFC,0x00,0x00,0x00,0x00 ;193 / 0xC1 -
	DB 0x00,0x00,0x00,0xFC,0x20,0x20,0x20,0x20 ;194 / 0xC2 -
	DB 0x20,0x20,0x20,0x3C,0x20,0x20,0x20,0x20 ;195 / 0xC3 -
	DB 0x00,0x00,0x00,0xFC,0x00,0x00,0x00,0x00 ;196 / 0xC4 -
	DB 0x20,0x20,0x20,0xFC,0x20,0x20,0x20,0x20 ;197 / 0xC5 -
	DB 0x20,0x20,0x3C,0x20,0x3C,0x20,0x20,0x20 ;198 / 0xC6 -
	DB 0x50,0x50,0x50,0x5C,0x50,0x50,0x50,0x50 ;199 / 0xC7 -
	DB 0x50,0x50,0x5C,0x40,0x7C,0x00,0x00,0x00 ;200 / 0xC8 -
	DB 0x00,0x00,0x7C,0x40,0x5C,0x50,0x50,0x50 ;201 / 0xC9 -
	DB 0x50,0x50,0xDC,0x00,0xFC,0x00,0x00,0x00 ;202 / 0xCA -
	DB 0x00,0x00,0xFC,0x00,0xDC,0x50,0x50,0x50 ;203 / 0xCB -
	DB 0x50,0x50,0x5C,0x40,0x5C,0x50,0x50,0x50 ;204 / 0xCC -
	DB 0x00,0x00,0xFC,0x00,0xFC,0x00,0x00,0x00 ;205 / 0xCD -
	DB 0x50,0x50,0xDC,0x00,0xDC,0x50,0x50,0x50 ;206 / 0xCE -
	DB 0x20,0x20,0xFC,0x00,0xFC,0x00,0x00,0x00 ;207 / 0xCF -
	DB 0x50,0x50,0x50,0xFC,0x00,0x00,0x00,0x00 ;208 / 0xD0 -
	DB 0x00,0x00,0xFC,0x00,0xFC,0x20,0x20,0x20 ;209 / 0xD1 -
	DB 0x00,0x00,0x00,0xFC,0x50,0x50,0x50,0x50 ;210 / 0xD2 -
	DB 0x50,0x50,0x50,0x7C,0x00,0x00,0x00,0x00 ;211 / 0xD3 -
	DB 0x20,0x20,0x3C,0x20,0x3C,0x00,0x00,0x00 ;212 / 0xD4 -
	DB 0x00,0x00,0x3C,0x20,0x3C,0x20,0x20,0x20 ;213 / 0xD5 -
	DB 0x00,0x00,0x00,0x7C,0x50,0x50,0x50,0x50 ;214 / 0xD6 -
	DB 0x50,0x50,0x50,0xFC,0x50,0x50,0x50,0x50 ;215 / 0xD7 -
	DB 0x20,0x20,0xFC,0x20,0xFC,0x20,0x20,0x20 ;216 / 0xD8 -
	DB 0x20,0x20,0x20,0xE0,0x00,0x00,0x00,0x00 ;217 / 0xD9 -
	DB 0x00,0x00,0x00,0x3C,0x20,0x20,0x20,0x20 ;218 / 0xDA -
	DB 0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC ;219 / 0xDB -
	DB 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0xFC ;220 / 0xDC -
	DB 0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0xE0,0xE0 ;221 / 0xDD -
	DB 0x1C,0x1C,0x1C,0x1C,0x1C,0x1C,0x1C,0x1C ;222 / 0xDE -
	DB 0xFC,0xFC,0xFC,0xFC,0x00,0x00,0x00,0x00 ;223 / 0xDF -
	DB 0x00,0x00,0x68,0x90,0x90,0x90,0x68,0x00 ;224 / 0xE0 -
	DB 0x30,0x48,0x48,0x70,0x48,0x48,0x70,0xC0 ;225 / 0xE1 -
	DB 0xF8,0x88,0x80,0x80,0x80,0x80,0x80,0x00 ;226 / 0xE2 -
	DB 0xF8,0x50,0x50,0x50,0x50,0x50,0x98,0x00 ;227 / 0xE3 -
	DB 0xF8,0x88,0x40,0x20,0x40,0x88,0xF8,0x00 ;228 / 0xE4 -
	DB 0x00,0x00,0x78,0x90,0x90,0x90,0x60,0x00 ;229 / 0xE5 -
	DB 0x00,0x50,0x50,0x50,0x50,0x68,0x80,0x80 ;230 / 0xE6 -
	DB 0x00,0x50,0xA0,0x20,0x20,0x20,0x20,0x00 ;231 / 0xE7 -
	DB 0xF8,0x20,0x70,0xA8,0xA8,0x70,0x20,0xF8 ;232 / 0xE8 -
	DB 0x20,0x50,0x88,0xF8,0x88,0x50,0x20,0x00 ;233 / 0xE9 -
	DB 0x70,0x88,0x88,0x88,0x50,0x50,0xD8,0x00 ;234 / 0xEA -
	DB 0x30,0x40,0x40,0x20,0x50,0x50,0x50,0x20 ;235 / 0xEB -
	DB 0x00,0x00,0x00,0x50,0xA8,0xA8,0x50,0x00 ;236 / 0xEC -
	DB 0x08,0x70,0xA8,0xA8,0xA8,0x70,0x80,0x00 ;237 / 0xED -
	DB 0x38,0x40,0x80,0xF8,0x80,0x40,0x38,0x00 ;238 / 0xEE -
	DB 0x70,0x88,0x88,0x88,0x88,0x88,0x88,0x00 ;239 / 0xEF -
	DB 0x00,0xF8,0x00,0xF8,0x00,0xF8,0x00,0x00 ;240 / 0xF0 -
	DB 0x20,0x20,0xF8,0x20,0x20,0x00,0xF8,0x00 ;241 / 0xF1 -
	DB 0xC0,0x30,0x08,0x30,0xC0,0x00,0xF8,0x00 ;242 / 0xF2 -
	DB 0x18,0x60,0x80,0x60,0x18,0x00,0xF8,0x00 ;243 / 0xF3 -
	DB 0x10,0x28,0x20,0x20,0x20,0x20,0x20,0x20 ;244 / 0xF4 -
	DB 0x20,0x20,0x20,0x20,0x20,0x20,0xA0,0x40 ;245 / 0xF5 -
	DB 0x00,0x20,0x00,0xF8,0x00,0x20,0x00,0x00 ;246 / 0xF6 -
	DB 0x00,0x50,0xA0,0x00,0x50,0xA0,0x00,0x00 ;247 / 0xF7 -
	DB 0x00,0x18,0x24,0x24,0x18,0x00,0x00,0x00 ;248 / 0xF8 -
	DB 0x00,0x30,0x78,0x78,0x30,0x00,0x00,0x00 ;249 / 0xF9 -
	DB 0x00,0x00,0x00,0x00,0x30,0x00,0x00,0x00 ;250 / 0xFA -
	DB 0x04,0x04,0x08,0x08,0x90,0x70,0x20,0x00 ;251 / 0xFB -
	DB 0xA0,0x50,0x50,0x50,0x00,0x00,0x00,0x00 ;252 / 0xFC -
	DB 0x40,0xA0,0x20,0x40,0xE0,0x00,0x00,0x00 ;253 / 0xFD -
	DB 0x00,0x00,0x30,0x30,0x30,0x30,0x00,0x00 ;254 / 0xFE -
	DB 0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC ;255 / 0xFF -

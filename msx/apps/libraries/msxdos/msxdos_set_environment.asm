	include "msxdos.inc"

; extern uint8_t msxdosSetEnvironment(const char *name, const char *value) __sdcccall(1);
	PUBLIC	_msxdosSetEnvironment

_msxdosSetEnvironment:
	LD	C, $6C
	CALL	BDOS
	LD	L, A

	RET

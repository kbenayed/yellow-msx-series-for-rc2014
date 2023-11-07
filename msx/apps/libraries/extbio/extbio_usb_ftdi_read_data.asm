	SECTION	CODE
	include	"msx.inc"

;
; extern usb_error ftdi_read_data(device_config_ftdi *const ftdi, uint8_t *buf, uint8_t *const size);
;
	PUBLIC	__ftdi_read_data
__ftdi_read_data:
	PUSH	IX
	LD	D, EXTBIO_RC2014				; RC2014 EXTENDED DRIVER
	LD	E, EXTBIO_RC2014_USB_FTDI_FN			; FUNCTION CODE
	LD	C, EXTBIO_RC2014_USB_FTDI_READ_DATA_SUB_FN
	CALL	EXTBIO						; RETURN HL
	POP	IX
	RET

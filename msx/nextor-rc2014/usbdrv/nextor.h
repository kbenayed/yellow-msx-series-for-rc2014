#ifndef __NEXTOR
#define __NEXTOR

#include <stdlib.h>

#define NEXTOR_ERR_OK    0x00
#define NEXTOR_ERR_NCOMP 0xFF
#define NEXTOR_ERR_WRERR 0xFE
#define NEXTOR_ERR_DISK  0xFD
#define NEXTOR_ERR_NRDY  0xFC
#define NEXTOR_ERR_DATA  0xFA
#define NEXTOR_ERR_RNF   0xF9
#define NEXTOR_ERR_WPROT 0xF8
#define NEXTOR_ERR_UFORM 0xF7
#define NEXTOR_ERR_SEEK  0xF3
#define NEXTOR_ERR_IFORM 0xF0
#define NEXTOR_ERR_IDEVL 0xB5
#define NEXTOR_ERR_IPARM 0x8B

#define INFO_FLAG_REMOVABLE 0x01
#define INFO_FLAG_READ_ONLY 0x02
#define INFO_FLAG_FLOPPY    0x04

/**
 * @defgroup DEV_STATUS code returned by nextor driver's DEV_STATUS function
 *
 * @{
 */

/** The device or logical unit is not available, or the  device or logical unit number supplied is invalid. **/
#define DEV_STATUS_NOT_AVAILABLE_OR_INVALID 0
/** The device or logical unit is available and has not changed since the last status request. */
#define DEV_STATUS_AVAILABLE_AND_NOT_CHANGED 1
/** The device or logical unit is available and has changed since the last status request (for devices, the device has been
 * unplugged and a different device has been plugged which has been assigned the same device index; for logical units, the media has
 * been changed). */
#define DEV_STATUS_AVAILABLE_AND_CHANGED 2
/** The device or logical unit is available, but it is not possible to determine whether it has been changed or not since the last
 * status request.*/
#define DEV_STATUS_AVAILABLE 3
/** @} */

typedef struct _nextor_lun_info {
  uint8_t  medium_type;
  uint16_t sector_size;
  uint32_t number_of_sectors;
  uint8_t  flags;
  uint16_t number_of_cylinders;
  uint8_t  number_of_heads;
  uint8_t  number_of_sectors_per_track;
} nextor_lun_info;

typedef enum _dev_info_request {
  BASIC_INFORMATION = 0,
  MANUFACTURER_NAME = 1,
  DEVICE_NAME       = 2,
  SERIAL_NUMBER     = 3
} dev_info_request;

#endif

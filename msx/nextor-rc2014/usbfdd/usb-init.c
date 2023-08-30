#include "ch376.h"
#include "hw.h"
#include "nextor.h"
#include "scsi.h"
#include "usb-enumerate-hub.h"
#include "usb-enumerate.h"
#include "usb-lun-info.h"
#include "usb.h"
#include "work-area.h"
#include <delay.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "debuggin.h"
#include "print.h"

usb_error usb_host_bus_reset() {
  ch_cmd_set_usb_mode(CH_MODE_HOST);
  delay_medium();

  ch_cmd_set_usb_mode(CH_MODE_HOST_RESET);
  delay_medium();

  ch_cmd_set_usb_mode(CH_MODE_HOST);
  delay_medium();

  ch_configure_nak_retry_3s();

  return USB_ERR_OK;
}

void convert_and_print_disk_size(uint32_t number_of_sectors) {
  if (number_of_sectors == 1474560 / 512) {
    printf("1440KB");
    return;
  }

  const char *suffix = "KB";

  if (number_of_sectors >= 2048) {
    number_of_sectors /= 256;
    suffix = "MB";
  }

  if (number_of_sectors >= 2048) {
    number_of_sectors /= 1024;
    suffix = "GB";
  }

  const uint16_t a = (uint16_t)(number_of_sectors / 8);
  const uint16_t b = (uint16_t)(number_of_sectors % 8 * 100) / 8;

  if (b == 0)
    printf("%d%s", a, suffix);
  else
    printf("%d.%02d%s", a, b, suffix);
}

void print_disk_size(const uint8_t device_index) {
  nextor_lun_info info;

  usb_lun_info(device_index, 1, &info);
  convert_and_print_disk_size(info.number_of_sectors);
  printf(")\r\n");
}

bool state_devices(const _usb_state *const work_area) __z88dk_fastcall {
  const bool hasUsbHub = work_area->hub_config.address != 0;

  uint8_t                      floppy_count       = 0;
  uint8_t                      mass_storage_count = 0;
  uint8_t                      index              = MAX_NUMBER_OF_STORAGE_DEVICES;
  const storage_device_config *storage_device     = &work_area->storage_device[0];
  uint8_t                      device_index       = 1;

  if (hasUsbHub)
    print_string("USB HUB:\r\n");
  else
    print_string("USB:         ");

  do {
    const usb_device_type t = storage_device->type;
    if (t == USB_IS_FLOPPY) {
      print_string("    FLOPPY  (");

      print_disk_size(device_index);
      floppy_count++;
    }

    else if (t == USB_IS_MASS_STORAGE) {
      print_string("    STORAGE (");
      print_disk_size(device_index);
      mass_storage_count++;
    }

    storage_device++;
    device_index++;
  } while (--index != 0);

  if (!hasUsbHub && floppy_count == 0 && mass_storage_count == 0) {
    print_string("\r\n");
    return false;
  }

  return floppy_count != 0 || mass_storage_count != 0;
}

inline void initialise_mass_storage_devices(_usb_state *const work_area) {
  uint8_t                index          = MAX_NUMBER_OF_STORAGE_DEVICES;
  storage_device_config *storage_device = &work_area->storage_device[0];

  do {
    if (storage_device->type == USB_IS_MASS_STORAGE)
      scsi_sense_init(storage_device);
    storage_device++;
  } while (--index != 0);
}

#define ERASE_LINE "\x1B\x6C\r"

uint8_t usb_host_init() {
  work_area *const p = get_work_area();
  __asm__("EI");
  _usb_state *const work_area = &p->ch376;
  memset(work_area, 0, sizeof(_usb_state));

  ch_cmd_reset_all();

  if (!ch_probe()) {
    print_string("CH376:           NOT PRESENT\r\n");
    return false;
  }

  const uint8_t ver = ch_cmd_get_ic_version();
  print_string("CH376:           PRESENT (VER ");
  print_hex(ver);
  print_string(")\r\n");

  print_string("USB:             SCANNING...");

  usb_host_bus_reset();

  enumerate_all_devices();

  initialise_mass_storage_devices(work_area);

  print_string(ERASE_LINE);

  return state_devices(work_area);
}

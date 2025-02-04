#include "class_ufi.h"
#include "nextor.h"
#include "print.h"
#include "usb_state.h"
#include <string.h>

#if defined(ENUMERATE_TRACE_ENABLED)

bool logEnabled = false;

void logInterface(const interface_descriptor *const p) {
  printf("int len=%d,t=%d,inum=%d,alt=%d,numEnd=%d,", p->bLength, p->bDescriptorType, p->bInterfaceNumber, p->bAlternateSetting,
         p->bNumEndpoints);

  if (p->bLength > 5)
    printf("clas=%d,sub=%d,prot=%d,int=%d", p->bInterfaceClass, p->bInterfaceSubClass, p->bInterfaceProtocol, p->iInterface);

  printf("\r\n");
}

void logConfig(const config_descriptor *const p) {
  printf("cfg len=%d,typ=%d,tlen=%d,numI=%d,bcfgv=%d,icfg=%d,bmA=%02x,max=%d\r\n", p->bLength, p->bDescriptorType, p->wTotalLength,
         p->bNumInterfaces, p->bConfigurationvalue, p->iConfiguration, p->bmAttributes, p->bMaxPower);
}

void logDevice(const device_descriptor *const p) {
  printf("Device  length: %d,\r\n", p->bLength);
  printf("        bDescriptorType: %d,\r\n", p->bDescriptorType);
  printf("        bcdUSB: %02X,\r\n", p->bcdUSB);
  printf("        bDeviceClass: %02x,\r\n", p->bDeviceClass);
  printf("        bDeviceSubClass: %02x,\r\n", p->bDeviceSubClass);
  printf("        bDeviceProtocol: %02x,\r\n", p->bDeviceProtocol);
  printf("        bMaxPacketSize0: %d,\r\n", p->bMaxPacketSize0);
  printf("        idVendor: %04X,\r\n", p->idVendor);
  printf("        idProduct: %04X,\r\n", p->idProduct);
  printf("        bcdDevice: %04X,\r\n", p->bcdDevice);
  printf("        iManufacturer:%d,\r\n", p->iManufacturer);
  printf("        iProduct: %d,\r\n", p->iProduct);
  printf("        iSerialNumber: %d,\r\n", p->iSerialNumber);
  printf("        bNumConfigurations:%d\r\n", p->bNumConfigurations);
}

void logEndPointDescription(const endpoint_descriptor *const p) {
  printf("ep: len=%d,t=%d,e=%d,a=%d,size=%d,intv=%d\r\n", p->bLength, p->bDescriptorType, p->bEndpointAddress, p->bmAttributes,
         p->wMaxPacketSize, p->bInterval);
}

// void logEndPointParam(const endpoint_param *const p) {
//   printf("enp (num=%d,tog=%d,max=%d)", p->number, p->toggle, p->max_packet_size);
// }

// void logWorkArea(const _usb_state *const p) {
//   printf("dev: %d: h-max: %d, h-cfg: %d, f-max: %d, f-cfg: %d, int: %d, BLKOUT: ",
//          p->usb_device,
//          p->hub_config.max_packet_size,
//          p->hub_config.value,
//          p->floppy_config.max_packet_size,
//          p->floppy_config.value,
//          p->interface_number);
//   logEndPointParam(&p->endpoints[ENDPOINT_BULK_OUT]);
//   printf(" BLKIN: ");
//   logEndPointParam(&p->endpoints[ENDPOINT_BULK_IN]);
//   printf(" INTIN: ");
//   logEndPointParam(&p->endpoints[ENDPOINT_INTERRUPT_IN]);
//   printf("\r\n");
// }

// void logInquiryResponse(const ufi_inquiry_response *const response) {
//   printf("typ: %d,", response->device_type);
//   printf("rmb: %d", response->removable_media);
//   printf("ans: %d,", response->ansi_version);
//   printf("ecma: %d,", response->ecma);
//   printf("iso: %d,", response->iso_version);
//   printf("fmt: %d,", response->response_data_format);
//   printf("add: %d,", response->additional_length);

//   char buffer[20];

//   memset(buffer, 0, 20);
//   memcpy(buffer, response->product_id, 16);
//   print_string(buffer);
//   print_string(",");

//   memset(buffer, 0, 20);
//   memcpy(buffer, response->vendor_information, 8);
//   print_string(buffer);
//   print_string(",");

//   memset(buffer, 0, 20);
//   memcpy(buffer, response->product_revision, 4);
//   print_string(buffer);
//   print_string("\r\n");
// }

// void logSetupPacket(const setup_packet *const cmd_packet) {
//   printf("bmRequestType = %d", cmd_packet->bmRequestType);
//   printf("bRequest = %d", cmd_packet->bRequest);
//   printf("bValue = %d,%d", cmd_packet->bValue[0], cmd_packet->bValue[1]);
//   printf("bIndex = %d,%d", cmd_packet->bIndex[0], cmd_packet->bIndex[1]);
//   printf("wLength = %d\r\n", cmd_packet->wLength);
// }

// void logNextorLunInfo(const nextor_lun_info* const info) {
//   printf("medium_type = %d,", info->medium_type);
//   printf("sector_size = %d,", info->sector_size);
//   printf("number_of_sectors = %ld,", info->number_of_sectors);
//   printf("flags = %02x", info->flags);
//   printf("number_of_cylinders = %d,", info->number_of_cylinders);
//   printf("number_of_heads = %d,", info->number_of_heads);
//   printf("number_of_sectors_per_track = %d,", info->number_of_sectors_per_track);
// }

void logHubDescription(const hub_descriptor *const hub_descriptor) {
  printf("hub: len=%d,t=%d,ports=%d,char=%d,pwr=%d,ccur=%d,rem=%d\r\n", hub_descriptor->bDescLength,
         hub_descriptor->bDescriptorType, hub_descriptor->bNbrPorts, hub_descriptor->wHubCharacteristics,
         hub_descriptor->bPwrOn2PwrGood, hub_descriptor->bHubContrCurrent, hub_descriptor->DeviceRemovable[0]);
}

// void logHubPortStatus(const hub_port_status *const port_status) { printf("hub: wPortStatus=%04x,wPortChange=%04x\r\n",
// port_status->wPortStatus.val, port_status->wPortChange.val); }

void log_ufi_request_sense_response(const ufi_request_sense_response *const response) {

  printf("Code: %02X, key: %02X, ASC: %02X, ASCQ: %02X\r\n", response->error_code, response->sense_key, response->asc,
         response->ascq);
}

void log_usb_inquiry_response(const ufi_inquiry_response *const inquiry) {

  printf("Device Type: %02X, Removable Media: %02X, Additional Length: %02X\r\n", inquiry->device_type, inquiry->removable_media,
         inquiry->additional_length);

  char vendor[9];
  char product_id[17];
  char product_revision[5];

  memset(vendor, 0, 9);
  memset(product_id, 0, 17);
  memset(product_revision, 0, 5);

  memcpy(vendor, inquiry->vendor_information, 8);
  memcpy(product_id, inquiry->product_id, 8);
  memcpy(product_revision, inquiry->product_revision, 4);

  printf(" Vendor: %s\r\n", vendor);
  printf(" Product ID: %s\r\n", product_id);
  printf(" Product Revision: %s\r\n", product_revision);
}

#endif

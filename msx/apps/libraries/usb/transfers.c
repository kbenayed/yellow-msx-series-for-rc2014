/**
 * @file transfers.c
 * @author Dean Netherton
 * @brief A simplest implementation of common usb transfer functions, based on the CH376S chip
 * @details For a basic walkthrough of the usb protocol see https://www.beyondlogic.org/usbnutshell/usb1.shtml
 * @version 1.0
 * @date 2023-09-22
 *
 * @copyright Copyright (c) 2023
 *
 */

#include "transfers.h"
#include "ch376.h"
#include <delay.h>
#include <stdlib.h>

/**
 * @brief Perform a USB control transfer (in or out)
 * See https://www.beyondlogic.org/usbnutshell/usb4.shtml for a description of the USB control transfer
 *
 * @param cmd_packet Pointer to the setup packet - top bit of bmRequestType indicate data direction
 * @param buffer Pointer of data to send or receive into
 * @param device_address usb device address
 * @param max_packet_size Maximum packet size for endpoint
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error usb_control_transfer(const setup_packet *const cmd_packet,
                               void *const               buffer,
                               const uint8_t             device_address,
                               const uint8_t             max_packet_size) {
  usb_error      result;
  endpoint_param endpoint = {1, 0, max_packet_size};

  const uint8_t transferIn = (cmd_packet->bmRequestType & 0x80);

  if (transferIn && buffer == 0)
    return USB_ERR_OTHER;

  ch_set_usb_address(device_address);

  ch_write_data((const uint8_t *)cmd_packet, sizeof(setup_packet));
  ch_issue_token_setup();
  CHECK(ch_short_wait_int_and_get_status())

  const uint16_t length = cmd_packet->wLength;

  result = length != 0
               ? (transferIn ? ch_data_in_transfer(buffer, length, &endpoint) : ch_data_out_transfer(buffer, length, &endpoint))
               : USB_ERR_OK;

  CHECK(result)

  if (transferIn) {
    ch_command(CH_CMD_WR_HOST_DATA);
    CH376_DATA_PORT = 0;
    ch_issue_token_out_ep0();
    result = ch_long_wait_int_and_get_status(); /* sometimes we get STALL here - seems to be ok to ignore */

    if (result == USB_ERR_OK || result == USB_ERR_STALL)
      return USB_ERR_OK;

    CHECK(result);

    return result;
  }

  ch_issue_token_in_ep0();
  result = ch_long_wait_int_and_get_status();

  if (result == USB_ERR_STALL)
    return USB_ERR_STALL;

  RETURN_CHECK(result);
}

/**
 * @brief Perform a USB data in on the specififed endpoint
 *
 * @param buffer the buffer to receive the data
 * @param buffer_size the maximum size of data to be received
 * @param device_address the usb address of the device
 * @param endpoint the usb endpoint to receive from (toggle of endpoint is updated)
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error
usb_data_in_transfer(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
  usb_error result;
  ch_set_usb_address(device_address);

  RETURN_CHECK(ch_data_in_transfer(buffer, buffer_size, endpoint));
}

/**
 * @brief Perform a USB data out on the specififed endpoint
 *
 * @param buffer the buffer to send the data from
 * @param buffer_size the maximum size of data to be sent
 * @param device_address the usb address of the device
 * @param endpoint the usb endpoint to send to (toggle of endpoint is updated)
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error
usb_data_out_transfer(const uint8_t *buffer, uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
  ch_set_usb_address(device_address);
  usb_error result;

  RETURN_CHECK(ch_data_out_transfer(buffer, buffer_size, endpoint));
}

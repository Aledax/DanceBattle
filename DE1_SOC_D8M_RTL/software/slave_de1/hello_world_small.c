/*
 * "Small Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It requires a STDOUT  device in your system's hardware.
 *
 * The purpose of this example is to demonstrate the smallest possible Hello
 * World application, using the Nios II HAL library.  The memory footprint
 * of this hosted application is ~332 bytes by default using the standard
 * reference design.  For a more fully featured Hello World application
 * example, see the example titled "Hello World".
 *
 * The memory footprint of this example has been reduced by making the
 * following changes to the normal "Hello World" example.
 * Check in the Nios II Software Developers Manual for a more complete
 * description.
 *
 * In the SW Application project (small_hello_world):
 *
 *  - In the C/C++ Build page
 *
 *    - Set the Optimization Level to -Os
 *
 * In System Library project (small_hello_world_syslib):
 *  - In the C/C++ Build page
 *
 *    - Set the Optimization Level to -Os
 *
 *    - Define the preprocessor option ALT_NO_INSTRUCTION_EMULATION
 *      This removes software exception handling, which means that you cannot
 *      run code compiled for Nios II cpu with a hardware multiplier on a core
 *      without a the multiply unit. Check the Nios II Software Developers
 *      Manual for more details.
 *
 *  - In the System Library page:
 *    - Set Periodic system timer and Timestamp timer to none
 *      This prevents the automatic inclusion of the timer driver.
 *
 *    - Set Max file descriptors to 4
 *      This reduces the size of the file handle pool.
 *
 *    - Check Main function does not exit
 *    - Uncheck Clean exit (flush buffers)
 *      This removes the unneeded call to exit when main returns, since it
 *      won't.
 *
 *    - Check Don't use C++
 *      This builds without the C++ support code.
 *
 *    - Check Small C library
 *      This uses a reduced functionality C library, which lacks
 *      support for buffering, file IO, floating point and getch(), etc.
 *      Check the Nios II Software Developers Manual for a complete list.
 *
 *    - Check Reduced device drivers
 *      This uses reduced functionality drivers if they're available. For the
 *      standard design this means you get polled UART and JTAG UART drivers,
 *      no support for the LCD driver and you lose the ability to program
 *      CFI compliant flash devices.
 *
 *    - Check Access device drivers directly
 *      This bypasses the device file system to access device drivers directly.
 *      This eliminates the space required for the device file system services.
 *      It also provides a HAL version of libc services that access the drivers
 *      directly, further reducing space. Only a limited number of libc
 *      functions are available in this configuration.
 *
 *    - Use ALT versions of stdio routines:
 *
 *           Function                  Description
 *        ===============  =====================================
 *        alt_printf       Only supports %s, %x, and %c ( < 1 Kbyte)
 *        alt_putstr       Smaller overhead than puts with direct drivers
 *                         Note this function doesn't add a newline.
 *        alt_putchar      Smaller overhead than putchar with direct drivers
 *        alt_getchar      Smaller overhead than getchar with direct drivers
 *
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "esp.h"
#include "system.h"
#include "uart.h"

#define NUM_POINT_FINDERS 1
volatile uint32_t *camera_base = COORDS_SLAVE_0_BASE;
static uint32_t thresholds[NUM_POINT_FINDERS];

/* arr is mutated to contain the coordinates the points
 * len is set to the size of arr
 *
 * (x,y) = (0,0) is at top left of VGA monitor
 * x = arr[i] & 0xFFFF;
 * y = arr[i] >> 16;
 */
void getFrame(uint32_t *arr, int *len) {
  arr = (uint32_t *)malloc(NUM_POINT_FINDERS * sizeof(uint32_t));
  *len = NUM_POINT_FINDERS;

  uint32_t raw_coords;
  for (int i = 0; i < NUM_POINT_FINDERS; i++) {
    raw_coords = *(camera_base + i);
    arr[i] = raw_coords;
    //	  uint16_t smallUpBigDown = raw_coords >> 16;
    //	  uint16_t smallLeftBigRight = raw_coords & 0xFFFF;
    //	  printf("smallUpBigDown: %i, smallLeftBigRight: %i\n", smallUpBigDown,
    // smallLeftBigRight);
  }
}

// sample code for Bell
void printCoords() {
  int len;
  uint32_t *arr = NULL;
  while (1) {
    getFrame(arr, &len);
    for (int i = 0; i < len; i++) {
      uint32_t raw_coords = arr[i];
      uint16_t x = raw_coords & 0xFFFF;
      uint16_t y = raw_coords >> 16;
      printf("x: %i, y: %i\n", x, y);
    }
  }
  free(arr);
}

void printThresholds(int i) {
  printf("Thresholds: crLow=%d crHigh=%d cbLow=%d cbHigh=%d\n",
         (thresholds[i] >> 24) & 0xFF, (thresholds[i] >> 16) & 0xFF,
         (thresholds[i] >> 8) & 0xFF, thresholds[i] & 0xFF);
}

void writeThresholds(int i) { *(camera_base + i) = thresholds[i]; }

int main(int argc, char **argv) {
  printf("Program start 1\n");
  uint8_t cbLow = 111, cbHigh = 133, crLow = 112, crHigh = 134;
  thresholds[0] = (crLow << 24) | (crHigh << 16) | (cbLow << 8) | cbHigh;
  writeThresholds(0);
  //	printCoords();

  int index = 0;
  int c;

  uart_init();
  uart_output();
  esp_run(argc, argv);

  //	int c;
  while (1) {
    char c;
    printf("Press a key on your keyboard: ");
    while ((c = getchar()) == '\n')
      ;  // consume newline characters
    if (c == 'q') {
      break;
    }
    printf("You pressed the '%c' key.\n", c);
    while (getchar() != '\n')
      ;  // clear input buffer
  }
  return 0;
}

// Top right: 120, 430
// Top left 100, 200
// Bottom right: 300, 430

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Misc */
size_t strlen(const char * str) {
  size_t ret = 0;
  while (str[ret])
    ret++;
  return ret;
}

void memcpy(void * to, const void * from, size_t length) {
  size_t counter = 0;
  while (counter < length) {
    *(char*)(to + counter) = *(char*)(from + counter);
    counter++;
  }
}

void memfill(void * to, uint8_t what, size_t length) {
  while (length--) {
    *(char*)(to+length) = what;
  }
}

extern char * int2str(uint32_t, char *);

/*** VGA ***/
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

typedef enum vga_color {
  VGA_COLOR_BLACK = 0,
  VGA_COLOR_BLUE = 1,
  VGA_COLOR_GREEN = 2,
  VGA_COLOR_CYAN = 3,
  VGA_COLOR_RED = 4,
  VGA_COLOR_MAGENTA = 5,
  VGA_COLOR_BROWN = 6,
  VGA_COLOR_LIGHT_GREY = 7,
  VGA_COLOR_DARK_GREY = 8,
  VGA_COLOR_LIGHT_BLUE = 9,
  VGA_COLOR_LIGHT_GREEN = 10,
  VGA_COLOR_LIGHT_CYAN = 11,
  VGA_COLOR_LIGHT_RED = 12,
  VGA_COLOR_LIGHT_MAGENTA = 13,
  VGA_COLOR_LIGHT_BROWN = 14,
  VGA_COLOR_WHITE = 15,
} vga_color;

#define vga_make_color(FG, BG)			\
  (FG | BG<<4)

#define vga_make_entry(CHAR, COLOR)		\
  (CHAR | COLOR<<8)

size_t vga_row = 0;
size_t vga_col = 0;
uint8_t vga_text_screen_color =
  vga_make_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
uint16_t * vga_text_screen = (void*)0xB8000;
uint16_t vga_text_buffer[VGA_HEIGHT][VGA_WIDTH];

void vga_flush() {
  memcpy(vga_text_screen, vga_text_buffer, sizeof(vga_text_buffer));
}

void vga_putc(char c) {
  switch (c) {
  case '\n':
    vga_row++;
    vga_col=0;
    break;
  default:
    vga_text_buffer[vga_row][vga_col] = vga_make_entry(c, vga_text_screen_color);
    vga_col++;
    break;
  }
  if (vga_col == VGA_WIDTH) {
    vga_row++;
    vga_col=0;
  }
  if (vga_row == VGA_HEIGHT) {
    vga_row--;
    for (size_t j = 0; j < VGA_HEIGHT-1; j++) {
      for (size_t i = 0; i < VGA_WIDTH; i++) {
	vga_text_buffer[j][i] = vga_text_buffer[j+1][i];
      }
    }
    for (size_t i = 0; i < VGA_WIDTH; i++) {
      vga_text_buffer[vga_row][i] = vga_make_entry(' ', vga_text_screen_color);
    }
  }
}

void vga_putchar(char c) {
  vga_putc(c);
  vga_flush();
}

void vga_puts(const char * str) {
  size_t length = strlen(str);
  for (size_t i = 0; i < length; i++)
    vga_putc(str[i]);
  vga_flush();
}

/*** Main ***/
typedef struct {
  uint32_t flags;
  uint32_t mem_lower;
  uint32_t mem_upper;
  uint32_t boot_device;
  char * cmdline;
  uint8_t other[70];
} boot_info;

void main(boot_info * opts) {
  char str[12];
  if (opts->flags | 4) {
    vga_puts("It works! Boot opts: \"");
    vga_puts(opts->cmdline);
    vga_puts("\"\nCommand line address: ");
    vga_puts(int2str((uint32_t)opts->cmdline, str));
  } else {
    vga_puts("It works! No options recieved.");
  }
}

#include <stdint.h>

extern void  puts(char*);
extern void* allot(uint32_t);
extern void memcpy(void*, const void*, uint32_t);

int
main(char* cmd)
{
  char* greeter = allot(54);
  memcpy(greeter,
	 "Hello unixless world. :)\n"
	 "My bootloader settings are: ", 54);
  puts(greeter);
  puts(cmd);
  puts(
    "\nAnd now... I sleep.\n"
    "    z-z-Z-z-z\n"
    "z-z-Z\n"
    "         Z-z-Z-z\n");
  return 0;
}

#include <stdint.h>

extern void  puts(char* s);
extern void* malloc(uint32_t size);
extern void  strcpy(char* restrict s1, const char* restrict s2);
extern void  printf(const char* format, ...);
extern void  putchar(char c);
extern int   getchar(void);
extern void  halt(void);

void
main(char* cmd)
{
	char* volatile greeter = malloc(54);
	strcpy(greeter,
	       "Hello unixless world. :) "
	       "My bootloader settings are:");
	printf("%s %s\n%s\n", greeter, cmd,
	       "This is an example of printf %s "
	       "string substitution.\n"
	       "The first line was dynamicly allocated "
	       "using malloc function.");
	printf("%s %d\n", "Now this is an example of printf "
	       "%d decimal convertion for 42:", 42);
	puts("\nType in commands below:\n> ");
	while (1) {
		int c = getchar();
		putchar(c);
		if (c == '\n') puts("> ");
	}
}

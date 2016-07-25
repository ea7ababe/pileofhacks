#include <stdint.h>
#include <stddef.h>

/* external functions */
extern void  puts(char* s);
extern void* malloc(uint32_t size);
extern void  strcpy(char* restrict s1, const char* restrict s2);
extern void  printf(const char* format, ...);
extern void  putchar(char c);
extern int   getchar(void);
extern void  halt(void);
extern uint32_t pci_probe(uint8_t bus, uint8_t slot, uint8_t func);
extern uint16_t pci_class(uint8_t bus, uint8_t slot, uint8_t func);
extern uint32_t pci_config(uint8_t bus, uint8_t slot,
                           uint8_t func, uint8_t offset);
extern char* pci_devstr(uint16_t class);
extern void trace(void);
extern void die_with_honor(void);
extern void reboot(void);

/* global variables */
static char cmd[4096];
static char* cmd_args;

static char*
strchr(const char* s, char c)
{
	while (*s != c)
		if (!*s++)
			return 0;
	return (char*)s;
}

static int
strcmp(const char* s1, const char* s2)
{
    while(*s1 && (*s1==*s2)) s1++,s2++;
    return *(const unsigned char*)s1-*(const unsigned char*)s2;
}

static char
lspci(void) {
	volatile int bus;
	volatile int slot;
	volatile int func;
	for (bus = 0; bus < 256; bus++) {
		for (slot = 0; slot < 32; slot++) {
			for (func = 0; func < 8; func++) {
				if (!pci_probe(bus, slot, func))
					continue;
				/* volatile uint8_t header = (uint8_t) */
				/* 	pci_config(bus, slot, func, 0xC)>>16; */
				volatile uint16_t class =
					pci_class(bus, slot, func);
				volatile char* desc =
					pci_devstr(class);
				volatile uint8_t subclass =
					class&0xFF;
				class >>= 8;
				printf("%d:%d.%d class %d:%d %s\n",
				       bus, slot, func,
				       class, subclass, desc);
			}
		}
	}
	return 0;
}

static char
echo(void) {
	printf("%s\n", cmd_args);
	return 0;
}

static char
halt_cmd(void) {
	puts("execution has stopped");
	die_with_honor();
	return -1; /* should never return */
}

static char
reboot_cmd(void) {
	reboot();
	puts("reboot failed");
	return -1;
}

static char
unknown_command() {
	printf("unknown command: %s\n", cmd);
	return 1;
}

/* basic command interpreter */
typedef char (*command)();
typedef struct pair {
	char* key;
	command com;
} pair;

static char rc = 0;
static pair commands[] = {
	{"lspci", lspci},
	{"halt", halt_cmd},
	{"reboot", reboot_cmd},
	{"echo", echo},
	{0}
};

static command
find_cmd(const char* key)
{
	int i;
	for (i = 0; commands[i].key != 0; i++) {
		if (strcmp(key, commands[i].key) == 0)
			return commands[i].com;
	}
	return unknown_command;
}

static void
get_command(char c)
{
	static int cmd_index = 0;
	command com;
	switch (c) {
	case '\n':
		if (cmd_index > 0) {
			cmd_args = strchr(cmd, ' ');
			*cmd_args++ = 0;
			com = find_cmd(cmd);
			rc = com();
			cmd[0] = 0;
			cmd_args[0] = 0;
			cmd_index = 0;
		}
		printf("%d> ", rc);
		break;
	case '\b':
		if (cmd_index > 0) {
			cmd[--cmd_index] = 0;
		}
		break;
	default:
		if (cmd_index < 255) {
			cmd[cmd_index++] = c;
			cmd[cmd_index] = 0;
		}
		break;
	}
}

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
	/* printf("%s %d\n", "Now this is an example of printf " */
	/*        "%d decimal convertion for 42:", 42); */
	/* puts("PCI devices:\n"); */
	/* lspci(); */
	puts("\nType in commands below:\n> ");
	while (1) {
		int c = getchar();
		putchar(c);
		get_command(c);
	}
}

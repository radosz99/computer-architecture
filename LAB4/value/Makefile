value: value.o
	ld value.o -m elf_i386 -o value 
value.o: value.s
	as --32 value.s -g -o value.o

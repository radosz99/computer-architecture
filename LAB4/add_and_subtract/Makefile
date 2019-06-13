add: add.o
	ld add.o -m elf_i386 -o add 
add.o: add.s
	as --32 add.s -g -o add.o

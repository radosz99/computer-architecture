adder: adder.o
	ld adder.o -m elf_i386 -o adder 
adder.o: adder.s
	as --32 adder.s -g -o adder.o

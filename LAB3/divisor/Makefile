divisor: divisor.o
	ld divisor.o -m elf_i386 -o divisor 
divisor.o: divisor.s
	as --32 divisor.s -g -o divisor.o

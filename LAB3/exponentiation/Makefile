power: power.o
	ld power.o -m elf_i386 -o power 
power.o: power.s
	as --32 power.s -g -o power.o

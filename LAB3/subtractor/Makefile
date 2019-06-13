subtractor: subtractor.o
	ld subtractor.o -m elf_i386 -o subtractor 
subtractor.o: subtractor.s
	as --32 subtractor.s -g -o subtractor.o

multi: multi.o
	ld multi.o -m elf_i386 -o multi 
multi.o: multi.s
	as --32 multi.s -g -o multi.o

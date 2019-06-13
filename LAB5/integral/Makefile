integral: integral.o
	ld -dynamic-linker /lib/ld-linux.so.2 -o integral integral.o -lc -m elf_i386
integral.o: integral.s
	as integral.s -o integral.o -g --32

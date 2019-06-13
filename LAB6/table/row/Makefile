table: table.o
	ld -dynamic-linker /lib/ld-linux.so.2 -o table table.o -lc -m elf_i386
table.o: table.s
	as table.s -o table.o -g --32

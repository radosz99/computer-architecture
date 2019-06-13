param: param.o
	ld -dynamic-linker /lib/ld-linux.so.2 -o param param.o -lc -m elf_i386
param.o: param.s
	as param.s -o param.o -g --32

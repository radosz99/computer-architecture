envi: envi.o
	ld -dynamic-linker /lib/ld-linux.so.2 -o envi envi.o -lc -m elf_i386
envi.o: envi.s
	as envi.s -o envi.o -g --32

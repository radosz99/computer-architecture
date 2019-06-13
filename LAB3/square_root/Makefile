root: root.o
	ld root.o -m elf_i386 -o root 
root.o: root.s
	as --32 root.s -g -o root.o

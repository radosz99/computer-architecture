tree: tree.o
	ld tree.o -m elf_i386 -o tree 
tree.o: tree.s
	as --32 tree.s -g -o tree.o

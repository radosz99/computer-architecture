test: test.o
	ld test.o -m elf_i386 -o test 
test.o: test.s
	as --32 test.s -g -o test.o

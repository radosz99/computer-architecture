hello: hello.o
	ld hello.o -m elf_i386 -o hello 
hello.o: hello.s
	as --32 hello.s -g -o hello.o

.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.section .bss

.section .data
    
    output:
    .asciz "%s\n"

	message0:
	.ascii "Parametry wywołania: \0\n"
	mes0_len = .-message0

.section .text
.globl _start

_start:

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $message0, %ecx
	movl $mes0_len, %edx
	int $LINUX_SYSCALL

    movl (%esp), %ecx

    movl %esp, %ebp
    addl $4, %ebp

loop1:
    pushl %ecx
    pushl (%ebp)
    pushl $output
    call printf
    addl $8, %esp
    popl %ecx
    addl $4, %ebp
    loop loop1

end:
    pushl $0
    call exit


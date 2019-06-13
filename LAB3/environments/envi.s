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
	.ascii "Zmienne środowiskowe: \0\n"
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
    addl $8, %ebp

loop1:
    addl $4, %ebp
    decl %ecx
    cmpl $0, %ecx
    jg loop1

loop2:
    cmpl $0, (%ebp)
    je end
    pushl (%ebp)
    pushl $output
    call printf
    addl $12, %esp
    addl $4, %ebp
    loop loop2

end:
    pushl $0
    call exit


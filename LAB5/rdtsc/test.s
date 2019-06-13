.equ LINUX_SYSCALL, 0x80
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ LENGTH, 32

.section .bss

.lcomm time, LENGTH

.section .data

	message0:
	.ascii "\nCzas: \0"
	mes0_len = .-message0


.section .text 
.globl _start 
_start:

loadUpperLimit:
    rdtsc
    xorl %ecx, %ecx
    addl %eax, %ecx

fragment:
    addl $2, %edx
    addl $5, %edx
    addl $10, %edx

    rdtsc 
    subl %ecx, %eax

    xorl %ecx, %ecx
    movl $10, %ecx
    xorl %edi, %edi
    movl $30, %edi
    movl $0xA, time (,%edi,1)
    incl %edi
    movl $0xD, time (,%edi,1)
    decl %edi
    decl %edi

loop:
    xorl %edx, %edx
    idiv %ecx
    addl $48, %edx
    movb %dl, time (,%edi,1)
    decl %edi
    cmpl $0, %eax
    jne loop

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $message0, %ecx
	movl $mes0_len, %edx
	int $LINUX_SYSCALL
    
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $time, %ecx # wyswietlamy sum
	movl $32, %edx
	int $LINUX_SYSCALL

exit:
    movl $1, %eax 
    movl $0, %ebx 
    int $0x80


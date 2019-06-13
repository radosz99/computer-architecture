.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.section .data
    rowsAmount = 4
    columnsAmount = 4
    rowCounter: .long 0
    columnCounter: .long 0
    printFormat: .string "%lld\n"

.section .bss
    .equ size, 4 * rowsAmount * columnsAmount
    .lcomm matrix, size
    .lcomm timeStamp, 8

.section .text
.globl _start

_start:
    xorl %eax, %eax
    xorl %ebx, %ebx
    xorl %ecx, %ecx
    xorl %edx, %edx
    rdtsc
    movl %eax, %ecx
    movl %edx, %ebx

columnsFilling:
    movl columnCounter, %esi
    movl $0, rowCounter

rowsFilling:
    movl rowCounter, %edi
    addl %esi, %edi
    movl $'0', matrix(,%edi,4)
    addl $columnsAmount, rowCounter
    cmpl $rowsAmount * columnsAmount, rowCounter
    jl rowsFilling

    incl columnCounter

    cmpl $columnsAmount, columnCounter
    jne columnsFilling

    rdtsc
    subl %ecx, %eax
    sbbl %ebx, %edx
    movl %eax, timeStamp
    movl %edx, timeStamp + 4

printResult:
    pushl timeStamp + 4
    pushl timeStamp
    pushl $printFormat
    call printf

exit:
    movl $EXIT, %eax
	movl $0, %ebx
	int $LINUX_SYSCALL

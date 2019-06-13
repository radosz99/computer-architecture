.section .data

.equ LINUX_SYSCALL, 0x80
.equ SIZE, 1024
.equ CLONE, 120
.equ WRITE, 4
.equ STDOUT, 1
.equ EXIT, 1
.equ CLONE_VM, 0x00000100
.equ CLONE_FS, 0x00000200
.equ CLONE_FILES, 0x00000400
.equ CLONE_SIGHAND, 0x00000800
.equ CLONE_PARENT, 0x00008000
.equ CLONE_THREAD, 0x00010000
.equ CLONE_IO, 0x80000000

CLONE_FLAGS = CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_PARENT | CLONE_THREAD | CLONE_IO

textFirst: .string "First thread is working now\n"
textSecond: .string "Second thread is working now\n"
textFirstLen = . - textFirst
textSecondLen = . - textSecond
counter: .long 0

.section .bss
.lcomm stack1, SIZE
.lcomm stack2, SIZE

.global main
.section .text
main:
    pushl $firstThreadWRK
    pushl $stack1 + SIZE
    call creatingThread
    addl $8, %esp

    pushl $secondThreadWRK
    pushl $stack2 + SIZE
    call creatingThread
    addl $8, %esp

checking:
    cmpl $0, counter
    jne checking
    jmp end

firstThreadWRK:
    movl $textFirstLen, %edx
    movl $textFirst, %ecx
    movl $STDOUT, %ebx
    movl $WRITE, %eax
    int $0x80
    lock decl counter
    jmp end

secondThreadWRK:
    movl $textSecondLen, %edx
    movl $textSecond, %ecx
    movl $STDOUT, %ebx
    movl $WRITE, %eax
    int $0x80
    lock decl counter

end:
    movl $EXIT, %eax
	movl $0, %ebx
	int $LINUX_SYSCALL

creatingThread:
    lock incl counter
    movl 4(%esp), %ecx
    subl $4, %ecx
    movl 8(%esp), %eax
    movl %eax, (%ecx)
    movl $CLONE_FLAGS, %ebx
    movl $CLONE, %eax
	int $LINUX_SYSCALL
    ret

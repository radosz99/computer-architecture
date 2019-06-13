EXIT=1
WRITE=4
STDOUT=1

.data
	msg: .ascii "Hello World!\n\0"
	msg_len = . - msg

.text
.global _start
_start:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $msg, %ecx
	movl $msg_len, %edx
	int $0x80

	movl $EXIT, %eax
	int $0x80


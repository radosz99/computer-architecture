.section .data 
.section .text
.type mysin, @function
.globl mysin

mysin:
	pushl %ebp
    movl %esp, %ebp

    flds 8(%ebp)
    fsin

    movl %ebp, %esp
    popl %ebp
    ret



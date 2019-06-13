.equ EXIT, 1
.equ READ, 3
.equ WRITE, 4
.equ STDIN, 0
.equ STDOUT, 1
.equ SYSCALL, 0x80

.section .bss
.equ LBUFOR, 12
.lcomm bufor, LBUFOR
.lcomm height, LBUFOR
.lcomm counter1, LBUFOR

.section .data
	star: .ascii "*"
	space: .ascii " "
	newLine: .ascii "\n"
	counter2: .long 1
	question: .ascii "Hej. Wprowadz wysokosc choinki: \0"
	question_len = .-question

.section .text
.global _start 
_start:
	
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $question, %ecx
    movl $question_len, %edx
    int $SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $bufor, %ecx
	movl $LBUFOR, %edx
	int $SYSCALL

	pushl $bufor
	call convertBuffer
	addl $4, %esp

	movl %eax, height
	movl %eax, counter1	

mainLoop:
	cmpl $0, counter1
	je printTrunk

	# PRINT SPACES
	decl counter1
	pushl counter1
	pushl $space
	call print

	addl $8, %esp

	# PRINT STARS
	pushl counter2
	add $2, counter2
	pushl $star
	call print

	addl $8, %esp
	
	# NEW LINE	
	pushl $1
	pushl $newLine
	call print

	addl $8, %esp
	jmp mainLoop

printTrunk:
	decl height
	pushl height
	pushl $space
	call print

	addl $8, %esp
	pushl $1
	pushl $star
	call print

	addl $8, %esp
	pushl $1
	pushl $newLine
	call print

	addl $8, %esp

	movl $EXIT, %eax
	int $SYSCALL

.type print, @function
print:
	pushl %ebp
	movl %esp, %ebp
	movl 12(%ebp), %esi

printLoop:
	cmpl $0, %esi
	je endLoop
	decl %esi
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl 8(%esp), %ecx
	movl $1, %edx
	int $SYSCALL
	jmp printLoop	

endLoop:
	movl %ebp, %esp
	popl %ebp
	ret

.type convertBuffer, @function
convertBuffer:
	pushl %ebp
	movl %esp, %ebp
	movl $0, %eax
	movl 8(%ebp), %ecx	#pod 8(%ebp) mamy ciag znakow z bufora
	movl $0, %ebx
	movb (%ecx), %bl
	cmpb $0x20, %bl		# jesli nie zostaly wpisane cyfry przeskakujemy do bledu
	jbe errorConvertBuffer

startConvertBuffer:
	subb $0x30, %bl 	# ascii --> cyfra 
	addl %ebx, %eax		# dodawanie cyfry do dotychczasowej liczby
	incl %ecx		# inkrementacja ecx by uzyskac nastepny znak z bufora
	movl $0, %ebx		# zerowanie ebx
	movb (%ecx), %bl	# pobieranie znaku (indirect addressing type)

	cmpb $0x20, %bl		# sprawdzanie czy doszlismy juz do \n
	jbe endConvertBuffer	# jesli tak to koniec
	imull $10, %eax 	# jesli nie to mnozymy np 19*10=190 i pozniej znow dodajemy znak

	jmp startConvertBuffer	# przeskakujemy 

errorConvertBuffer:
	movl $0, %eax		# eax zwraca 0 jesli blad

endConvertBuffer:
	movl %ebp, %esp		
	popl %ebp  
	ret


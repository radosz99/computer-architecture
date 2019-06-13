.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.section .bss
.equ BYTES, 1024
.equ BYTES_2, 2048
.equ LENGTH, 4
.equ BYTE, 1
.lcomm number_1, BYTES
.lcomm number_2, BYTES
.lcomm base, LENGTH
.lcomm answer_1, LENGTH

.lcomm lengthNumber_1, LENGTH
.lcomm lengthNumber_2, LENGTH
.lcomm lengthNumber, LENGTH
.lcomm result, BYTES_2
.lcomm carry, BYTE

.section .data
    size: .long 0
    sizeCounter: .long 0

	message0:
	.ascii "\nIn which system would you want to execute the operation\n(b - bin, d - dec, h - hex): \0"
	mes0_len = .-message0

	message1:
	.ascii "\nFirst number: \0"
	mes1_len = .-message1

	message2:
	.ascii "Second number: \0"
	mes2_len = .-message2

	answer:
	.ascii "\nSum: \0"
	answer_len = .-answer

	fault0:
	.ascii "\nGive the correct value!\n\0"
	fault0_len = .-fault0

.section .text
.globl _start

_start:

askBase:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $message0, %ecx
	movl $mes0_len, %edx
	int $LINUX_SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $base, %ecx
	movl $BYTES, %edx
	int $LINUX_SYSCALL

	orl %ebx, %ebx		# zerowanie %ebx
	movb base, %bl
	cmpb $0x62, %bl
	je binary
	cmpb $0x64, %bl		
	je decimal
	cmpb $0x68, %bl		
	je hexadecimal

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $fault0, %ecx
	movl $fault0_len, %edx
	int $LINUX_SYSCALL
	jmp askBase

binary:
	movl $2, %eax
	movl %eax, base
	jmp askFirstNumber

decimal:
    movl $10, %eax
	movl %eax, base
	jmp askFirstNumber

hexadecimal:
	movl $0x10, %eax
	movl %eax, base

askFirstNumber:
    xorl %edi, %edi
    movb $0, result(,%edi,1)
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $message1, %ecx
	movl $mes1_len, %edx
	int $LINUX_SYSCALL
	
	movl $READ, %eax
	movl $STDIN, %ebx
	movl $number_1, %ecx
	movl $BYTES, %edx
	int $LINUX_SYSCALL

	decl %eax
	decl %eax
	movl %eax, lengthNumber_1 # dlugosc liczby 1 bez entera i \0

askSecondNumber:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $message2, %ecx
	movl $mes2_len, %edx
	int $LINUX_SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $number_2, %ecx
	movl $BYTES, %edx
	int $LINUX_SYSCALL

	decl %eax
	decl %eax
	movl %eax, lengthNumber_2

designateLoopLenght:
	movb $0, carry	# zerujemy ewentualne przeniesienie
	movl lengthNumber_1, %edi	
	cmpl lengthNumber_2, %edi
	jg prepareResult2
	movl lengthNumber_2, %edi # wyznaczona ilosc petli 
	movl %edi, lengthNumber # dlugosc wyniku
    movl %edi, size

prepareResult2:
	incl %edi	# jesli dodawanie to nalezy powiekszyc o 1, gdyz z n+x (gdzie x<n) moze powstac n+1

calculatorBegin:

    xorl %edx, %edx
	movl lengthNumber_1, %edx	# pobierz dlugosc pierwszej liczby do rejestru
	cmpl $0, %edx
	jl firstNumberEnd
	xorl %ebx, %ebx	# wyzeruj ebx
	decl lengthNumber_1		# dekrementacja dlugosci liczby by wczytac kolejna cyfre w nowej petli
	movb number_1(,%edx,1), %bl # pobieranie znaku do ebx

	pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
	cmpb base, %al # niepoprawne wartosci
	jge askFirstNumber # powrot do pytan o liczby

	jmp calculatorContinue

firstNumberEnd:
	xorl %eax, %eax	# przejscie po calej pierwszej liczbie

calculatorContinue:
	xorl %ebx, %ebx	
    xorl %edx, %edx
	movl lengthNumber_2, %edx	# pobierz dlugosc drugiej liczby do rejestru
	cmpl $0, %edx	
	jl secondNumberEnd	
	decl lengthNumber_2		
	movb number_2(,%edx,1), %bl # pobieranie znaku do ebx

	pushl %eax		# cyfre z pierwszej liczby wrzucamy na stos

	pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
	cmpb base, %al
	jge askFirstNumber
	
	movl %eax, %ebx	# w ebx mamy teraz cyfre z drugiej liczby
	popl %eax		# przywracamy cyfre z pierwszej liczby

secondNumberEnd:
	cmpl $0, lengthNumber_1
	jge adderBegin
	cmpl $0, lengthNumber_2
	jge adderBegin
	cmpl $0, %eax   # dlugosc zostanie najpierw wyzerowana ale wartosci jeszcze beda
	jne adderBegin
	cmpl $0, %ebx
	jne adderBegin
	cmpl $1, carry
	je adderBegin
	jmp calculatorEnd

adderBegin:
	addl %ebx, %eax	# dodajemy wartosci rejestrow
	addl carry, %eax # dodajemy ewentualne przeniesienie
	movb $0, carry # zerujemy przeniesienie
	cmpl base, %eax	# 
	jb savingResult

	subl base, %eax #jezeli wynik jest wiekszy od podstawy to odejmujemy podstawe...
	movb $1, carry # ... i aktywujemy przeniesienie
	jmp savingResult

savingResult:
	pushl %eax
	call intToChar
	addl $4, %esp

	movb %al, result(,%edi,1) #zapisujemy wynik do result
	decl %edi # i dekrementujemy nasz rejestr przechodzacy po result

	jmp calculatorBegin

calculatorEnd:

    call findInitialZeros

adderAnswer:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $answer, %ecx # wyswietlamy sum
	movl $answer_len, %edx
	int $LINUX_SYSCALL

outcome:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $result, %ecx
	movl $BYTES_2, %edx
	int $LINUX_SYSCALL

end:
    jmp askFirstNumber
    movl $EXIT, %eax
	movl $0, %ebx
	int $LINUX_SYSCALL

.type charToInt,@function
charToInt:
	pushl %ebp
	movl %esp, %ebp

	xorl %ebx, %ebx		# zeruj ebx
	movl 8(%ebp), %ebx  # wrzucamy znak do ebx
	subb $0x30, %bl		# odejmij wartosc znaku '0' od znaku, zostaje cyfra
	cmpb $10, %bl		# jezeli cyfra mniejsza od 10, przejdz na koniec
	jb charToIntEnd

	subb $0x7, %bl      # mogla zostac podana duza litera, np A
	cmpb $0x10, %bl	    # jesli mniejsza to przeskakujemy dalej
	jb charToIntEnd

	subb $0x20, %bl     # podana zostala mala litera, np a

charToIntEnd:
	movl %ebx, %eax		# powiodla sie konwersja, przepisz ebx do eax
	movl %ebp, %esp
	popl %ebp
	ret

.type intToChar,@function
intToChar:
	pushl %ebp
	movl %esp, %ebp

	movl 8(%ebp), %eax
	addb $0x30, %al
	cmpb $0x39, %al	# wartosc mniejsza lub rowna '9'
	jbe intToCharEnd

	addb $7, %al # dla heksadecymalnego

intToCharEnd:
	movl %ebp, %esp
	popl %ebp
	ret

.type findInitialZeros,@function
findInitialZeros:
    xorl %edx, %edx
    xorl %eax, %eax
    xorl %ecx, %ecx
    movl size, %eax
    movl %eax, sizeCounter
    addl $3, sizeCounter
    xorl %eax, %eax

findInitialZerosBegin:
    movl $0, %edx #indeksowanie od zera, w mnozeniu od 1
    decl sizeCounter
    movb result(,%edx,1), %al
    incl %edx
    cmpl $'0', %eax
    je deleteInitialZeros
    jmp findInitialZerosEnd
    
deleteInitialZeros:
    xorl %eax, %eax
    movb result(,%edx,1), %al
    decl %edx
    movb %al, result(,%edx,1)
    addl $2, %edx
    cmpl sizeCounter, %edx
    jle deleteInitialZeros

deleteRedundand:
    decl %edx
    movl $0, result(,%edx,1)
    jmp findInitialZerosBegin

findInitialZerosEnd:
    #movl %ebp, %esp
	#popl %ebp
	ret


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
.equ LBUFOR, 12
.lcomm bufor, LBUFOR
.lcomm number_1, BYTES
.lcomm number, BYTES
.lcomm licznik, BYTES
.lcomm base, LENGTH
.lcomm answer_1, LENGTH
.lcomm lengthNumber1, LENGTH
.lcomm positionNumber, LENGTH
.lcomm result, BYTES_2
.lcomm tempResult, BYTES_2
.lcomm carry, BYTE
.lcomm finalCarry, BYTE

.section .data
    size: .long 128
    elasticSize: .long 0
    sizeCounter: .long 0
    sizeResult: .long 0
    sizeTempResult: .long 0
    positionNumber_1: .long 0
    positionResult: .long 0
    digit: .long 0
    counter: .long 4
    accuracyCounter: .long 0
    
	message0:
	.ascii "In which system would you want to execute the operation\n(b - bin, d - dec, h - hex): \0"
	mes0_len = .-message0

	message1:
	.ascii "\nNumber: \0"
	mes1_len = .-message1

	message2:
	.ascii "How many digits after ','?: \0"
	mes2_len = .-message2
	
	answer:
	.ascii "\nSquare root: \0"
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
	movl %eax, lengthNumber1 # dlugosc liczby 1 bez entera i \0
   
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $message2, %ecx
    movl $mes2_len, %edx
    int $LINUX_SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $bufor, %ecx
	movl $LBUFOR, %edx
	int $LINUX_SYSCALL

	pushl $bufor
	call convertBuffer
	addl $4, %esp

	movl %eax, accuracyCounter
    movl lengthNumber1, %eax

addZeroIfOdd:
    incl %eax
    xorl %edx, %edx
    xorl %ecx, %ecx
    movl $2, %ecx
    idivl %ecx

    cmpl $0, %edx
    je setAccuracy
    movl lengthNumber1, %edi

addZeroIfOddBegin:
    movb number_1(,%edi,1), %bl
	incl %edi
	movb %bl, number_1(,%edi,1) # cr
    subl $2, %edi
    cmpl $0, %edi
    jl addZeroIfOddEnd
    jmp addZeroIfOddBegin

addZeroIfOddEnd:
    incl %edi
    movb $'0', number_1(,%edi,1)
    incl lengthNumber1  
    xorl %eax, %eax

setAccuracy:
    movl lengthNumber1, %eax
    xorl %edx, %edx
    xorl %ebx, %ebx
    movl accuracyCounter, %edx
    movl accuracyCounter, %ebx
    imull $2, %ebx
    addl %ebx, lengthNumber1

setAccuracyBegin:
    incl %eax
    cmpl $0, %edx
    jle setAccuracyEnd
    movl $'0', number_1(,%eax,1)
    incl %eax
    movl $'0', number_1(,%eax,1)
    decl %edx
    jmp setAccuracyBegin

setAccuracyEnd:

	movb $0xA, number_1(,%eax,1) # lf
	incl %eax
	movb $0xD, number_1(,%eax,1) # cr
  
    movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $number_1, %ecx
	movl $BYTES_2, %edx
    int $LINUX_SYSCALL
    
prepareResult: 
    movl $0, %edi
    movl $'0', result(,%edi,1)
    incl %edi
	movb $0xA, result(,%edi,1) # lf
	incl %edi
	movb $0xD, result(,%edi,1) # cr

    movl $0, positionNumber
    
loadTwoDigits:
    xorl %eax, %eax
    movl lengthNumber1, %eax
    cmpl %eax, positionNumber_1
    jg END
    xorl %edx, %edx
    xorl %edi, %edi
    movl positionNumber_1, %edx
    movl positionNumber, %edi
    
loadTwoDigitsBegin:
    xorl %eax, %eax
    movb number_1(, %edx,1), %al
    xorl %ebx, %ebx
    movb number(,%edi,1), %bl
    movl $0, number(,%edi,1)
    movb %al, number(,%edi,1)
    incl %edx
    incl %edi
    xorl %eax, %eax
    movb number_1(, %edx,1), %al
    movl $0, number(,%edi,1)
    movb %al, number(,%edi,1)
    incl %edi
	movb $0xA, number(,%edi,1) # lf
	incl %edi
	movb $0xD, number(,%edi,1) # cr
    addl $2, positionNumber_1
    movl %edi, positionNumber
    subl $1, positionNumber
    xorl %eax, %eax
    movl base, %eax
    movl %eax, digit

    movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $number, %ecx
	movl $BYTES_2, %edx
	int $LINUX_SYSCALL

prepareTempResult:
    decl digit
    xorl %eax, %eax
    xorl %ecx, %ecx
    xorl %ebx, %ebx
    xorl %edx, %edx
    movl sizeResult, %ebx
    addl $2, %ebx

prepareTempResultBegin:
    xorl %edi, %edi
    xorl %edx, %edx
    movl counter, %edx
    incl counter
    movl $'0', tempResult(,%edi, 1)

reset:
    cmpl $0, %edx
    jl drift

    incl %edi
    decl %edx
    movl $'0', tempResult(,%edi, 1)
    jmp reset

drift:
    incl %edi
    movb result(,%ecx,1), %al
    movb %al, tempResult(,%edi,1)
    incl %ecx
    cmpl %ecx, %ebx
    jge drift

    movl %edi, sizeTempResult
    subl $2, sizeTempResult

prepareTempResultMulti:
    xorl %edi, %edi
    movl sizeTempResult, %edi

prepareTempResultMultiBegin:
    movb tempResult(,%edi,1), %bl
    pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp

    imull $2, %eax
    addl carry, %eax
    movl $0, carry
    cmpl base, %eax
    jge prepareTempResultMultiOverflow

    pushl %eax
	call intToChar
	addl $4, %esp
    movb %al, tempResult(,%edi,1)
    decl %edi

    jmp prepareTempResultMultiEnd

prepareTempResultMultiOverflow:
    subl base, %eax

    pushl %eax
	call intToChar
	addl $4, %esp

    movb %al, tempResult(,%edi,1)
    movl $1, carry
    decl %edi

    jmp prepareTempResultMultiBegin
    
prepareTempResultMultiEnd:
    cmpl $0, %edi
    jl prepareTempResultMultiEndEnd

    jmp prepareTempResultMultiBegin

prepareTempResultMultiEndEnd:
    xorl %edi, %edi
    movl sizeTempResult, %edi
    addl $1, %edi
    incl sizeTempResult
    movl $'0', tempResult(,%edi,1)
    incl %edi
    movb $0xA, tempResult(,%edi,1) # lf
	incl %edi
	movb $0xD, tempResult(,%edi,1) # cr
    
    xorl %eax, %eax
    xorl %ecx, %ecx
    xorl %ebx, %ebx
    xorl %edx, %edx

prepareTempResultAddBegin:
    movl digit, %ebx
    pushl %ebx
	call intToChar
	addl $4, %esp
    movl sizeTempResult, %edi
    movb %al, tempResult(,%edi,1)
    movl $0, carry
    xorl %edi, %edi
    movl sizeTempResult, %edi

prepareTempResultAddMulti:
    movb tempResult(,%edi,1), %bl
    pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
    
    imull digit, %eax
    addl carry, %eax
    movl $0, carry
    cmpl base, %eax
    jge prepareTempResultAddMultiOverflow
    
    pushl %eax
	call intToChar
	addl $4, %esp
    movb %al, tempResult(,%edi,1)
    decl %edi

    jmp prepareTempResultAddMultiEnd

prepareTempResultAddMultiOverflow:
    subl base, %eax
    incl carry
    cmpl base, %eax
    jge prepareTempResultAddMultiOverflow
    
    pushl %eax
	call intToChar
	addl $4, %esp

    movb %al, tempResult(,%edi,1)
    decl %edi

prepareTempResultAddMultiEnd:
    cmpl $0, %edi
    jl prepareTempResultAddMultiEndEnd
    jmp prepareTempResultAddMulti

prepareTempResultAddMultiEndEnd:
    call findInitialZeros
    
checkIfHigher:
    xorl %eax, %eax
    xorl %ebx, %ebx
    xorl %ecx, %ecx
    movl $0, %edx
    movl positionNumber, %ecx

checkIfHigherBegin:
    cmpl %edx, %ecx
    jg checkIfHigherBegin2
    jmp subtractor

checkIfHigherBegin2:
    xorl %ebx, %ebx
    movb number(,%edx,1), %bl
    pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
    
    movb tempResult(,%edx,1), %bl
    pushl %eax
    pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
	
	movl %eax, %ebx	# w ebx mamy teraz cyfre z drugiej liczby
	popl %eax		# przywracamy cyfre z pierwszej liczby

    incl %edx

    cmpl %eax, %ebx
    je checkIfHigherBegin
    cmpl %eax, %ebx
    jg prepareTempResult
    
subtractor:
    movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $tempResult, %ecx
	movl $BYTES_2, %edx
	int $LINUX_SYSCALL

    xorl %eax, %eax
    xorl %ecx, %ecx
    xorl %ebx, %ebx
    xorl %edx, %edx 

    movl $0, carry
    xorl %edx, %edx
    movl sizeTempResult, %edx

subtractorBegin:
    cmpl $0, %edx
    jl subtractorEnd
    movb number(,%edx,1), %bl
    pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
    
    movb tempResult(,%edx,1), %bl
    pushl %eax
    pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp

	movl %eax, %ebx	# w ebx mamy teraz cyfre z drugiej liczby
	popl %eax		# przywracamy cyfre z pierwszej liczby

    subl %ebx, %eax
    subl carry, %eax
    movl $0, carry
    cmpl $0, %eax
    jl subtractorOverflow

    pushl %eax
	call intToChar
	addl $4, %esp
    movb %al, number(,%edx,1)
    decl %edx
    jmp subtractorBegin

subtractorOverflow:
    addl base, %eax
    movl $1, carry

    pushl %eax
	call intToChar
	addl $4, %esp
    movb %al, number(,%edx,1)
    decl %edx
    jmp subtractorBegin

subtractorEnd:
    xorl %eax, %eax
    movl digit, %eax
    pushl %eax
	call intToChar
	addl $4, %esp
   
    xorl %edi, %edi
    xorl %ebx, %ebx
    movl positionResult, %edi
    incl positionResult
    movb result(,%edi,1), %bl
    cmpl $48, %ebx
    jne addToResult

    movb %al, result(,%edi,1)
    jmp loadTwoDigits
    
addToResult:
    incl sizeResult
    movb %al, result(,%edi,1)
    incl %edi
    movb $0xA, result(,%edi,1) # lf
	incl %edi
	movb $0xD, result(,%edi,1) # cr


    jmp loadTwoDigits
   
END:
    xorl %edi, %edi
    xorl %edx, %edx
    xorl %ecx, %ecx
    movl sizeResult, %edi   
    movl %edi, %ecx 
    subl accuracyCounter, %ecx
    addl $2, %edi
    movl %edi, %edx
    incl %edx

    cmpl $0, accuracyCounter
    jle theEND

ENDING:
    xorl %ebx, %ebx
    movb result(,%edi,1), %bl
    movb %bl, result(,%edx,1)
    decl %edi
    decl %edx
    cmpl %edi, %ecx
    jl ENDING
    movb $44, result(,%edx,1) #montujemy przecinek

theEND:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $answer, %ecx
	movl $answer_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $result, %ecx
	movl $BYTES_2, %edx
	int $LINUX_SYSCALL

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
    movl sizeTempResult, %eax
    movl %eax, sizeCounter
    addl $3, sizeCounter
    xorl %eax, %eax

findInitialZerosBegin:
    movl $0, %edx #indeksowanie od zera, w mnozeniu od 1
    
    movb tempResult(,%edx,1), %al
    incl %edx

    xorl %ebx, %ebx
    movl positionNumber, %ebx
    decl %ebx
    cmpl %ebx, sizeTempResult
    je findInitialZerosEnd

    cmpl $'0', %eax
    je deleteInitialZerosBegin
    jmp findInitialZerosEnd

deleteInitialZerosBegin:
    decl sizeCounter
    decl sizeTempResult

deleteInitialZeros:
    xorl %eax, %eax
    movb tempResult(,%edx,1), %al
    decl %edx
    movb %al, tempResult(,%edx,1)
    addl $2, %edx
    cmpl sizeCounter, %edx
    jle deleteInitialZeros

deleteRedundand:
    decl %edx
    movl $0, tempResult(,%edx,1)
    jmp findInitialZerosBegin

findInitialZerosEnd:
    #movl %ebp, %esp
	#popl %ebp
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


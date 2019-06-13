.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.section .bss

.equ BYTES, 1024
.equ BYTES_2, 2048
.equ LENGTH2, 32
.equ LENGTH, 4
.equ BYTE, 1
.lcomm licznik, BYTES
.lcomm base, LENGTH
.lcomm baseForCalc, LENGTH
.lcomm limit, LENGTH
.lcomm limit1, LENGTH
.lcomm answer_1, LENGTH
.lcomm firstNumberCurrentValue, LENGTH
.lcomm number, BYTES
.lcomm exponentResult, BYTES
.lcomm fractionResult, BYTES
.lcomm stringValueFraction, BYTES
.lcomm lengthNumber1, LENGTH
.lcomm lengthNumber2, LENGTH
.lcomm lengthNumber2_2, LENGTH
.lcomm result, BYTES_2
.lcomm finalResult, BYTES
.lcomm finalResultMantysas, BYTES_2
.lcomm carry, BYTE
.lcomm finalCarry, BYTE
.lcomm roundingBits, BYTES

.section .data
    size: .long 256
    elasticSize: .long 0
    sizeCounter: .long 0
    whichIsBigger: .long 0
    movingCounter: .long 0
    sizeOfMantysa: .long 23
    sizeOfExponent: .long 8
    valueExponent: .long 0 # wartosc wykladnika liczby 1
    valueFraction: .long 0 # wartosc mantysy liczby 1

    signResult: .long 0
    operation: .long 0

    messageNumber1:
    .ascii "\nNumber: \0"
    messageNumber1_len = .-messageNumber1

    messageRoundingBits:
    .ascii "Rounding bits: \0"
    messageRoundingBits_len = .-messageRoundingBits

	message1:
	.ascii "\nNumber: \0"
	mes1_len = .-message1

	answer:
	.ascii "\nValue: \0"
	answer_len = .-answer

	fault0:
	.ascii "\nGive the correct value!\n\0"
	fault0_len = .-fault0

.section .text
.globl _start

_start:

    movl $2, base
    movl $10, baseForCalc
    movl size, %eax
    movl %eax, elasticSize
    xorl %eax, %eax

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $message1, %ecx
    movl $mes1_len, %edx
    int $LINUX_SYSCALL
 
    movl $READ, %eax
    movl $STDIN, %ebx
    movl $number, %ecx
    movl $BYTES, %edx
    int $LINUX_SYSCALL
 
    movl sizeOfMantysa, %ecx
    subl %ecx, %eax
    cmpl $10, %eax
    je correctValue1
 
incorrectValue1:    
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $fault0, %ecx
    movl $fault0_len, %edx
    int $LINUX_SYSCALL
    jmp _start
   
correctValue1:
    xorl %edi, %edi
    movb number(,%edi,1), %al
    incl %edi
    cmpb $48, %al
    je setNumber_1_0
    cmpb $49, %al
    je setNumber_1_1
    jmp incorrectValue1
 
setNumber_1_0:
    jmp convertExponent_1
 
setNumber_1_1:
    movl $1, signResult
 
convertExponent_1:
    xorl %edx, %edx
    xorl %eax, %eax
 
convertExponent_1Begin:
    movb number(,%edi,1), %al
    movb %al, exponentResult(,%edx,1)
    incl %edx
    incl %edi
    cmpl $8, %edx
    jb convertExponent_1Begin
    movb $0xA, exponentResult(,%edx,1) # lf
    incl %edx
    movb $0xD, exponentResult(,%edx,1) # cr
    xorl %edx, %edx
 
    pushl $2
    pushl $exponentResult
    call convertBuffer
    addl $8, %esp
    subl $127, %eax
    movl %eax, valueExponent
    xorl %edx, %edx

    movb $49, fractionResult(,%edx,1) #ukryty bicik
    incl %edx
 
convertFraction1:
    movb number(,%edi,1), %al
    movb %al, fractionResult(,%edx,1)
    incl %edx
    incl %edi
    xorl %ecx, %ecx
    movl sizeOfMantysa, %ecx
    cmpl %ecx, %edx #ile jest cyfr mantysy
    jbe convertFraction1
    movb $0xA, fractionResult(,%edx,1) # lf
    incl %edx
    movb $0xD, fractionResult(,%edx,1) # cr
 
    pushl $2
    pushl $fractionResult
    call convertBuffer
    addl $8, %esp
    movl %eax, valueFraction
 
    pushl $number
    call makingResultNumber
    addl $4, %esp

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $messageNumber1, %ecx
    movl $messageNumber1_len, %edx
    int $LINUX_SYSCALL
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $number, %ecx
    movl $BYTES, %edx
    int $LINUX_SYSCALL

calculating:
    call valueFractionToString

    xorl %eax, %eax
    xorl %ebx, %ebx
    movl valueExponent, %eax
    movl sizeOfMantysa, %ebx
    cmpl %eax, %ebx
    jge minus
    
    subl %ebx, %eax
    movl %eax, movingCounter
    call exponentHigher
    call findInitialZeros
    jmp display

minus:
    movb $1, operation
    subl %eax, %ebx
    movl %ebx, movingCounter
    call exponentLower
    call findInitialZeros
    call movePoint

display:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $answer, %ecx # wyswietlamy sum
	movl $answer_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $stringValueFraction, %ecx
	movl $BYTES, %edx
	int $LINUX_SYSCALL
    

    pushl signResult
    call showResult
    addl $4, %esp

end:
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
    xorl %eax, %eax
    movl size, %eax
    xorl %ebx, %ebx
	movl operation, %ebx
    movl %eax, sizeCounter
    addl $3, sizeCounter
   

findInitialZerosBegin:
    xorl %eax, %eax
    xorl %edx, %edx
    movl $1, %edx
    decl sizeCounter
    movb stringValueFraction(,%edx,1), %al
    incl %edx
    cmpl $'0', %eax
    je deleteInitialZeros
    jmp moveSign
    
deleteInitialZeros:
    xorl %eax, %eax
    movb stringValueFraction(,%edx,1), %al
    decl %edx
    movb %al, stringValueFraction(,%edx,1)
    addl $2, %edx
    cmpl sizeCounter, %edx
    jle deleteInitialZeros

deleteRedundand:
    decl %edx
    movl $0, stringValueFraction(,%edx,1)
    cmpl $1, %ebx
    jne forHigher

    subl $4, %edx #na znak konca i 0 jeszcze, znajdujemy sie za cr
    cmpl movingCounter, %edx
    jg findInitialZerosBegin
    jmp moveSign 

forHigher:
    jmp findInitialZerosBegin

moveSign:
    xorl %edx, %edx
    cmpl $0, signResult
    je movePlus
    movb $45, stringValueFraction(,%edx,1)
    jmp findInitialZerosEnd

movePlus:
    movb $43, stringValueFraction(,%edx,1)

findInitialZerosEnd:
	ret

.type convertBuffer, @function
convertBuffer:
    pushl %ebp
    movl %esp, %ebp
    movl $0, %eax
    movl 8(%ebp), %ecx  #pod 8(%ebp) mamy ciag znakow z bufora
    xorl %ebx, %ebx
    movb (%ecx), %bl
    cmpb $0x20, %bl     # jesli nie zostaly wpisane cyfry przeskakujemy do bledu
    jbe errorConvertBuffer
 
startConvertBuffer:
    subb $0x30, %bl     # ascii --> cyfra
    addl %ebx, %eax     # dodawanie cyfry do dotychczasowej liczby
    incl %ecx       # inkrementacja ecx by uzyskac nastepny znak z bufora
    xorl %ebx, %ebx     # zerowanie ebx
    movb (%ecx), %bl    # pobieranie znaku (indirect addressing type)
 
    cmpb $0x20, %bl     # sprawdzanie czy doszlismy juz do \n
    jbe endConvertBuffer    # jesli tak to koniec
    imull 12(%ebp), %eax    # jesli nie to mnozymy np 19*10=190 i pozniej znow dodajemy znak
 
    jmp startConvertBuffer  # przeskakujemy
 
errorConvertBuffer:
    movl $0, %eax       # eax zwraca 0 jesli blad
 
endConvertBuffer:
    movl %ebp, %esp    
    popl %ebp  
    ret


.type makingResultNumber, @function
makingResultNumber:
    pushl %ebp
    movl %esp, %ebp
    xorl %edi, %edi
    movl 8(%ebp), %ecx  #pod 8(%ebp) mamy number_1 badz number_2
    addl sizeOfMantysa, %edi
    addl sizeOfExponent, %edi
    addl $2, %edi #znaki konca
    addl %edi, %ecx

movingTwoTimes:
    xorl %ebx, %ebx
    movb (%ecx), %bl
    addl $2, %ecx
    movb %bl, (%ecx)
    subl $3, %ecx
    decl %edi
    cmpl sizeOfExponent, %edi
    jg movingTwoTimes

    addl $2, %ecx
    movb $124, (%ecx)
    subl $2, %ecx

movingOneTime:
    xorl %ebx, %ebx
    movb (%ecx), %bl
    addl $1, %ecx
    movb %bl, (%ecx)
    subl $2, %ecx
    decl %edi
    cmpl $0, %edi
    jg movingOneTime

    addl $1, %ecx
    movb $124, (%ecx)
    subl $1, %ecx

endMakingResultNumber:
    movl %ebp, %esp
    popl %ebp
    ret

.type showResult, @function
showResult:
    pushl %ebp
    movl %esp, %ebp
    xorl %edi, %edi
   
joinSign:
    movl 8(%ebp), %ebx
    addl $48, %ebx
    movb %bl, finalResult(,%edi,1)
    incl %edi
    movb $124, finalResult(,%edi,1)
    incl %edi
    xorl %esi, %esi # licznik dla wykladnika
    movl sizeOfExponent, %ecx
 
joinExponent:
    xorl %ebx, %ebx
    movb exponentResult (,%esi,1), %bl
    movb %bl, finalResult(,%edi,1)
    incl %esi
    incl %edi
    cmpl %ecx, %esi
    jl joinExponent
    movb $124, finalResult(,%edi,1)
    incl %edi
    xorl %esi, %esi
    movl sizeOfMantysa, %ecx
   
joinFraction:
    xorl %ebx, %ebx
    movb fractionResult (,%esi,1), %bl
    movb %bl, finalResult(,%edi,1)
    incl %esi
    incl %edi
    cmpl %ecx, %esi
    jl joinFraction
 
    movb $0xA, finalResult(,%edi,1) # lf
    incl %edi
    movb $0xD, finalResult(,%edi,1) # cr
 
endShowResult:
    movl %ebp, %esp    
    popl %ebp  
    ret

.type valueFractionToString, @function
valueFractionToString:
    pushl %ebp
    movl %esp, %ebp
    xorl %ecx, %ecx
    xorl %esi, %esi
    movl size, %esi
    incl %esi
    movl $10, %ecx

    movb $0xA, stringValueFraction(,%esi,1)
    incl %esi
    movb $0xD, stringValueFraction(,%esi,1)
    decl %esi
    decl %esi    

conversion:
    xorl %eax, %eax
    xorl %edx, %edx

    movl valueFraction, %eax
    idiv %ecx
    movl $0, valueFraction
    movl %eax, valueFraction
    addl $48, %edx #int to char
    movb %dl, stringValueFraction(,%esi,1)
    decl %esi
    cmpl $0, %eax
    jne conversion

addZeros:
    movb $'0', stringValueFraction(,%esi,1)
    decl %esi
    cmpl $0, %esi
    jge addZeros   

endValueFractionToString:
    movl %ebp, %esp    
    popl %ebp  
    ret


.type exponentHigher, @function
exponentHigher:
    pushl %ebp
    movl %esp, %ebp
    movl movingCounter, %edi

startExponentHigher:
    movl $0, carry
    xorl %esi, %esi
    movl size, %esi

multi:
    xorl %ebx, %ebx
    movb stringValueFraction(,%esi,1), %bl
    subl $48, %ebx
    imull $2, %ebx
    addl carry, %ebx
    movl $0, carry
    cmpl baseForCalc, %ebx
    jl saving

overflow:
    subl baseForCalc, %ebx
    incl carry
    cmpl baseForCalc, %ebx
    jge overflow
    
saving:
    addl $48, %ebx
    movb %bl, stringValueFraction(,%esi,1)
    decl %esi
    cmpl $0, %esi
    jge multi

    decl %edi
    cmpl $0, %edi
    jg startExponentHigher

endExponentHigher:
    movl %ebp, %esp    
    popl %ebp  
    ret


.type exponentLower, @function
exponentLower:
    pushl %ebp
    movl %esp, %ebp
    movl movingCounter, %edi

startExponentLower:
    movl $0, carry
    xorl %esi, %esi
    movl size, %esi

multi1:
    xorl %ebx, %ebx
    movb stringValueFraction(,%esi,1), %bl
    subl $48, %ebx
    imull $5, %ebx
    addl carry, %ebx
    movl $0, carry
    cmpl baseForCalc, %ebx
    jl saving1

overflow1:
    subl baseForCalc, %ebx
    incl carry
    cmpl baseForCalc, %ebx
    jge overflow1
    
saving1:
    addl $48, %ebx
    movb %bl, stringValueFraction(,%esi,1)
    decl %esi
    cmpl $0, %esi
    jge multi1

    decl %edi
    cmpl $0, %edi
    jg startExponentLower

endExponentLower:
    movl %ebp, %esp    
    popl %ebp  
    ret


.type movePoint, @function
movePoint:
    pushl %ebp
    movl %esp, %ebp
    xorl %edx, %edx
    movl movingCounter, %edx 
    addl $3, %edx #zeby znalezc sie na indeksie gdzie jest 0xD

movingFraction:
    xorl %ebx, %ebx
    movb stringValueFraction(,%edx,1), %bl
    incl %edx
    movb %bl, stringValueFraction(,%edx,1)
    subl $2, %edx
    cmpl $1, %edx #zostawiamy znak i cyfre jednosci czyli indeksy 0 i 1
    jne movingFraction
    
    incl %edx
    movb $46, stringValueFraction(,%edx,1)


endMovePoint:
    movl %ebp, %esp    
    popl %ebp  
    ret



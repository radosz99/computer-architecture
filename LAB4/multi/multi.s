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
.lcomm licznik, BYTES
.lcomm base, LENGTH
.lcomm limit, LENGTH
.lcomm limit1, LENGTH
.lcomm answer_1, LENGTH
.lcomm firstNumberCurrentValue, LENGTH
.lcomm number_1, BYTES
.lcomm number_2, BYTES
.lcomm exponent_1, BYTES
.lcomm exponent_2, BYTES
.lcomm exponentResult, BYTES
.lcomm fractionResult, BYTES
.lcomm fraction_1, BYTES
.lcomm fraction_2, BYTES
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
    size: .long 0
    elasticSize: .long 0
    sizeCounter: .long 0
    whichIsBigger: .long 0
    movingCounter: .long 0
    sizeOfMantysa: .long 23
    sizeOfExponent: .long 8
    valueExponent_1: .long 0 # wartosc wykladnika liczby 1
    valueExponent_2: .long 0 # wartosc wykladnika liczby 2
    valueFraction_1: .long 0 # wartosc mantysy liczby 1
    valueFraction_2: .long 0 # wartosc mantysy liczby 2
    differenceOfExponents: .long 0 # roznica wykladnikow
   
    sign_1: .byte 0
    sign_2: .byte 0
    signResult: .byte 0

    messageNumber1:
    .ascii "\n\n First: \0"
    messageNumber1_len = .-messageNumber1

    messageNumber2:
    .ascii "Second: \0"
    messageNumber2_len = .-messageNumber2

    messageRoundingBits:
    .ascii "Rounding bits: \0"
    messageRoundingBits_len = .-messageRoundingBits

	message1:
	.ascii "\nFirst number: \0"
	mes1_len = .-message1

	message2:
	.ascii "Second number: \0"
	mes2_len = .-message2
   
	answer:
	.ascii "\nProduct: \0"
	answer_len = .-answer

	fault0:
	.ascii "\nGive the correct value!\n\0"
	fault0_len = .-fault0

	faultNadmiar:
	.ascii "\nWystapil nadmiar!\n\n\0"
	faultNadmiar_len = .-faultNadmiar

	faultNiedomiar:
	.ascii "\nWystapil niedomiar!\n\n\0"
	faultNiedomiar_len = .-faultNiedomiar

.section .text
.globl _start

_start:
    movl sizeOfMantysa, %eax
    imull $2, %eax
    incl %eax
    incl %eax #indeksowanie w size od 1 dlatego tak
    movl %eax, size

    movl $127, limit
    movl $-127, limit1
    movl $2, base
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
    movl $number_1, %ecx
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
    movb number_1(,%edi,1), %al
    incl %edi
    cmpb $48, %al
    je setNumber_1_0
    cmpb $49, %al
    je setNumber_1_1
    jmp incorrectValue1
 
setNumber_1_0:
    jmp convertExponent_1
 
setNumber_1_1:
    movl $1, sign_1
 
convertExponent_1:
    xorl %edx, %edx
    xorl %eax, %eax
 
convertExponent_1Begin:
    movb number_1(,%edi,1), %al
    movb %al, exponent_1(,%edx,1)
    incl %edx
    incl %edi
    cmpl $8, %edx
    jb convertExponent_1Begin
    movb $0xA, exponent_1(,%edx,1) # lf
    incl %edx
    movb $0xD, exponent_1(,%edx,1) # cr
    xorl %edx, %edx
 
    pushl $2
    pushl $exponent_1
    call convertBuffer
    addl $8, %esp
    movl %eax, valueExponent_1
    xorl %edx, %edx

    movb $49, fraction_1(,%edx,1) #ukryty bicik
    incl %edx
 
convertFraction1:
    movb number_1(,%edi,1), %al
    movb %al, fraction_1(,%edx,1)
    incl %edx
    incl %edi
    xorl %ecx, %ecx
    movl sizeOfMantysa, %ecx
    cmpl %ecx, %edx #ile jest cyfr mantysy
    jbe convertFraction1
    movb $0xA, fraction_1(,%edx,1) # lf
    incl %edx
    movb $0xD, fraction_1(,%edx,1) # cr
 
    pushl $2
    pushl $fraction_1
    call convertBuffer
    addl $8, %esp
    movl %eax, valueFraction_1
 
askForSecondNumber:
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
 
    movl sizeOfMantysa, %ecx
    subl %ecx, %eax
    cmpl $10, %eax
    je correctValue2
 
incorrectValue2:    
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $fault0, %ecx
    movl $fault0_len, %edx
    int $LINUX_SYSCALL
    jmp askForSecondNumber
   
correctValue2:
    xorl %edi, %edi
    movb number_2(,%edi,1), %al
    incl %edi
    cmpl $'0', %eax
    je setNumber_2_0
    cmpl $'1', %eax
    je setNumber_2_1
    jmp incorrectValue2
 
setNumber_2_0:
    movl $0, sign_2
    jmp convertExponent_2
 
setNumber_2_1:
    movl $1, sign_2
 
convertExponent_2:
    xorl %edx, %edx
    xorl %eax, %eax
 
convertExponent_2Begin:
    movb number_2(,%edi,1), %al
    movb %al, exponent_2(,%edx,1)
    incl %edx
    incl %edi
    cmpl $8, %edx
    jb convertExponent_2Begin
    movb $0xA, exponent_2(,%edx,1) # lf
    incl %edx
    movb $0xD, exponent_2(,%edx,1) # cr
    xorl %edx, %edx
 
    pushl $2
    pushl $exponent_2
    call convertBuffer
    addl $8, %esp
    movl %eax, valueExponent_2
    movb $49, fraction_2(,%edx,1) #ukryty bicik
    incl %edx
 
convertFraction2:
    movb number_2(,%edi,1), %al
    movb %al, fraction_2(,%edx,1)
    incl %edx
    incl %edi
    xorl %ecx, %ecx
    movl sizeOfMantysa, %ecx
    cmpl %ecx, %edx #ile jest cyfr mantysy
    jbe convertFraction2
    movb $0xA, fraction_2(,%edx,1) # lf
    incl %edx
    movb $0xD, fraction_2(,%edx,1) # cr
 
    pushl $2
    pushl $fraction_2
    call convertBuffer
    addl $8, %esp
    movl %eax, valueFraction_2
    
    subl $127, valueExponent_1
    subl $127, valueExponent_2

    xorl %edx, %edx
    addl valueExponent_1, %edx
    addl valueExponent_2, %edx
    cmpl limit, %edx
    jg faultNadmiar1
    cmpl limit1, %edx
    jl faultNiedomiar1
    jmp setValues

faultNadmiar1:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $faultNadmiar, %ecx
    movl $faultNadmiar_len, %edx
    int $LINUX_SYSCALL
    jmp _start

faultNiedomiar1:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $faultNiedomiar, %ecx
    movl $faultNiedomiar_len, %edx
    int $LINUX_SYSCALL
    jmp _start

setValues:
    xorl %edx, %edx
    movl sizeOfMantysa, %edx
    movl %edx, lengthNumber1
	movl %edx, lengthNumber2
    xorl %edx, %edx
    movl lengthNumber2, %edx
    movl %edx, lengthNumber2_2
    xorl %edx, %edx

    pushl $number_1
    call makingResultNumber
    addl $4, %esp

    pushl $number_2
    call makingResultNumber
    addl $4, %esp

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $messageNumber1, %ecx
    movl $messageNumber1_len, %edx
    int $LINUX_SYSCALL
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $number_1, %ecx
    movl $BYTES, %edx
    int $LINUX_SYSCALL

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $messageNumber2, %ecx
    movl $messageNumber2_len, %edx
    int $LINUX_SYSCALL
  
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $number_2, %ecx
    movl $BYTES, %edx
    int $LINUX_SYSCALL


setFinalResult:
    movl size, %edi
    addl $2, %edi
    movb $0xA, finalResultMantysas(,%edi,1) # lf
    decl %edi
    movb $0xD, finalResultMantysas(,%edi,1) # cr
	decl %edi

resetFinalResult:
    movb $0, finalResultMantysas(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jg resetFinalResult	

prepareResult: 
    cmpl $0, lengthNumber1
    jl outcome3
    xorl %edi, %edi
    movl size, %edi

resetResult: 
    movb $0, result(,%edi,1)
    decl %edi
    cmpl $0, %edi
    je afterResetResult
    jmp resetResult

afterResetResult:
    movl size, %edi
	xorl %ecx, %ecx 	
	incl %edi
	movb $0xA, result(,%edi,1) # lf
	incl %edi
	movb $0xD, result(,%edi,1) # cr
	decl %edi	
	decl %edi # wpisywanie bedziemy zaczynac od 3 pozycji od konca
    movl size, %ecx
    subl elasticSize, %ecx
    decl elasticSize

loop:
    cmpl $0, %ecx
    je calculatorBegin
    movb $0, result(,%edi,1)
    decl %edi
    decl %ecx
    jmp loop
    
calculatorBegin:
    xorl %ecx, %ecx
    xorl %edx, %edx
 

    movl $0, firstNumberCurrentValue
	movl lengthNumber1, %edx	# pobierz dlugosc pierwszej liczby do rejestru
	cmpl $0, %edx
	jl firstNumberEnd
	xorl %ebx, %ebx	# wyzeruj ebx
	decl lengthNumber1		# dekrementacja dlugosci liczby by wczytac kolejna cyfre w nowej petli
	movb fraction_1(,%edx,1), %bl # pobieranie znaku do ebx


	pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp    
    movl %eax, firstNumberCurrentValue
	jmp calculatorCont

firstNumberEnd:
	xorl %eax, %eax	# przejscie po calej pierwszej liczbie
    movl %eax, firstNumberCurrentValue
    
calculatorCont:
    movl lengthNumber2_2, %edx
    movl %edx, lengthNumber2  
  
calculatorContinue:
	xorl %eax, %eax	
	movl lengthNumber2, %edx	# pobierz dlugosc drugiej liczby do rejestru
	cmpl $0, %edx	
	jl secondNumberEnd	
	decl lengthNumber2		
	movb fraction_2(,%edx,1), %bl # pobieranie znaku do ebx

	pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
    jmp multiBegin

secondNumberEnd:
	cmpl $0, lengthNumber1
	jge multiBegin
	cmpl $0, lengthNumber2
	jge multiBegin
	cmpl $0, carry
	jg multiBegin
	jmp outcome

multiBegin:
    xorl %ecx, %ecx
	imull firstNumberCurrentValue, %eax	
	addl carry, %eax # dodajemy ewentualne przeniesienie
	movb $0, carry # zerujemy przeniesienie

compare:
	cmpl base, %eax	
	jb savingResult
	subl base, %eax #jezeli wynik jest wiekszy od podstawy to odejmujemy podstawe...
	incl %ecx
	jmp compare

savingResult:
    movl %ecx, carry

	movb %al, result(,%edi,1) #zapisujemy wynik do result
	decl %edi # i dekrementujemy nasz rejestr przechodzacy po result
    
    xorl %ecx, %ecx
    movl lengthNumber2, %ecx
    addl $1, %ecx
    cmpl $0, %ecx 
	jg calculatorContinue   # jesli lengthNumber > -1 to kontynuujemy mnozenie przez druga liczbe

    xorl %ecx, %ecx
    movl carry, %ecx
    cmpl $0, %ecx   
    jne calculatorContinue  # jesli mamy jeszcze przeniesienie to lecimy dalej

outcome:
    decl %edi
    cmpl $0, %edi
    je outcome2
    movb $0, result(,%edi,1) #zapisujemy wynik do result
    jmp outcome

outcome2:
    call addToFinalResult  
    jmp prepareResult

outcome3:
    #call findInitialZeros
    xorl %edi, %edi
    xorl %eax, %eax
    xorl %ebx, %ebx

makeSignResult:
    movb sign_1, %al
    movb sign_2, %bl
    cmpl %eax, %ebx
    je makeExponentResult
    movb $1, signResult

makeExponentResult:
    movb $0, carry
    movl sizeOfExponent, %edi

    movb $0xA, exponentResult(,%edi,1) # lf
    incl %edi
    movb $0xD, exponentResult(,%edi,1) # cr
    decl %edi
    decl %edi #indeksowanie od zera

makeExponentResultAdding:
    xorl %ebx, %ebx
    xorl %eax, %eax
    movb exponent_1(,%edi,1), %al
    movb exponent_2(,%edi,1), %bl
    subl $48, %eax
    subl $48, %ebx #char to int

    addl %ebx, %eax
    addl carry, %eax
    movb $0, carry
    cmpl base, %eax
    jl makeExponentResultSaving
    subl base, %eax
    movb $1, carry

makeExponentResultSaving:
    addl $48, %eax
    movb %al, exponentResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge makeExponentResultAdding

    movb $0, carry
    movl sizeOfExponent, %edi
    decl %edi #przygotowanie indeksu do odejmowania

makeExponentResultSubtracting: #odejmujemy obciazonko (01111111)
    xorl %eax, %eax
    movb exponentResult(,%edi,1), %al
    subl $48, %eax
    cmpl $0, %edi
    je makeExponentResultSubtracting2 #dla indeksu 0 nie odjemujemy nic
    decl %eax

makeExponentResultSubtracting2:
    subl carry, %eax
    movb $0, carry
    cmpl $0, %eax
    jge makeExponentResultSaving2
    addl base, %eax
    movb $1, carry

makeExponentResultSaving2:
    addl $48, %eax
    movb %al, exponentResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge makeExponentResultSubtracting
    
makeFractionResult:
    xorl %edi, %edi #indeks poruszania sie po finalResultMantysas
    xorl %ebx, %ebx
    incl %edi #indeksowanie od 1 w finalResult (pozniej do zmiany, zeby bylo od 0 jak w reszcie)
    movb finalResultMantysas(,%edi,1), %bl   
    incl %edi
    xorl %edx, %edx #indeks poruszania sie po fractionResult
    cmpl $'0', %ebx
    jne makeFractionResult1
    incl %edi
    jmp makeFractionResult2

makeFractionResult1:
    pushl %edi
    call incrementExponent
    popl %edi

makeFractionResult2:
    xorl %ebx, %ebx
    movb finalResultMantysas (,%edi,1), %bl
    movb %bl, fractionResult (,%edx,1)
    incl %edi
    incl %edx
    cmpl sizeOfMantysa, %edx
    jl makeFractionResult2
    
    movb $0xA, fractionResult(,%edx,1) # lf
    incl %edx
    movb $0xD, fractionResult(,%edx,1) # cr
    xorl %edx, %edx

moveRoundingBits:
    xorl %ebx, %ebx
    movb finalResultMantysas (,%edi,1), %bl
    movb %bl, roundingBits (,%edx,1)
    incl %edi
    incl %edx
    cmpl $3, %edx #liczba bitow zaokraglenia
    jl moveRoundingBits

    movb $0xA, roundingBits(,%edx,1) # lf
    incl %edx
    movb $0xD, roundingBits(,%edx,1) # cr

    pushl signResult
    call showResult
    addl $4, %esp

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $answer, %ecx # wyswietlamy sum
	movl $answer_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $finalResult, %ecx
	movl $BYTES, %edx
	int $LINUX_SYSCALL


	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $messageRoundingBits, %ecx # wyswietlamy sum
	movl $messageRoundingBits_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $roundingBits, %ecx
	movl $BYTES, %edx
	int $LINUX_SYSCALL


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

.type addToFinalResult,@function
addToFinalResult:
	pushl %ebp
	movl %esp, %ebp
    xorl %edx, %edx
    movl size, %edx

addToFinalResult1:
    xorl %ebx, %ebx
    movb result(,%edx,1), %bl # pobieranie znaku do ebx
    movb finalResultMantysas(,%edx,1), %al
    addl %ebx, %eax
    addl finalCarry, %eax
    movl $0, finalCarry
    cmpl base, %eax
    jl addToFinalResult2

    xorl %ecx, %ecx
    subl base, %eax
    incl %ecx
    movl %ecx, finalCarry
    
addToFinalResult2:
    cmpl $0, lengthNumber1
    jl addToFinalResult3

addToFinalResult2_5:
    movb %al, finalResultMantysas(,%edx,1)
    decl %edx
    cmpl $0, %edx
    jg addToFinalResult1
    jmp addToFinalResultEnd

addToFinalResult3:
    pushl %eax
    call intToChar
    addl $4, %esp
    movb %al, finalResultMantysas(,%edx,1)
    decl %edx
    cmpl $0, %edx
    jg addToFinalResult1

addToFinalResultEnd:
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
    movl $1, %edx
    decl sizeCounter
    movb finalResultMantysas(,%edx,1), %al
    incl %edx
    cmpl $'0', %eax
    je deleteInitialZeros
    jmp findInitialZerosEnd
    
deleteInitialZeros:
    xorl %eax, %eax
    movb finalResultMantysas(,%edx,1), %al
    decl %edx
    movb %al, finalResultMantysas(,%edx,1)
    addl $2, %edx
    cmpl sizeCounter, %edx
    jle deleteInitialZeros

deleteRedundand:
    decl %edx
    movl $0, finalResultMantysas(,%edx,1)
    jmp findInitialZerosBegin

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

.type incrementExponent, @function
incrementExponent:
    pushl %ebp
    movl %esp, %ebp
    xorl %edi, %edi
    movb $0, carry

increment:
    movl sizeOfExponent, %edi
    decl %edi #  indeks ostatniej cyfry wykladnika (lecimy od 0)
   
increment1:
    xorl %ebx, %ebx #dodawanie jedynki do wykladnika
    movb exponentResult(,%edi,1), %bl
    subl $48, %ebx
    addb carry, %bl
    movb $0, carry
    cmpl $7, %edi #tylko raz ma byc dodana jedynka (inkrementacja)
    jne increment2
    incl %ebx

increment2:
    cmpl $2, %ebx
    jl increment3
    subl $2, %ebx
    movb $1, carry
 
increment3:
    addl $48, %ebx
    movb %bl, exponentResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge increment1
    
endIncrementExponent:
    movl %ebp, %esp    
    popl %ebp  
    ret


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
.lcomm helper, BYTE
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
    valueDivident: .long 0
    valueTempDivident: .long 0
    valueDivider: .long 0
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
    movl $2, base
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
    movl %eax, valueDivident
    movl %eax, valueTempDivident
 
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
    movl %eax, valueDivider
    
    subl $127, valueExponent_1
    subl $127, valueExponent_2

    #xorl %edx, %edx
    #addl valueExponent_1, %edx
    #addl valueExponent_2, %edx
    #cmpl limit, %edx
    #jg faultNadmiar1
    #cmpl limit1, %edx
    #jl faultNiedomiar1
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

makeExponentResultSubtracting:
    xorl %ebx, %ebx
    xorl %eax, %eax
    movb exponent_1(,%edi,1), %al
    movb exponent_2(,%edi,1), %bl
    subl $48, %eax
    subl $48, %ebx #char to int

    subl %ebx, %eax
    subl carry, %eax
    movb $0, carry
    cmpl $0, %eax
    jge makeExponentResultSaving
    addl base, %eax
    movb $1, carry

makeExponentResultSaving:
    addl $48, %eax
    movb %al, exponentResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge makeExponentResultSubtracting

    movb $0, carry
    movl sizeOfExponent, %edi
    decl %edi #przygotowanie indeksu do dodawania

makeExponentResultAdding: #odejmujemy obciazonko (01111111)
    xorl %eax, %eax
    movb exponentResult(,%edi,1), %al
    subl $48, %eax
    cmpl $0, %edi
    je makeExponentResultAdding2 #dla indeksu 0 nie odjemujemy nic
    incl %eax

makeExponentResultAdding2:
    addl carry, %eax
    movb $0, carry
    cmpl base, %eax
    jl makeExponentResultSaving2
    subl base, %eax
    movb $1, carry

makeExponentResultSaving2:
    addl $48, %eax
    movb %al, exponentResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge makeExponentResultAdding
    xorl %edi, %edi

makeFraction:
    xorl %eax, %eax
    xorl %edx, %edx
    xorl %ecx, %ecx
    movl valueTempDivident, %eax
    movl valueDivider, %ecx
    idiv %ecx
    imull base, %edx
    movl $0, valueTempDivident
    movl %edx, valueTempDivident

    addl $48, %eax
    movb %al, fractionResult(,%edi,1)
    incl %edi
    cmpl $28, %edi #23 + 3 bity zaokraglenia + 1 bit ukryty + 1 ewentualne 0
    jl makeFraction

    movb $0xA, fractionResult(,%edi,1) # lf
    incl %edi
    movb $0xD, fractionResult(,%edi,1) # cr
    
    xorl %edi, %edi
    xorl %ebx, %ebx
    movb fractionResult(,%edi,1), %bl
    cmpl $'0', %ebx
    jne finish
    call decrementExponent
    movb $1, helper # jesli jest 0 to uruchamiamy jedynke zeby przesunac wynik o jeden w lewo

finish: 
    xorl %edi, %edi
    movl sizeOfMantysa, %edi
    incl %edi #bit ukryty
    addl helper, %edi #ewentualne 0 na poczatku wyniku
    xorl %edx, %edx

moveRoundingBits:
    xorl %ebx, %ebx
    movb fractionResult (,%edi,1), %bl
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
    addl $8, %esp

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
    incl %esi
    movl sizeOfMantysa, %ecx
    addl helper, %esi
    addl helper, %ecx

joinFraction:
    xorl %ebx, %ebx
    movb fractionResult (,%esi,1), %bl
    movb %bl, finalResult(,%edi,1)
    incl %esi
    incl %edi
    cmpl %ecx, %esi
    jle joinFraction
 
    movb $0xA, finalResult(,%edi,1) # lf
    incl %edi
    movb $0xD, finalResult(,%edi,1) # cr
 
endShowResult:
    movl %ebp, %esp    
    popl %ebp  
    ret

.type decrementExponent, @function
decrementExponent:
    pushl %ebp
    movl %esp, %ebp
    xorl %edi, %edi
    movb $0, carry

decrement:
    movl sizeOfExponent, %edi
    decl %edi #  indeks ostatniej cyfry wykladnika (lecimy od 0)
   
decrement1:
    xorl %ebx, %ebx #dodawanie jedynki do wykladnika
    movb exponentResult(,%edi,1), %bl
    subl $48, %ebx
    subb carry, %bl
    movb $0, carry
    cmpl $7, %edi #tylko raz ma byc dodana jedynka (inkrementacja)
    jne decrement2
    decl %ebx

decrement2:
    cmpl $0, %ebx
    jge decrement3
    addl $2, %ebx
    movb $1, carry
 
decrement3:
    addl $48, %ebx
    movb %bl, exponentResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge decrement1
    
endDecrementExponent:
    movl %ebp, %esp    
    popl %ebp  
    ret


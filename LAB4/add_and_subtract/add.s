# First: 0|11101010|10101000101001010101010
#Second: 0|11101010|10110010101110110010101

#Result: 0|1110101|10101101101100000011111

# +

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
.lcomm finalResult, BYTES
.lcomm exponent_1, BYTES
.lcomm exponent_2, BYTES
.lcomm exponentResult, BYTES
.lcomm fractionResult, BYTES
.lcomm fraction_1, BYTES
.lcomm fraction_2, BYTES
.lcomm roundingBits, BYTES
 
.lcomm base, LENGTH
.lcomm operation, LENGTH
.lcomm answer_1, LENGTH
 
.lcomm result, BYTES
.lcomm carry, BYTE
.lcomm carryForFraction, BYTE
 
.section .data
    whichIsBigger: .long 0
    size: .long 0
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
    limit: .long 255
 
    message0:
    .ascii "\nIn which system would you want to execute the operation\n(b - bin, d - dec, h - hex): \0"
    mes0_len = .-message0
 
    message1:
    .ascii "\nFirst number (32 bits): \0"
    mes1_len = .-message1
 
    message2:
    .ascii "Second number (32 bits): \0"
    mes2_len = .-message2
    
    message3:
    .ascii "\nDo you want to do one more? (0 - yes, 1 - no): \0"
    mes3_len = .-message3
 
    messageWynik:
    .ascii "\nResult: \0"
    messageWynik_len = .-messageWynik

    messageNumber1:
    .ascii "\n First: \0"
    messageNumber1_len = .-messageNumber1

    messageNumber2:
    .ascii "Second: \0"
    messageNumber2_len = .-messageNumber2
 
    menu:
    .ascii "\nWhat operation do you want to execute? \n (0) - adder \n (1) - subtractor\n\0"
    menu_len = .-menu
 
    answer:
    .ascii "\nSum: \0"
    answer_len = .-answer
 
    answer1:
    .ascii "\nDifference: \0"
    answer1_len = .-answer1
   
    fault0:
    .ascii "\nGive the correct value!\n\0"
    fault0_len = .-fault0

    faultNAN:
    .ascii "\nNaN!\n\n\0"
    faultNAN_len = .-faultNAN
 
    faultDenormalized:
    .ascii "\nDenormalized!\n\n\0"
    faultDenormalized_len = .-faultDenormalized
   
    faultInfinity:
    .ascii "\nInfinity!\n\n\0"
    faultInfinity_len = .-faultInfinity
 
.section .text
.globl _start
 
_start:
 
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
    incb sign_1
 
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
    subl $127, %eax

    movl %eax, valueExponent_1
    xorl %edx, %edx
    movb $49, fraction_1(,%edx,1)
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


    cmpl $128, valueExponent_1
    jl checkingIfDenormalized1
    movl valueFraction_1, %eax
    cmpl $8388608, valueFraction_1 #2^23  trzeba wziąć pod uwagę bit ukryty
    jne numberIsNan
    jmp numberIsInfinity

checkingIfDenormalized1:
    cmpl $-127, valueExponent_1 # wykladnik -127 czyli 00000000
    jg askForSecondNumber
    cmpl $8388608, valueFraction_1
    jg numberIsDenormalized
 
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
    subl $127, %eax
    movl %eax, valueExponent_2
    movb $49, fraction_2(,%edx,1)
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


    cmpl $128, valueExponent_2
    jl checkingIfDenormalized2
    cmpl $8388608, valueFraction_2
    jne numberIsNan
    jmp numberIsInfinity

checkingIfDenormalized2:
    cmpl $-127, valueExponent_2
    jg continue2
    cmpl $8388608, valueFraction_2
    jg numberIsDenormalized

continue2:
    movl valueExponent_1, %eax
    movl valueExponent_2, %ebx
    movl valueFraction_1, %ecx
    movl valueFraction_2, %edx
   
    cmpl %eax, %ebx
    jg setSecondBigger
    cmpl %eax, %ebx
    jl setFirstBigger
    cmpl %ecx, %edx
    jge setSecondBigger
 
 
setFirstBigger:
    movl $1, whichIsBigger
    jmp start
   
setSecondBigger:
    movl $2, whichIsBigger
 
start:
    jmp menuStart
    
numberIsDenormalized:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $faultDenormalized, %ecx
    movl $faultDenormalized_len, %edx
    int $LINUX_SYSCALL
    jmp _start

numberIsNan:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $faultNAN, %ecx
    movl $faultNAN_len, %edx
    int $LINUX_SYSCALL
    jmp _start


numberIsInfinity:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $faultInfinity, %ecx
    movl $faultInfinity_len, %edx
    int $LINUX_SYSCALL
    jmp _start

menuStart:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $menu, %ecx
    movl $menu_len, %edx
    int $LINUX_SYSCALL
 
    xorl %eax, %eax
    xorl %ebx, %ebx
    xorl %ecx, %ecx
    xorl %edx, %edx
 
 
    movl $READ, %eax
    movl $STDIN, %ebx
    movl $operation, %ecx
    movl $BYTE, %edx
    int $LINUX_SYSCALL
 
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

    xorl %ebx, %ebx
    movb operation, %bl
    cmpb $'0', %bl
    je adder
    cmpb $'1', %bl
    je adder
 
    jmp menuStart
 
adder:
    xorl %eax, %eax
    xorl %ebx, %ebx
    xorl %ecx, %ecx
    xorl %edx, %edx
 
    movl valueExponent_1, %eax
    movl valueExponent_2, %ebx
 
    cmpl %eax, %ebx
    jge adderSecondExponentBigger
    subl %ebx, %eax
    jmp ifSenseExist
 
adderSecondExponentBigger:
    subl %eax, %ebx
    xorl %eax, %eax
    movl %ebx, %eax
 
ifSenseExist:
    movl %eax, differenceOfExponents # w eax jest zapisana roznica miedzy wykladnikami
    cmpl sizeOfMantysa, %eax  #jesli roznica w wykladnikach jest wieksza od 23 to przechodzimy od razu do wyswietlenia liczby wiekszej gdyz nie ma sensu dodawac
    jle adderContinue

    xorl %eax, %eax
    xorl %ebx, %ebx
 
    movl valueExponent_1, %eax
    movl valueExponent_2, %ebx
 
    cmpl %eax, %ebx
    jg ifSenseExistSecondHigher

write1Result1:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $messageWynik, %ecx
    movl $messageWynik_len, %edx
    int $LINUX_SYSCALL
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $number_1, %ecx
    movl $BYTES, %edx
    int $LINUX_SYSCALL
 
    jmp adderEnd
 
ifSenseExistSecondHigher:

    cmpb $'0', operation
    je write1Result2 #jesli jest dodawanie to zostawiamy znak, odejmowanie = przeciwny
    xorl %edx, %edx
    movb sign_2, %bl
    subl $1, %ebx
    cmpl $0, %ebx
    jge setSignAs0
    movb $49, number_2(,%edx,1)
    jmp write1Result2

setSignAs0:
    movb $48, number_2(,%edx,1)


write1Result2:
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $messageWynik, %ecx
    movl $messageWynik_len, %edx
    int $LINUX_SYSCALL
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $number_2, %ecx
    movl $BYTES, %edx
    int $LINUX_SYSCALL
 
    jmp adderEnd
 
adderContinue:
 
    xorl %ebx, %ebx
    movb operation, %bl
    cmpb $'0', %bl
    je adderStart
    cmpb $'1', %bl
    je subtractor
 
adderStart:
    movl sizeOfMantysa, %edi
    incl %edi
    movb $0xA, fractionResult(,%edi,1) # lf
    incl %edi
    movb $0xD, fractionResult(,%edi,1) # cr
    xorl %edi, %edi

    call makingResult
 
    jmp endAdder
 
endAdder:
    xorl %eax, %eax
    xorl %ebx, %ebx
    xorl %ecx, %ecx
    xorl %edx, %edx
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $messageWynik, %ecx
    movl $messageWynik_len, %edx
    int $LINUX_SYSCALL
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $finalResult, %ecx
    movl $BYTES, %edx
    int $LINUX_SYSCALL
 
adderEnd:
    jmp end
 
subtractor: 
    call makingResult
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $messageWynik, %ecx
    movl $messageWynik_len, %edx
    int $LINUX_SYSCALL
 
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $finalResult, %ecx
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
 
.type incrementExponent, @function
incrementExponent:
    pushl %ebp
    movl %esp, %ebp
    movl 8(%ebp), %ecx  #pod 8(%ebp) mamy exponentResult
    movl 12(%ebp), %edx #pod 12(%ebp) mamy exponent_1 badz exponent_2
    xorl %edi, %edi
 
    cmpb $0, carry
    je rewritingExponent
    jmp increment
 
rewritingExponent:
    xorl %ebx, %ebx
    movb (%edx), %bl
    movb %bl, (%ecx)
    incl %edx
    incl %ecx
    incl %edi
    cmpl $9, %edi #przepisujemy tez znaki konca, dlatego indeks 9 (8 znakow wykladnika i 2 konca)
    jle rewritingExponent
 
    xorl %edi, %edi
    incl %edi
    movl sizeOfMantysa, %edx
    addl $2, %edx #znaki konca
 
moveMantysa:    
    movb fractionResult (,%edi,1), %bl
    decl %edi
    movb %bl, fractionResult (,%edi,1)
    incl %edi
    incl %edi
    cmpl %edx, %edi
    jle moveMantysa
 
    jmp endIncrementExponent
 
increment:
    xorl %edi, %edi
    movl sizeOfExponent, %edi
    decl %edi #  indeks ostatniej cyfry wykladnika (lecimy od 0)
    addl %edi, %ecx # bedziemy od ostatniej cyfry pobierac
    addl %edi, %edx
   
increment1:
    movb $0, carry
    incl %ecx
    movb $0xA, (%ecx) # lf
    incl %ecx
    movb $0xD, (%ecx) # cr
    decl %ecx
    decl %ecx
    xorl %ebx, %ebx #dodawanie jedynki do wykladnika
    movb (%edx), %bl
    subl $48, %ebx
    incl %ebx
    cmpl $2, %ebx
    jl incrementContinueXD
    subl $2, %ebx
    movb $1, carry
    addl $48, %ebx
    movb %bl, (%ecx)
 
incrementContinueXD:
    addl $48, %ebx
    movb %bl, (%ecx)
 
incrementContinue:
    decl %edi
    decl %ecx
    decl %edx
    xorl %ebx, %ebx
    movb (%edx), %bl
    subl $48, %ebx
    addl carry, %ebx
    movb $0, carry
    cmpl $2, %ebx
    jl incrementContinue1
    subl $2, %ebx
    movb $1, carry
 
incrementContinue1:
    addl $48, %ebx
    movb %bl, (%ecx)
    cmpl $0, %edi
    jge incrementContinue
   
    xorl %edi, %edi
    movl sizeOfMantysa, %edi
    movb $0xA, fractionResult(,%edi,1)
    incl %edi
    movb $0xD, fractionResult(,%edi,1)
 
endIncrementExponent:
    movl %ebp, %esp    
    popl %ebp  
    ret
 
.type addMantysas, @function
addMantysas:
    pushl %ebp
    movl %esp, %ebp
 
    xorl %edi, %edi
    xorl %ecx, %ecx
    xorl %esi, %edx
    movl sizeOfMantysa, %edi
    movl differenceOfExponents, %ecx  # tu mamy differenceOfExponents
    movl %edi, %esi
    subl %ecx, %esi
 
    xorl %ecx, %ecx
    movl 8(%ebp), %edx  #pod 8(%ebp) mamy fraction_1 badz fraction_2
    movl 12(%ebp), %ecx #pod 12(%ebp) mamy fraction_2 badz fraction_1
    addl %esi, %edx
    addl %edi, %ecx
 
addMantysasContinue:
    movb (%edx), %bl
    movb (%ecx), %al
    cmpl $0, %esi
    jl addMantysasContinueSaving3
    subb $48, %bl
    subb $48, %al
 
    addl %ebx, %eax
    addl carry, %eax
    movb $0, carry
    cmpl $2, %eax
    jl addMantysasContinueSaving
    subl $2, %eax
    movb $1, carry
 
addMantysasContinueSaving:
    addb $48, %al
 
addMantysasContinueSaving2:
    movb %al, fractionResult(,%edi,1)
    decl %edi
    decl %esi
    decl %edx
    decl %ecx
    cmpl $0, %edi
    jl endAddMantysas
    jmp addMantysasContinue
 
addMantysasContinueSaving3:
    subb $48, %al
    addl carry, %eax
    movb $0, carry #zerowanie przeniesienia
    cmpl $2, %eax
    jl addMantysasContinueSaving4
    subl $2, %eax
    movb $1, carry
 
addMantysasContinueSaving4:
    addb $48, %al
    movb %al, fractionResult(,%edi,1)
    decl %edi
    decl %edx
    decl %ecx
    cmpl $0, %edi
    jl endAddMantysas
    jmp addMantysasContinue
 
endAddMantysas:
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
    incl %ecx
   
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
 
.type subtractMantysas, @function
subtractMantysas:
    pushl %ebp
    movl %esp, %ebp
 
    xorl %edi, %edi
    xorl %ecx, %ecx
    xorl %esi, %edx
    movl sizeOfMantysa, %edi
    movl differenceOfExponents, %ecx  # tu mamy differenceOfExponents
    movl %edi, %esi
    subl %ecx, %esi
 
    xorl %ecx, %ecx
    movl 8(%ebp), %edx  #pod 8(%ebp) mamy fraction_1 badz fraction_2
    movl 12(%ebp), %ecx #pod 12(%ebp) mamy fraction_2 badz fraction_1
    addl %esi, %edx
    addl %edi, %ecx
 
subtractMantysasContinue:
    xorl %ebx, %ebx
    xorl %eax, %eax
    movb (%edx), %bl
    movb (%ecx), %al
    cmpl $0, %esi
    jl subtractMantysasContinueSaving3
 
    subb $48, %bl
    subb $48, %al
 
    subl %ebx, %eax
    subl carry, %eax
    movb $0, carry
    cmpl $0, %eax
    jge subtractMantysasContinueSaving
    addl $2, %eax
    movb $1, carry
 
subtractMantysasContinueSaving:
    addb $48, %al
 
subtractMantysasContinueSaving2:
    movb %al, fractionResult(,%edi,1)
    decl %edi
    decl %esi
    decl %edx
    decl %ecx
    cmpl $0, %edi
    jl endSubtractMantysas
    jmp subtractMantysasContinue
 
subtractMantysasContinueSaving3:
    subb $48, %al
    subl carry, %eax
    movb $0, carry #zerowanie przeniesienia
    cmpl $0, %eax
    jge subtractMantysasContinueSaving4
    addl $2, %eax
    movb $1, carry
 
subtractMantysasContinueSaving4:
    addb $48, %al
    movb %al, fractionResult(,%edi,1)
    decl %edi
    decl %edx
    decl %ecx
    cmpl $0, %edi
    jl endSubtractMantysas
    jmp subtractMantysasContinue
 
endSubtractMantysas:
    movl %ebp, %esp    
    popl %ebp  
    ret
 
.type movingMantysa, @function
movingMantysa:
    pushl %ebp
    movl %esp, %ebp
    xorl %edi, %edi
    xorl %edx, %edx
    movl sizeOfMantysa, %edx
    incl %edx
 
moving:
    movb fractionResult(,%edi,1), %al
    cmpb $48, %al
    jne moving2
    incl %ebx
    movb %al, fractionResult(,%edx,1)
    incl %edx
    incl %edi
    jmp moving
   
moving2:
    movl %ebx, movingCounter
    cmpl $0, %ebx
    je endmovingMantysa
 
    movb $0xA, fractionResult(,%edx,1) # lf
    incl %edx
    movb $0xD, fractionResult(,%edx,1) # cr
    xorl %edi, %edi
    xorl %edx, %edx
    movl %ebx, %edi
    movl sizeOfMantysa, %ecx
    addl $2, %ecx # znak konca, pomocniczy rejestr
 
moving3:
    movb fractionResult(,%edi,1), %al
    movb %al, fractionResult(,%edx,1)
    incl %edi
    incl %edx
    cmpl %ecx, %edx
    jle moving3    
 
endmovingMantysa:
    movl %ebp, %esp    
    popl %ebp  
    ret
 
.type decrementExponent, @function
decrementExponent:
    pushl %ebp
    movl %esp, %ebp
    movl 8(%ebp), %ecx  #pod 8(%ebp) mamy exponentResult
    movl 12(%ebp), %edx #pod 12(%ebp) mamy exponent_1 badz exponent_2
    xorl %edi, %edi
 
 
rewritingExponent1:
    xorl %ebx, %ebx
    movb (%edx), %bl
    movb %bl, (%ecx)
    incl %edx
    incl %ecx
    incl %edi
    cmpl $9, %edi #przepisujemy tez znaki konca, dlatego indeks 9 (8 znakow wykladnika i 2 konca)
    jle rewritingExponent1
 
    xorl %edi, %edi
    incl %edi
    movl sizeOfMantysa, %edx
    addl $2, %edx #znaki konca
    movb $0, carry
 
    movl movingCounter, %ebx
    cmpl $0, %ebx
    jle endDecrementExponent
 
decrement:
    movl 8(%ebp), %ecx  #pod 8(%ebp) mamy exponentResult
    xorl %edi, %edi
    movl sizeOfExponent, %edi
    decl %edi #  indeks ostatniej cyfry wykladnika (lecimy od 0)
    addl %edi, %ecx # bedziemy od ostatniej cyfry pobierac
    addl %edi, %edx
 
    movl movingCounter, %ebx
    decl %ebx
    movl %ebx, movingCounter
 
decrement1:
    xorl %ebx, %ebx #dodawanie jedynki do wykladnika
    movb (%ecx), %bl
    subl $48, %ebx
    decl %ebx
    cmpl $0, %ebx
    jge decrementContinueXD
    addl $2, %ebx
    movb $1, carry
    addl $48, %ebx
    movb %bl, (%ecx)
    jmp decrementContinue
 
decrementContinueXD:
    addl $48, %ebx
    movb %bl, (%ecx)
 
decrementContinue:
    decl %edi
    decl %ecx
    decl %edx
    xorl %ebx, %ebx
    movb (%ecx), %bl
    subl $48, %ebx
    subl carry, %ebx
    movb $0, carry
    cmpl $0, %ebx
    jge decrementContinue1
    addl $2, %ebx
    movb $1, carry
 
decrementContinue1:
    addl $48, %ebx
    movb %bl, (%ecx)
    cmpl $0, %edi
    jg decrementContinue
 
    movl movingCounter, %ebx
    cmpl $0, %ebx
    jg decrement
 
endDecrementExponent:
    movl %ebp, %esp    
    popl %ebp  
    ret
 
.type showResultForSubtract, @function
showResultForSubtract:
    pushl %ebp
    movl %esp, %ebp
    xorl %edi, %edi
   
joinSign1:
    movl 8(%ebp), %ebx
    addl $48, %ebx
    movb %bl, finalResult(,%edi,1)
    incl %edi
    movb $124, finalResult(,%edi,1)
    incl %edi
    xorl %esi, %esi # licznik dla wykladnika
    movl sizeOfExponent, %ecx
 
joinExponent1:
    xorl %ebx, %ebx
    movb exponentResult (,%esi,1), %bl
    movb %bl, finalResult(,%edi,1)
    incl %esi
    incl %edi
    cmpl %ecx, %esi
    jl joinExponent1
    movb $124, finalResult(,%edi,1)
    incl %edi
    xorl %esi, %esi
    movl sizeOfMantysa, %ecx
    incl %ecx
    incl %esi
 
 
joinFraction1:
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
 
endShowResultForSubtract:
    movl %ebp, %esp    
    popl %ebp  
    ret
 
.type makingResult, @function
makingResult:
    pushl %ebp
    movl %esp, %ebp
    xorl %ebx, %ebx
    movb operation, %bl
    cmpb $'0', %bl
    je makingResultAddition
    cmpb $'1', %bl
    je makingResultSubtraction
 
makingResultSubtraction:
    cmpl $2, whichIsBigger
    je makingResultSubtraction2
   
makingResultSubtraction1:  
    movb sign_1, %al
    movb sign_2, %bl
    movl %eax, signResult
    cmpl %eax, %ebx
    je makingResultSubtraction1FINAL
   
    jmp makingResultAddition1FINAL
   
makingResultSubtraction1FINAL: 
    pushl $fraction_1
    pushl $fraction_2
    call subtractMantysas
    addl $8, %esp
 
    call movingMantysa
 
    pushl $exponent_1
    pushl $exponentResult
    call decrementExponent
    addl $8, %esp
       
    pushl signResult
    call showResultForSubtract
    addl $4, %esp
   
    jmp endMakingResult
   
makingResultSubtraction2:  
    movb sign_1, %al
    movb sign_2, %bl
    subl $1, %ebx
    cmpl $0, %ebx
    jge continuing2
    movl $1, signResult
   
continuing2:
    incl %ebx
    cmpl %eax, %ebx
    je makingResultSubtraction2FINAL
 
    jmp makingResultAddition2FINAL
   
makingResultSubtraction2FINAL:
    pushl $fraction_2
    pushl $fraction_1
    call subtractMantysas
    addl $8, %esp
 
    call movingMantysa
 
    pushl $exponent_2
    pushl $exponentResult
    call decrementExponent
    addl $8, %esp
   
    pushl signResult
    call showResultForSubtract
    addl $4, %esp
   
    jmp endMakingResult
   
makingResultAddition:
 
    cmpl $2, whichIsBigger
    je makingResultAddition2
 
makingResultAddition1:
 
    movb sign_1, %al
    movb sign_2, %bl
    movl %eax, signResult
    cmpl %eax, %ebx
    je makingResultAddition1FINAL
   
    jmp makingResultSubtraction1FINAL
   
makingResultAddition1FINAL:
 
    pushl $fraction_1
    pushl $fraction_2
    call addMantysas
    addl $8, %esp
   
    pushl $exponent_1
    pushl $exponentResult
    call incrementExponent
    addl $8, %esp
   
    pushl signResult
    call showResult
    addl $4, %esp
 
    jmp endMakingResult
 
makingResultAddition2:
    movb sign_1, %al
    movb sign_2, %bl
    movb %bl, signResult

    cmpl %eax, %ebx
    je makingResultAddition2FINAL
 
    jmp makingResultSubtraction2FINAL
 
makingResultAddition2FINAL:
 
    pushl $fraction_2
    pushl $fraction_1
    call addMantysas
    addl $8, %esp
 
    pushl $exponent_2
    pushl $exponentResult
    call incrementExponent
    addl $8, %esp
   
    pushl signResult
    call showResult
    addl $4, %esp
 
 
endMakingResult:
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

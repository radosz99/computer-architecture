.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.section .bss
.equ EXP, 32
.equ TEMPSIZE, 1024 #zmienic na 512 pozniej
.equ BYTES, 1024
.equ BYTES_2, 2048
.equ LENGTH, 4
.equ BYTE, 1
.lcomm number_1, BYTES
.lcomm exponentBinary, BYTES
.lcomm number_2, BYTES
.lcomm tempPower, TEMPSIZE
.lcomm tempPowerCopy, TEMPSIZE
.lcomm licznik, BYTES
.lcomm base, LENGTH
.lcomm lengthResult, LENGTH
.lcomm lengthNumber1, LENGTH
.lcomm lengthNumber2, LENGTH
.lcomm lengthNumber2_2, LENGTH
.lcomm lengthTempPower, LENGTH
.lcomm lengthTempPowerCopy, LENGTH
.lcomm counterOperationsString, LENGTH
.lcomm firstNumberCurrentValue, LENGTH
.lcomm lengthBinaryExponent, LENGTH
.lcomm result, BYTES
.lcomm tempResult, BYTES
.lcomm finalResult, BYTES
.lcomm carry, BYTE
.lcomm finalCarry, BYTE

.section .data
    size: .long 1024 #zmienic na wiecej
    elasticSize: .long 0
    sizeCounter: .long 0
    exponentBinaryCounter: .long 0
    counterOperations: .long 0

	message0:
	.ascii "In which system would you want to execute the operation\n(b - bin, d - dec, h - hex): \0"
	mes0_len = .-message0

	message1:
	.ascii "\nNumber: \0"
	mes1_len = .-message1

	message2:
	.ascii "Exponent: \0"
	mes2_len = .-message2

	answerResult:
	.ascii "\nResult: \0"
	answerResult_len = .-answerResult

	answerOperations:
	.ascii "\nNumber of multiplications: \0"
	answerOperations_len = .-answerOperations


	fault0:
	.ascii "\nGive the correct value!\n\0"
	fault0_len = .-fault0


.section .text
.globl _start

_start:
    movl $0, counterOperations
    movl $0, exponentBinaryCounter
    movl size, %eax
    movl %eax, elasticSize

moveOneToResult:
    xorl %eax, %eax
    movb $'1', result(,%eax,1)
    movl $0, lengthResult
    
setFinalResult:
    xorl %eax, %eax
    movl size, %edi
	decl %edi

resetFinalResult:
    movb $0, finalResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge resetFinalResult	
	
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

faulting:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $fault0, %ecx
	movl $fault0_len, %edx
	int $LINUX_SYSCALL
	jmp askBase

binary:
	movl $2, %eax
	movl %eax, base
	jmp askNumber

decimal:
    movl $10, %eax
	movl %eax, base
	jmp askNumber

hexadecimal:
	movl $0x10, %eax
	movl %eax, base

askNumber:
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
	movl %eax, lengthTempPower # dlugosc liczby 1 bez entera i \0
    movl %eax, lengthTempPowerCopy

askExponent:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $message2, %ecx
	movl $mes2_len, %edx
	int $LINUX_SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $number_2, %ecx
	movl $EXP, %edx
	int $LINUX_SYSCALL

	decl %eax


moveBaseToTempPower:
    movl lengthTempPower, %edx

moveBaseToTempPowerContinue:
    xorl %ebx, %ebx
    movb number_1(,%edx,1), %bl
    movb %bl, tempPower(,%edx,1)
    decl %edx
    cmpl $0, %edx
    jge moveBaseToTempPowerContinue

convertExponentToBinaryString: #konwersja wykładnika do postaci binarnej
    pushl base #podstawa podawanej liczby
    pushl $number_2
    call convertBuffer
    addl $8, %esp
    xorl %ecx, %ecx
    xorl %edi, %edi
    movl $2, %ecx
    movl size, %edi
    decl %edi
    movl $0, lengthBinaryExponent

convertStart:
    xorl %edx, %edx
    idiv %ecx
    addl $48, %edx
    movb %dl, exponentBinary(,%edi,1)
    decl %edi
    incl lengthBinaryExponent
    cmpl $0, %eax
    jne convertStart

zeroReplenishment: #do wyswietlenia (czy poprawnie skonwertowano) #uzupełnienie binarnego wykładnika zerami
    movb $'0', exponentBinary(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge zeroReplenishment

	#movl $WRITE, %eax
	#movl $STDOUT, %ebx
	#movl $messageIndexBinary, %ecx
	#movl $messageIndexBinary_len, %edx
	#int $LINUX_SYSCALL
   
	#movl $WRITE, %eax
	#movl $STDOUT, %ebx
	#movl $exponentBinary, %ecx
	#movl $TEMPSIZE, %edx
	#int $LINUX_SYSCALL

    xorl %edi, %edi

checkIfMultiplicationIsNecessary: #sprawdzanie jakie mnożenie należy wykonać
    xorl %ebx, %ebx
    movl size, %edi
    decl %edi
    movl lengthBinaryExponent, %eax
    subl exponentBinaryCounter, %edi
    incl exponentBinaryCounter
    cmpl %eax, exponentBinaryCounter
    jg rewriteOperationsCounter
    movb exponentBinary(,%edi,1), %bl
    cmpl $'0', %ebx
    je multiplicationTempPowerTempPowerCopy

multiplicationResultTempPower: # result * tempPower
    pushl lengthResult
    pushl $tempPower
    pushl $result
    pushl lengthTempPower
    call multiplication
    popl lengthTempPower # popujemy lengthTempPower gdyż nie uległa zmianie
    addl $12, %esp

    incl counterOperations # inkrementacja licznika operacji

    xorl %eax, %eax
    movl lengthTempPower, %eax

    pushl $finalResult # przepisanie finalResult (czyli stringa w którym jest wynik mnożenia) do result
    pushl $result
    call rewriting
    addl $8, %esp

    pushl $result # usunięcie początkowych zer z result
    call findInitialZeros
    addl $4, %esp
    movl %eax, lengthResult # zaktualizowanie długości result
  
setFinalResult0: #zresetowanie finalResult
    xorl %eax, %eax
    movl size, %edi
	decl %edi

resetFinalResult0:
    movb $0, finalResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge resetFinalResult0

multiplicationTempPowerTempPowerCopy: # tempPower * tempPowerCopy (pomocniczy string identyczny z tempPower)

    movl lengthBinaryExponent, %eax
    movl exponentBinaryCounter, %ebx
    cmpl %eax, exponentBinaryCounter # sprawdzenie czy koniec wykładnika
    je rewriteOperationsCounter

    pushl $tempPower # przepisanie tempPower do tempPowerCopy
    pushl $tempPowerCopy
    call rewriting
    addl $8, %esp

    pushl lengthTempPowerCopy # tempPower * tempPoweropy
    pushl $tempPower
    pushl $tempPowerCopy
    pushl lengthTempPower
    call multiplication
    addl $16, %esp

    incl counterOperations # inkrementacja licznika operacji

    pushl $finalResult # przepisanie finalResult (czyli stringa w którym jest wynik mnożenia) do tempPower
    pushl $tempPower
    call rewriting
    addl $8, %esp

    pushl $tempPower # usunięcie początkowych zer z tempPower
    call findInitialZeros
    addl $4, %esp
    movl %eax, lengthTempPower # zaktualizowanie długości tempPower

    movl lengthTempPower, %eax
    movl %eax, lengthTempPowerCopy # zaktualizowanie długości tempPowerCopy

setFinalResult1: #zresetowanie finalResult
    xorl %eax, %eax
    movl size, %edi
	decl %edi

resetFinalResult1:
    movb $0, finalResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge resetFinalResult1

    jmp checkIfMultiplicationIsNecessary #powrot do poczatku petli

rewriteOperationsCounter: #przepisanie licznika operacji do stringa
    movl $3, %edi #4 miejsca na licznik
    movl $10, %ecx #baza systemu w ktorym jest licznik

    incl %edi
    movb $0xA, counterOperationsString(,%edi,1)
    decl %edi

    movl counterOperations, %eax

rewriteOperationsCounterStart:
    xorl %edx, %edx
    idiv %ecx
    addl $48, %edx
    movb %dl, counterOperationsString(,%edi,1)
    decl %edi
    cmpl $0, %eax
    jne rewriteOperationsCounterStart

ending: 
    movl lengthResult, %eax
    incl %eax
    movb $0xA, result(,%eax,1) # wstawienie znaku końca na koniec result


	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $answerOperations, %ecx
	movl $answerOperations_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $counterOperationsString, %ecx # wyswietlenie liczby operacji
	movl $LENGTH, %edx
	int $LINUX_SYSCALL
  


	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $answerResult, %ecx 
	movl $answerResult_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $result, %ecx # wyswietlenie wyniku result
	movl $TEMPSIZE, %edx
	int $LINUX_SYSCALL
  

end:
    movl $EXIT, %eax # koniec
	movl $0, %ebx
	int $LINUX_SYSCALL

#---------------------------------------------
#   Funkcja konwertująca chara do inta
#   uniwersalna dla systemów 2,10,16
#
#   argumenty:
#   8(%ebp) - konwertowany znak
#
#   wynik zwracany w rejestrze eax
#
#---------------------------------------------

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

#---------------------------------------------
#   Funkcja konwertująca inta do chara
#   uniwersalna dla systemów 2,10,16
#
#   argumenty:
#   8(%ebp) - konwertowany znak
#
#   wynik zwracany w rejestrze eax
#
#---------------------------------------------

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

#---------------------------------------------
#   Funkcja wykorzystywana w mnożeniu
#   Dodaje tempResult do finalResult
#
#   Przykładowo:
#
#       56
#   *   67
#   -------
#      392  <--- tempResult
#   + 336   <--- tempResult
#   -------
#     3752  <--- finalResult
#
#   wymaga przesuwania tempResult, które
#   wykonywane jest w samej funkcji multiplication
#
#   uniwersalna dla systemów 2,10,16
#
#---------------------------------------------

.type addToFinalResult,@function
addToFinalResult:
	pushl %ebp
	movl %esp, %ebp
    xorl %edx, %edx
    movl size, %edx
    decl %edx

addToFinalResult1:
    xorl %ebx, %ebx
    movb tempResult(,%edx,1), %bl # pobieranie znaku do ebx
    movb finalResult(,%edx,1), %al
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
    movb %al, finalResult(,%edx,1)
    decl %edx
    cmpl $0, %edx
    jge addToFinalResult1
    jmp addToFinalResultEnd

addToFinalResult3:
    pushl %eax
    call intToChar
    addl $4, %esp
    movb %al, finalResult(,%edx,1)
    decl %edx
    cmpl $0, %edx
    jge addToFinalResult1

addToFinalResultEnd:
    movl %ebp, %esp
	popl %ebp
	ret


#---------------------------------------------
#   Funkcja usuwająca wszystkie początkowe zera
#   z dowolnego stringa
#
#   jeśli znajdzie pod indeksem zerowym wartość 0
#   (48) to cały string jest przesuwany w lewo
#   powrót do szukania 0, jeśli na początku jest
#   coś innego niż 0 to wychodzimy z funkcji
#
#   Przykładowo:
#
#   00052 --> 52
#
#   stringi uzupełniane są z początku zerami
#   w celu stworzenia miejsca na wynik, który
#   jest większy i nadpisywany jest w tym samym stringu
#
#   argumenty:
#   8(%ebp) - string
#
#---------------------------------------------

.type findInitialZeros,@function
findInitialZeros:
    pushl %ebp
    movl %esp, %ebp

    xorl %eax, %eax
    xorl %ecx, %ecx
    movl size, %eax
    movl %eax, sizeCounter
    xorl %eax, %eax
    xorl %edi, %edi

findInitialZerosBegin:
    incl %edi # jeśli znajdujemy 0 na początku to inkrementujemy rejestr edi
    movl 8(%ebp), %ecx
    movl $0, %edx
    decl sizeCounter
    movb (%ecx), %al
    incl %ecx
    incl %edx
    cmpl $'0', %eax
    jne findInitialZerosEnd
    
deleteInitialZeros:
    xorl %eax, %eax
    movb (%ecx), %al
    decl %edx
    decl %ecx
    movb %al, (%ecx)
    addl $2, %edx
    addl $2, %ecx
    cmpl sizeCounter, %edx
    jle deleteInitialZeros

deleteRedundand:
    decl %edx
    decl %ecx
    movl $0, (%ecx)
    jmp findInitialZerosBegin

findInitialZerosEnd:
    xorl %eax, %eax
    movl size, %eax
    subl %edi, %eax # od size odejmujemy licznik zer (zawsze wartość minimum 1), a eax wrzucamy w długość stringa (długość liczona od 0)
    movl %ebp, %esp
	popl %ebp
	ret


#---------------------------------------------
#   Funkcja konwertująca stringowy bufor do
#   wartości, która jest zwracana w %eax
#   Dodaje tempResult do finalResult
#
#   Bierze pierwszy znak z bufora, konwertuje na inta
#   i sprawdza czy koniec bufora, jeśli nie to mnoży
#   razy podstawę systemu i dodaje następny znak 
#   do momentu końca bufora
#
#   Przykładowo:
#
#   bufor - 523 w dec
#
#   5 i następny znak to 2, czyli mnożymy 5*10 i
#   dodajemy 2 i mamy 52 w eax
#
#   52 i następny znak to 3, czyli mnożymy 52*10 i
#   dodajemy 3 i mamy 523 w eax
#
#   następuje koniec bufora (znak końca linii)
#   i zawartość eax jest wartością liczbową bufora
#
#   argumenty:
#   8(%ebp) - string
#
#   uniwersalna dla systemów 2,10,16
#
#---------------------------------------------
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
    xorl %edx, %edx
    movl %eax, %edx #zachowanie eax
    pushl %ebx     # ascii --> cyfra
    call charToInt
    addl $4, %esp
    movl %eax, %ebx #wartosc zwracana jest w eax
    cmpl base, %ebx
    jge faulting
    xorl %eax, %eax
    movl %edx, %eax #przywrocenie eax
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


#---------------------------------------------
#   Funkcja wykonująca mnożenie dwóch stringów
#   o danych długościach
#
#   argumenty:
#   8(%ebp) - długość string1
#   12(%ebp) - string2
#   16(%ebp) - string1
#   20(%ebp) - długość string2
#
#   Przykładowo:
#
#       56
#   *   67
#   -------
#     0392  <--- tempResult
#   + 3360  <--- tempResult
#   -------
#     3752  <--- finalResult
#
#
#   Przesunięcie tempResult (de facto uzupełnienie
#   zerami jest zawarte w etykietach afterResetResult
#   i loop.
#
#   uniwersalna dla systemów 2,10,16
#
#---------------------------------------------

.type multiplication, @function
multiplication: 
    pushl %ebp
    movl %esp, %ebp
    xorl %eax, %eax
    xorl %ebx, %ebx
    movl 20(%ebp), %eax
    movl 8(%ebp), %ebx
    movl %eax, lengthNumber1 # zachowujemy długość string2
    movl %ebx, lengthNumber2_2 # zachowujemy długość string1


prepareResult:
    cmpl $0, lengthNumber1 # jeśli nie ma czego mnożyć to nie mnożymy
    jl exitMultiplication
    xorl %edi, %edi
    movl size, %edi
    decl %edi # ostatnia pozycja ma indeks size - 1 bo liczymy od 0

resetResult: # resetujemy tempResult po każdym przejściu
    movb $0, tempResult(,%edi,1)
    decl %edi
    cmpl $0, %edi
    jge resetResult

afterResetResult:
    movl size, %edi
	xorl %ecx, %ecx 	
	decl %edi 
    movl size, %ecx
    subl elasticSize, %ecx
    decl elasticSize # z każdym przejściem pętli będziemy zaczynali od mniejszego o jeden indeksu

loop:
    cmpl $0, %ecx
    jle calculatorBegin
    movb $0, tempResult(,%edi,1)
    decl %edi
    decl %ecx
    jmp loop
    
calculatorBegin:
    xorl %ecx, %ecx
    xorl %edx, %edx
    movl 12(%ebp), %ecx # pod ecx będzie adres pierwszego znaku string2

    movl $0, firstNumberCurrentValue # pobieramy pierwszy (ostatni) znak z string2, który przemnożymy przez cały string1
	movl lengthNumber1, %edx # pobierz dlugosc pierwszej liczby do rejestru
    addl %edx, %ecx
	cmpl $0, %edx
	jl firstNumberEnd # jeśli przeszliśmy po całej liczbie to idziemy do firstNumberEnd
	xorl %ebx, %ebx	# wyzeruj ebx
	decl lengthNumber1 # dekrementacja dlugosci liczby by wczytac kolejna cyfre w nowej petli
	movb (%ecx), %bl # pobieranie znaku do ebx z adresu ecx
    xorl %ecx, %ecx

	pushl %ebx
	call charToInt
	addl $4, %esp    
    movl %eax, firstNumberCurrentValue
	jmp calculatorCont

firstNumberEnd:
    jmp exitMultiplication
    
calculatorCont:
    movl lengthNumber2_2, %edx # potrzeba zachować długość string1
    movl %edx, lengthNumber2 # więc operujemy na pomocniczym lengthNumber2
  
calculatorContinue:
    movl 16(%ebp), %ecx # pod ecx będzie adres pierwszego znaku string1
	xorl %eax, %eax	
	movl lengthNumber2, %edx # pobierz dlugosc drugiej liczby do rejestru
    addl %edx, %ecx
	cmpl $0, %edx	
	jl secondNumberEnd # jeśli przeszliśmy po całej liczbie to idziemy do firstNumberEnd
	decl lengthNumber2		
	movb (%ecx), %bl # pobieranie znaku do ebx
    xorl %ecx, %ecx

	pushl %ebx
	call charToInt
	addl $4, %esp
    jmp multiBegin

secondNumberEnd:
	cmpl $0, lengthNumber1
	jge multiBegin
	cmpl $0, lengthNumber2
	jge multiBegin
	cmpl $0, carry # możliwe że przeszliśmy po całej drugiej liczbie, lecz zostało przeniesienie
	jg multiBegin
	jmp outcome

multiBegin:
    xorl %ecx, %ecx
	imull firstNumberCurrentValue, %eax	# mnożymy wartość z string2 razy cały string1
	addl carry, %eax # dodajemy ewentualne przeniesienie
	movb $0, carry # zerujemy przeniesienie

compare:
	cmpl base, %eax # sprawdzanie czy nie wytworzyć przeniesienia
	jb savingResult
	subl base, %eax #jezeli wynik jest wiekszy od podstawy to odejmujemy podstawe...
	incl %ecx
	jmp compare

savingResult:
    movl %ecx, carry

	movb %al, tempResult(,%edi,1) # zapis do tempResult
	decl %edi # i dekrementujemy nasz rejestr przechodzacy po tempResult 
    
    xorl %ecx, %ecx
    movl lengthNumber2, %ecx
    cmpl $0, %ecx 
	jge calculatorContinue # jesli lengthNumber > -1 to kontynuujemy mnozenie przez druga liczbe

    xorl %ecx, %ecx
    movl carry, %ecx
    cmpl $0, %ecx   
    jne calculatorContinue # jesli mamy jeszcze przeniesienie to lecimy dalej

outcome:
    decl %edi
    cmpl $0, %edi
    jl outcome2
    movb $0, tempResult(,%edi,1) # uzupełniamy zerami tempResult aż do indeksu 0
    jmp outcome

outcome2:
    call addToFinalResult # dodajemy tempResult do FinalResult
    jmp prepareResult # idziemy na początek mnożenia

exitMultiplication:
    movl size, %eax
    movl %eax, elasticSize # przywrócenie wartości elasticSize

	movl %ebp, %esp
	popl %ebp
	ret


#---------------------------------------------
#   Funkcja przepisująca string do innego stringa
#
#   argumenty:
#   8(%ebp) - string do którego będziemy przepisywać
#   12(%ebp) - string który będziemy przepisywać
#
#---------------------------------------------

.type rewriting, @function
rewriting: 
    pushl %ebp
    movl %esp, %ebp
    xorl %edi, %edi
    xorl %ecx, %ecx
    xorl %edx, %edx
    movl 8(%ebp), %ecx
    movl 12(%ebp), %edx
rewrite:
    movb (%edx), %bl
    movb %bl, (%ecx)
    incl %ecx
    incl %edx
    incl %edi
    cmpl size, %edi
    jl rewrite

endRewriting:
	movl %ebp, %esp
	popl %ebp
	ret


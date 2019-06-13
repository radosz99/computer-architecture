#------------------------------------------------------------------------------
# program liczy calke oznaczona z:
# (0) - ln(x)
# (1) - sin(x)
# 
# granice podawane ze standardowego wejścia
# wynik wypisywany za pomocą standardowego wyjścia
# użyta jednostka zmiennoprzecinkowa (double)
#------------------------------------------------------------------------------

.section .bss

.lcomm upperLimit, 8
.lcomm lowerLimit, 8
.lcomm result, 8

.section .data

doubleFormat: .string "%f"
doublePrintFormat: .string "%f\n"
operation: .long 0
operationMessage: .string "Choose: \n (0) - integral of ln(x) \n (1) - integral of sin(x)\n"
firstMessage: .string "\nUpper limit: "
secondMessage: .string "Lower limit: "
firstMessageSinus: .string "\nUpper limit (radians): "
secondMessageSinus: .string "Lower limit (radians): "
resultMessage: .string "\nResult: "
format_input: .string "%d"

.section .text 
.globl _start 
_start:
    finit
    push $operationMessage
	call printf

	push $operation
	push $format_input
	call scanf

    cmpl $1, operation
    je integralSinus
    cmpl $0, operation
    je integralLogarithm
    jmp _start

integralLogarithm:

#------------------------------------------------------------------------------
# calka z ln(x) to (x * ln(x) - x)
# ln(x) = log_e_x --> niestety nie ma takiej funkcji, lecz:
# log_e_x = log_2_x / log_2_e --> takie funkcje juz mamy
#
# 1) dolna granica jest wrzucana na floating point stack 
# 2) systemowa wartosc log_2_e jest wrzucana na floating point stack
# 3) jedynka jest wrzucana na floating point stack
# 4) ponownie dolna granica jest wrzucana
#
# obecnie zawartosc stosu prezentuje sie nastepujaco:
# st0 - dolna granica (x)
# st1 - 1
# st2 - log_2_e
# st3 - dolna granica (x)
#
# za pomoca mnemoniku fyl2x wyliczamy log_2_st0 --> wynik zapisywany w st1
# i nastepuje zrzucenie ze stosu, ktorego obecna zawartosc wyglada tak:
# st7 - dolna granica (x)
# st0 - log_2_x
# st1 - log_2_e
# st2 - dolna granica (x)
#
# za pomoca mnemoniku fdivp dzielimy st0 przez st1 --> wynik zapisywany w st1
# i nastepuje zrzucenie ze stosu, ktorego obecna zawartosc wyglada tak:
# st6 - dolna granica (x)
# st7 - log_2_x
# st0 - log_2_x / log_2_e
# st1 - dolna granica (x)
#
# za pomoca mnemoniku fmul lowerLimit, mnozymy st0 razy dolna granice
# wynik zapisywany jest w st0:
# st6 - dolna granica (x)
# st7 - log_2_x
# st0 - x * (log_2_x / log_2_e)
# st1 - dolna granica (x)
#
# nastepnie odejmujemy za pomoca mnemoniku fsubp st0 - st1 i stos wyglada tak:
# st5 - dolna granica (x)
# st6 - log_2_x
# st7 - x * (log_2_x / log_2_e)
# st0 - x * (log_2_x / log_2_e) - x
#
# dla gornej granicy jest ta sama procedura, z ta roznica ze caly czas na stosie
# mamy wynik dla dolnej granicy, czyli po wykonaniu drugiej procedury:
# st5 - górna granica (y)
# st6 - log_2_y
# st7 - y * (log_2_y / log_2_e)
# st0 - y * (log_2_y / log_2_e) - y
# st1 - x * (log_2_x / log_2_e) - x
#
# po tym za pomoca mnemoniku fsubp odejmujemy wynik dolnej granicy (st0) od wyniku
# dla drugiej granicy i mamy wynik, ktory wrzucamy do result za pomoca fstl
#------------------------------------------------------------------------------

loadUpperLimit:
    pushl $firstMessage
    call printf
    addl $4, %esp

    pushl $upperLimit
    pushl $doubleFormat
    call scanf
    addl $8, %esp

loadLowerLimit:
    pushl $secondMessage
    call printf
    addl $4, %esp

    pushl $lowerLimit
    pushl $doubleFormat
    call scanf
    addl $8, %esp

calculateForLower:
    fld lowerLimit
    fldl2e
    fld1
    fld lowerLimit
    fyl2x
    fdivp #dzieli st0/st1
    fmul lowerLimit #mnozy st0 razy upperLimit
    fsubp #st0-st1

calculateForUpper:
    fld upperLimit
    fldl2e
    fld1
    fld upperLimit
    fyl2x
    fdivp #dzieli st0/st1
    fmul upperLimit #mnozy st0 razy upperLimit
    fsubp #st0-st1

showResult:
    fsubp #st0-st1, ostateczny wynik
    fstl result 

    pushl $resultMessage
    call printf
    addl $4, %esp

    fldl result
    subl $8, %esp
    fstl (%esp)

    pushl $doublePrintFormat
    call printf
    addl $12, %esp
    
    jmp exit

integralSinus:

#------------------------------------------------------------------------------
# calka z sin(x) to (-cos(x)) wiec oznaczona to: (-cos (x)) - (-cos(y)), czyli:
# cos(y) - cos(x) wiec najpierw obliczenia beda dla gornej granicy (x) tak zeby 
# znalazla sie w st1, a wynik dla dolnej granicy (y) w st2
#
# upperLimit jest wrzucane na stos i za pomoca mnemoniku fcos w st0 jest zapiswany
# cosinus z wartosci upperLimit, podobnie z lowerLimit
# na koniec odejmowanie zgodnie z tym co bylo wczesniej napisane
# wynik w radianach
#------------------------------------------------------------------------------

loadUpperLimit1:
    pushl $firstMessageSinus
    call printf
    addl $4, %esp

    pushl $upperLimit
    pushl $doubleFormat
    call scanf
    addl $8, %esp

loadLowerLimit1:
    pushl $secondMessageSinus
    call printf
    addl $4, %esp

    pushl $lowerLimit
    pushl $doubleFormat
    call scanf
    addl $8, %esp

calculateForUpper1:
    fld upperLimit
    fcos 

calculateForLower1:
    fld lowerLimit
    fcos 

showResult1:
    fsubp
    fstl result

    pushl $resultMessage
    call printf
    addl $4, %esp

    fldl result
    subl $8, %esp
    fstl (%esp)

    pushl $doublePrintFormat
    call printf
    addl $12, %esp

exit:
    movl $1, %eax 
    movl $0, %ebx 
    int $0x80


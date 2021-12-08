global string_length
global print_char
global print_newline
global print_string
global print_error
global print_uint
global print_int
global string_equals
global parse_uint
global parse_int
global read_word
global string_copy
global exit

%define sys_exit 60
%define sys_read 0
%define sys_write 1

%define stdin 0
%define stdout 1

%define newline 0xA
%define whitespace 0x20
%define tab 0x9

section .text

; Вспомогательная функция для вывода
sys_stdout:
    mov rax, sys_write                      ; Write system call number
    mov rdi, stdout                         ; file descriptor
    syscall
    ret

; Принимает код возврата и завершает текущий процесс
exit:
    mov rax, sys_exit                       ; Exit system call number
    syscall
    ret

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax                            ; in rax, we'll have our result, so rax have to be zeroed
    .string_length__loop:                   ; rdi -> val1, val2, ..., 0
        cmp byte[rdi + rax], 0              ; check for zero every char
        je .end                             ; jump to end if we get zero
        inc rax                             ; increment string length counter
        jmp .string_length__loop            ; jump to next iteration
    .end:
        ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    mov rsi, rdi                            ; write output string address to rsi
    call string_length                      ; rax = string_length
    mov rdx, rax                            ; rdx = string_length
    call sys_stdout                         ; print string (all arguments are set)
    ret

; Принимает код символа и выводит его в stdout
print_char:
    push rdi                                ; now rsp is a pointer to our char
    mov rsi, rsp                            ; rsp -> rsi
    mov rdx, 1                              ; size of our 'string'
    call sys_stdout                         ; print char (all arguments are set)
    add rsp, 8                              ; equivalent to pop without having the result
    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, newline                        ; rdi now has newline character
    call print_char                         ; call function with argument in rdi
    ret

; Выводит беззнаковое 8-байтовое число в десятичном формате
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    push r12                                ; save r12 (callee-saved)
    mov r12, rsp                            ; save rsp in r12
    mov rax, rdi
    dec rsp                                 ; allocate memory in stack for null terminator symbol
    mov byte[rsp], 0                        ; null terminator symbol at the top of the stack
    .div_loop:
        xor rdx, rdx
        push r13                            ; save r13
        mov r13, 10
        div r13                             ; divide rax by 10 (because of system base)
        pop r13                             ; restore r13
        add rdx, '0'                        ; (remainder in rdx)
                                            ; (number + 0x30) = ASCII(number)

        dec rsp                             ; move pointer
        mov  byte[rsp], dl                  ; save val at the top of the stack
        test rax, rax                       ; set zf
        jz .print                           ; if quotient(rax) is equal to zero, then print and end
        jmp .div_loop                       ; else continue iterating
    .print:
        mov rdi, rsp
        call print_string
        mov rsp, r12                        ; restore rsp from r12
        jmp .return
    .return:
        pop r12                             ; restore r12
        ret

; Выводит знаковое 8-байтовое число в десятичном формате
print_int:
    mov r9,0x8000000000000000               ; mask for defining sign of the number
    mov rax, rdi                            ; number in rdi and rax
    and r9, rax                             ; r9 = (r9 AND rax)
    test r9, r9                             ; if the r9 is zero, it means that the number was not-neg
    jz .not_neg
    push rax                                ; save rax
    mov  rdi, 0x2d                          ; ASCII of  '-'
    call print_char                         ; print '-'
    pop rax                                 ; restore rax
    neg rax                                 ; convert to not-neg number
    mov rdi, rax                            ; for function call store number in rdi
    .not_neg:
        call print_uint                     ; print as unsigned value ("-" char already should be printed or number is not-neg)
    ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
                                            ; pointers to str1 and str2 in rdi and rsi respectively
    .check_lengths_of_strings:
        call string_length
        mov r10, rax                        ; r10 = len(str1)
        xchg rdi, rsi                       ; swap(rdi, rsi)
        call string_length
        mov r11, rax                        ; r11 = len(str2)
        cmp r10,r11                         ; Are r10 and r11 equal?
        jne .not_equals                     ; return the value if not equals
    .init_regs:
        xor r10,r10                         ; r10 will have symbol
        xor rax, rax                        ; rax will have index of current char (i)
    .loop:
        mov r10b, byte[rdi+rax]             ; str1[i] -> r10b
        cmp r10b, byte[rsi+rax]             ; compare str1[i] and str2[i]
        jne .not_equals                     ; if str[1]!=str[2] our strings isn't equal
        cmp byte[rdi+rax], 0                ; if we get 0
        je .equals                          ; strings is equal
        inc rax                             ; i = i + 1
        jmp .loop                           ; next iteration
    .not_equals:                            ; returns 0
        xor rax, rax
        ret
    .equals:                                ; returns 1
        mov rax, 0x1
        ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    mov rax, sys_read                       ; Read system call number
    mov rdi, stdin                          ; file descriptor
    mov rdx, 1                              ; size
    push 0                                  ; allocate memory for our read symbol
    mov rsi, rsp                            ; pointer to read symbol
    syscall                                 ; our symbol in stack
    pop rax                                 ; 'deleting' our symbol from stack and get it in rax
    ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
    xor rcx, rcx                            ; init rcx and save regs  values
    mov r8, rdi
    mov r9, rsi
    mov r10, rcx                            ; counter r10 = 0
    .loop:
        call read_char                      ; read char and check for space_symbols
        cmp al, whitespace
        je .space_symbol
        cmp al, tab
        je .space_symbol
        cmp al, newline
        je .space_symbol
        cmp rax, 0                          ; check for end of input
        je .return
        mov [r8 + r10], rax                 ; save char to buffer
        inc r10                             ; counter++
        cmp r10, r9                         ; check for overflow
        jge .buffer_overflow                ; if counter >= buffer_length, then error
        jmp .loop                           ; else continue iterating
    .space_symbol:
        cmp r10, 0                          ; if counter == 0, then it is start of the word (mean whitespaces)
        je .loop                            ; whitespaces, then continue iterating
        jmp .return                         ; not whitespaces, then new word starting, break and return
    .buffer_overflow:
        xor rdx, rdx                        ; return zeroes
        xor rax, rax
        ret
    .return:
        mov byte [r8 + r10], 0              ; push_back null terminator
        mov rax, r8                         ; set return values
        mov rdx, r10
        ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rax, rax                            ; rax - parsed number
    xor rcx, rcx                            ; rcx - counter
    xor rdx, rdx                            ; rdx - len of number
    xor rsi, rsi                            ; char for parse
    mov r8, 10                              ; multiplier for every iteration
    .loop:
        mov sil, byte[rdi + rcx]            ; read char in sil (byte of rsi)
        cmp sil, '0'                        ; check for ['0'; '9'] segment
        jl .return
        cmp sil, '9'
        jg .return
        inc rcx                             ; counter++ for next iteration
        sub sil, '0'                        ; convert from char to number
        mul r8                              ; next digit
        add rax, rsi                        ; cur digit
        jmp .loop                           ; continue
    .return:
        xor rdx, rcx
        ret

; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был)
; rdx = 0 если число прочитать не удалось
parse_int:
    xor rax, rax
    cmp byte[rdi], '-'                      ; check for sign
    je .signed                              ; if signed, then process it
    call parse_uint                         ; else just do like uint
    ret
    .signed:
        inc rdi                             ; skip '-'
        call parse_uint                     ; parse like uint
        cmp rdx, 0                          ; if nan, return
        je .return
        neg rax                             ; Complement code of neg number
        inc rdx                             ; because of sign
    .return:
        ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    call string_length                      ; strlen -> rax
    inc rax                                 ; rax++ (null terminator)
    cmp rax, rdx                            ; compare length of buffer and string
    jg .long_string_exit                    ; if string is too long exit
    xor rcx, rcx                            ; reset the registers used for cycles
    xor rax, rax
    .copy_loop:
        mov rcx, [rdi + rax]                ; char from string  to r10
        mov [rsi + rax], rcx                ; r10 to buffer
        inc rax                             ; rax set for next iteration
        cmp byte[rdi + rax], 0              ; null terminator check
        jne .copy_loop                      ; jump to next iteration
        ret                                 ; rax is equal to strlen
    .long_string_exit:
        xor rax, rax
        ret
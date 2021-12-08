section .text

%define ID_ERR "First token in the parameter must exist and be an identifier (first character is a letter or "_" or ".")"
%define STR_ERR "Key must be string"
%define BUFFER_SIZE 255
%define KEY_SHIFT 8
%include "colon.inc"
%include "lib.inc"
%define newline 0xA
extern find_word
global _start

section .data
input_string_buffer: times BUFFER_SIZE db 0                             ; buffer

buffer_overflow: db "The key length is more than 255",   newline, 0     ; messages
key_not_found:   db "The key isn't exist in dictionary", newline, 0

%include "words.inc"

section .text
    _start:
        mov rdi, input_string_buffer                                    ; set args for read_word call
        mov rsi, BUFFER_SIZE
        call read_word                                                  ; returns 0 if we can't read word
        push rdx                                                        ; save key length
        je .buffer_overflow_exc
        mov rdi, rax                                                    ; set args for find_word call
        mov rsi, CURRENT_START
        call find_word
        cmp rax, 0
        je .key_not_found_exc
        add rax, KEY_SHIFT                                              ; to get value of key, we add KEY_SHIFT
        pop rdx
        add rax, rdx                                                    ; and key length
        inc rax                                                         ; inc because of added null terminator
        mov rdi, rax                                                    ; set arg for value printing
        jmp .end
    .buffer_overflow_exc:
        mov rdi, buffer_overflow                                        ; set arg for error message printing
        jmp .end
    .key_not_found_exc:
        mov rdi, key_not_found                                          ; set arg for error message printing
        jmp .end
    .end:
        call print_string
        call exit

%include "lib.inc"
%define KEY_SHIFT 8
global find_word

find_word:                                      ; args: rdi->null-terminated string, rsi->start of the dict
    push r12                                    ; save callee-saved reg for func uses
    .loop:
        cmp rsi, 0                              ; check is it end of the list?
        je .not_found
        push rdi
        push rsi
        add rsi, KEY_SHIFT                      ; now rsi is pointer to key (skip 8 byte of next node pointer)
        call string_equals                      ; checking for equals of the input string and node key
        pop rsi
        pop rdi
        cmp rax, 1                              ; string_equals returns 1, if they equal
        je .found
    .next:
        mov r12, [rsi]                          ; we need r12 like extra temp for updating rsi val
        mov rsi, r12                            ; list = list->next
        jmp .loop                               ; if we don't find it, we'll continue iterating
    .found:
        mov rax, rsi                            ; return found node of the list
        jmp .end
    .not_found:
        xor rax, rax                            ; return 0
    .end:
        pop r12                                 ; restore temp
        ret

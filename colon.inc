; colon macro
%define CURRENT_START 0
%macro colon 2                                      ; 1: key value, 2: label
    %ifid %2                                        ; label must be identifier (explanation below in "%fatal" text)
        %2:                                         ; declare label
            dq CURRENT_START                        ; init pointer to next of the node of linked list
            %define CURRENT_START %2                ; change NEXT_INDEX for next entry
    %else
        fatal ID_ERR                                ; err
    %endif

    %ifstr %1                                       ; key value must be string
        db %1, 0                                    ; null-terminated value
    %else
        fatal STR_ERR                               ; err
    %endif
%endmacro

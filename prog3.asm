; ==========================================================
; Program 3: Automatic Progressive Counter in Base 16
; Counts from 0h to Fh using CMP and JNZ (conditional jumps)
; and prints each hexadecimal digit on the screen.
; Assembler: MASM / TASM (16-bit, run under DOSBox)
; ==========================================================
.MODEL SMALL
.STACK 100h
 
.DATA
    msgTitle DB 'Hexadecimal counter from 0h to Fh:',0Dh,0Ah,'$'
    msgEnd   DB 0Dh,0Ah,'Done.$'
 
.CODE
MAIN PROC
    mov  ax, @data         ; initialize the data segment
    mov  ds, ax
 
    lea  dx, msgTitle
    mov  ah, 09h           ; INT 21h, AH=09h: print string
    int  21h
 
    mov  bl, 0             ; BL = counter, starts exactly at 0h
 
COUNT_LOOP:
    mov  al, bl            ; AL = current value (0..15)
    cmp  al, 9             ; digit 0-9 or letter A-F?
    jbe  IS_DIGIT
    add  al, 37h           ; 0Ah..0Fh -> 'A'..'F'
    jmp  PRINT_IT
IS_DIGIT:
    add  al, 30h           ; 0..9 -> '0'..'9'
PRINT_IT:
    mov  dl, al
    mov  ah, 02h           ; INT 21h, AH=02h: print the character in DL
    int  21h
    mov  dl, ' '           ; separator space
    mov  ah, 02h
    int  21h
 
    inc  bl                ; next value
    cmp  bl, 10h           ; have we passed Fh?
    jnz  COUNT_LOOP        ; no: repeat
 
    lea  dx, msgEnd
    mov  ah, 09h
    int  21h
 
    mov  ax, 4C00h         ; INT 21h, AH=4Ch: return control to the OS
    int  21h
MAIN ENDP
 
END MAIN

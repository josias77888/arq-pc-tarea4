; ==========================================================
; Program 1: Direct Hexadecimal Arithmetic Calculator
; Reads two bytes in hex (00h-FFh) and an operator (+ or -),
; executes ADD or SUB on CPU registers and prints the result
; in hexadecimal, reporting the Carry Flag (CF).
; Assembler: MASM / TASM (16-bit, run under DOSBox)
; ==========================================================
.MODEL SMALL
.STACK 100h
 
.DATA
    msgA     DB 'Enter first byte in hex (00-FF): $'
    msgB     DB 0Dh,0Ah,'Enter second byte in hex (00-FF): $'
    msgOp    DB 0Dh,0Ah,'Enter operator (+ or -): $'
    msgRes   DB 0Dh,0Ah,0Dh,0Ah,'Result (hex): $'
    msgCF    DB 0Dh,0Ah,'Carry/Borrow flag (CF) = $'
    msgCar   DB 0Dh,0Ah,'Carry occurred: the result needs 9 bits.$'
    msgBor   DB 0Dh,0Ah,'Borrow occurred: negative result (8-bit complement).$'
    msgErr   DB 0Dh,0Ah,'Invalid input. Program ended.$'
    valA     DB ?          ; first operand
    valB     DB ?          ; second operand
    oper     DB ?          ; operator character
    outByte  DB ?          ; 8-bit result
    carry    DB ?          ; copy of CF after ADD/SUB
 
.CODE
MAIN PROC
    mov  ax, @data         ; initialize the data segment
    mov  ds, ax
 
    ; ---- read first operand ----
    lea  dx, msgA
    mov  ah, 09h           ; INT 21h, AH=09h: print '$'-terminated string
    int  21h
    call READ_HEX_BYTE     ; AL = byte read
    mov  valA, al
 
    ; ---- read second operand ----
    lea  dx, msgB
    mov  ah, 09h
    int  21h
    call READ_HEX_BYTE
    mov  valB, al
 
    ; ---- read operator ----
    lea  dx, msgOp
    mov  ah, 09h
    int  21h
    mov  ah, 01h           ; INT 21h, AH=01h: read one character (echo)
    int  21h
    mov  oper, al
 
    ; ---- execute the operation on CPU registers ----
    mov  al, valA          ; AL = first operand
    mov  bl, valB          ; BL = second operand
    mov  ah, 0             ; AH will hold the Carry Flag
    cmp  oper, '+'
    je   DO_ADD
    cmp  oper, '-'
    je   DO_SUB
    call BAD_INPUT         ; any other character ends the program
 
DO_ADD:
    add  al, bl            ; AL = AL + BL, CF = carry out
    jmp  SAVE_CF
DO_SUB:
    sub  al, bl            ; AL = AL - BL, CF = borrow
SAVE_CF:
    adc  ah, 0             ; AH = 0 + 0 + CF  (captures the flag)
    mov  outByte, al
    mov  carry, ah
 
    ; ---- print the result ----
    lea  dx, msgRes
    mov  ah, 09h
    int  21h
    cmp  oper, '+'
    jnz  PRINT_BYTE
    cmp  carry, 1
    jnz  PRINT_BYTE
    mov  dl, '1'           ; ADD with carry: the 9th bit is shown as '1'
    mov  ah, 02h           ; INT 21h, AH=02h: print the character in DL
    int  21h
PRINT_BYTE:
    mov  al, outByte
    call PRINT_HEX_BYTE
    mov  dl, 'h'
    mov  ah, 02h
    int  21h
 
    ; ---- print the Carry Flag ----
    lea  dx, msgCF
    mov  ah, 09h
    int  21h
    mov  dl, carry
    add  dl, 30h           ; 0 -> '0', 1 -> '1'
    mov  ah, 02h
    int  21h
 
    cmp  carry, 0
    jz   FINISH
    cmp  oper, '+'
    jnz  SHOW_BORROW
    lea  dx, msgCar
    mov  ah, 09h
    int  21h
    jmp  FINISH
SHOW_BORROW:
    lea  dx, msgBor
    mov  ah, 09h
    int  21h
 
FINISH:
    mov  ax, 4C00h         ; INT 21h, AH=4Ch: return control to the OS
    int  21h
MAIN ENDP
 
; ----------------------------------------------------------
; READ_HEX_DIGIT: reads one key and converts it to 0..15 in AL
; ----------------------------------------------------------
READ_HEX_DIGIT PROC
    mov  ah, 01h
    int  21h               ; AL = ASCII code of the key
    cmp  al, '0'
    jb   RHD_BAD
    cmp  al, '9'
    jbe  RHD_NUM
    cmp  al, 'A'
    jb   RHD_BAD
    cmp  al, 'F'
    jbe  RHD_UP
    cmp  al, 'a'
    jb   RHD_BAD
    cmp  al, 'f'
    ja   RHD_BAD
    sub  al, 57h           ; 'a' (61h) -> 0Ah
    ret
RHD_UP:
    sub  al, 37h           ; 'A' (41h) -> 0Ah
    ret
RHD_NUM:
    sub  al, 30h           ; '0' (30h) -> 00h
    ret
RHD_BAD:
    call BAD_INPUT
    ret
READ_HEX_DIGIT ENDP
 
; ----------------------------------------------------------
; READ_HEX_BYTE: reads two hex digits and returns the byte in AL
; ----------------------------------------------------------
READ_HEX_BYTE PROC
    push bx
    push cx
    call READ_HEX_DIGIT    ; high nibble
    mov  bl, al
    mov  cl, 4
    shl  bl, cl            ; move it to the upper 4 bits
    call READ_HEX_DIGIT    ; low nibble
    or   al, bl            ; combine both nibbles
    pop  cx
    pop  bx
    ret
READ_HEX_BYTE ENDP
 
; ----------------------------------------------------------
; PRINT_HEX_BYTE: prints AL as two hexadecimal digits
; ----------------------------------------------------------
PRINT_HEX_BYTE PROC
    push ax
    push cx
    push dx
    mov  dh, al            ; keep a copy of the byte
    mov  cl, 4
    shr  al, cl            ; high nibble
    call PRINT_NIBBLE
    mov  al, dh
    and  al, 0Fh           ; low nibble
    call PRINT_NIBBLE
    pop  dx
    pop  cx
    pop  ax
    ret
PRINT_HEX_BYTE ENDP
 
; ----------------------------------------------------------
; PRINT_NIBBLE: prints the value 0..15 in AL as '0'..'F'
; ----------------------------------------------------------
PRINT_NIBBLE PROC
    push ax
    push dx
    cmp  al, 9
    jbe  PN_DIGIT
    add  al, 37h           ; 0Ah -> 'A'
    jmp  PN_PRINT
PN_DIGIT:
    add  al, 30h           ; 0 -> '0'
PN_PRINT:
    mov  dl, al
    mov  ah, 02h
    int  21h
    pop  dx
    pop  ax
    ret
PRINT_NIBBLE ENDP
 
; ----------------------------------------------------------
; BAD_INPUT: prints an error and ends the program (never returns)
; ----------------------------------------------------------
BAD_INPUT PROC
    lea  dx, msgErr
    mov  ah, 09h
    int  21h
    mov  ax, 4C01h         ; exit with error code 1
    int  21h
    ret
BAD_INPUT ENDP
 
END MAIN

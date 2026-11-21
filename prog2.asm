; ==========================================================
; Program 2: Logical Mask Operator (AND / OR / XOR)
; Reads one byte in hex, applies an internal bit mask with a
; Boolean instruction and prints the result as 8-bit binary.
; Assembler: MASM / TASM (16-bit, run under DOSBox)
; ==========================================================
.MODEL SMALL
.STACK 100h
 
MASK_AND EQU 11110000b     ; AND clears (turns off) the 4 low bits
MASK_OR  EQU 10000001b     ; OR turns on bit 7 and bit 0
MASK_XOR EQU 00001111b     ; XOR inverts the 4 low bits
 
.DATA
    msgIn    DB 'Enter one byte in hex (00-FF): $'
    msgOrig  DB 0Dh,0Ah,'Original value (binary): $'
    msgOp    DB 0Dh,0Ah,'Choose operation: (A)ND, (O)R, (X)OR: $'
    msgMask  DB 0Dh,0Ah,'Mask applied (binary):   $'
    msgRes   DB 0Dh,0Ah,'Result (binary):         $'
    msgErr   DB 0Dh,0Ah,'Invalid input. Program ended.$'
    value    DB ?
 
.CODE
MAIN PROC
    mov  ax, @data         ; initialize the data segment
    mov  ds, ax
 
    ; ---- read the byte ----
    lea  dx, msgIn
    mov  ah, 09h           ; INT 21h, AH=09h: print string
    int  21h
    call READ_HEX_BYTE     ; AL = byte
    mov  value, al
 
    ; ---- show it in binary ----
    lea  dx, msgOrig
    mov  ah, 09h
    int  21h
    mov  al, value
    call PRINT_BIN_BYTE
 
    ; ---- choose the operation ----
    lea  dx, msgOp
    mov  ah, 09h
    int  21h
    mov  ah, 01h           ; INT 21h, AH=01h: read a key (echo)
    int  21h
    and  al, 11011111b     ; clear bit 5: lowercase -> uppercase
 
    mov  bl, value         ; BL = working copy of the byte
    cmp  al, 'A'
    je   DO_AND
    cmp  al, 'O'
    je   DO_OR
    cmp  al, 'X'
    je   DO_XOR
    call BAD_INPUT         ; any other key ends the program
 
DO_AND:
    mov  bh, MASK_AND      ; BH = mask
    and  bl, bh            ; bits with 0 in the mask are cleared
    jmp  SHOW
DO_OR:
    mov  bh, MASK_OR
    or   bl, bh            ; bits with 1 in the mask are set
    jmp  SHOW
DO_XOR:
    mov  bh, MASK_XOR
    xor  bl, bh            ; bits with 1 in the mask are flipped
 
SHOW:
    lea  dx, msgMask
    mov  ah, 09h
    int  21h
    mov  al, bh
    call PRINT_BIN_BYTE    ; print the mask
 
    lea  dx, msgRes
    mov  ah, 09h
    int  21h
    mov  al, bl
    call PRINT_BIN_BYTE    ; print the result
 
    mov  ax, 4C00h         ; INT 21h, AH=4Ch: return control to the OS
    int  21h
MAIN ENDP
 
; ----------------------------------------------------------
; READ_HEX_DIGIT: reads one key and converts it to 0..15 in AL
; ----------------------------------------------------------
READ_HEX_DIGIT PROC
    mov  ah, 01h
    int  21h
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
    sub  al, 57h
    ret
RHD_UP:
    sub  al, 37h
    ret
RHD_NUM:
    sub  al, 30h
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
    call READ_HEX_DIGIT
    mov  bl, al
    mov  cl, 4
    shl  bl, cl
    call READ_HEX_DIGIT
    or   al, bl
    pop  cx
    pop  bx
    ret
READ_HEX_BYTE ENDP
 
; ----------------------------------------------------------
; PRINT_BIN_BYTE: prints AL as 8 binary digits (MSB first)
; ----------------------------------------------------------
PRINT_BIN_BYTE PROC
    push ax
    push bx
    push cx
    push dx
    mov  bl, al            ; working copy
    mov  cx, 8             ; 8 bits to print
PBB_LOOP:
    shl  bl, 1             ; MSB goes into CF
    mov  dl, '0'
    adc  dl, 0             ; '0' + CF = '0' or '1'
    mov  ah, 02h
    int  21h
    loop PBB_LOOP
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
PRINT_BIN_BYTE ENDP
 
; ----------------------------------------------------------
; BAD_INPUT: prints an error and ends the program (never returns)
; ----------------------------------------------------------
BAD_INPUT PROC
    lea  dx, msgErr
    mov  ah, 09h
    int  21h
    mov  ax, 4C01h
    int  21h
    ret
BAD_INPUT ENDP
 
END MAIN

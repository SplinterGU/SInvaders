; *************************************************************************
; Convert the Y AND X pixel values TO the correct Screen Address  - Address in DE
;
; IN:
;   b       row
;   c       col
;
; OUT:
;   de      screen addr
;
; MODIFIED REGISTERS
;   a
;   de
;

define( `GET_SCREEN_ADDR', `
IFDEF __ZX81__
    push hl

    ld de,(16518)

    ld l,b
    ld h,0
    
    ; row x 32
    add hl,hl ; x2
    add hl,hl ; x4
    add hl,hl ; x8
    add hl,hl ; x16
    add hl,hl ; x32

    ; col / 8
    ld a,c
    srl a
    srl a
    srl a
    add a,l
    ld l,a
    ld a,0
    adc a,h
    ld h,a

    add hl,de
    pop de
    ex de,hl
ENDIF
IFDEF __SPECTRUM__
    ; 77t
    ex de,hl
    ld h, ScreenTables/256
    ld l,b
    ld a,(hl)

    inc h
    ld l,(hl)
    ld h,a

    ld a,c
    srl a
    srl a
    srl a

    add a,l
    ld l,a
    ex de,hl
ENDIF
')

; **************************************************************************************************+
; Sprite and Print functions
; by Juan Jose Ponteprino
; **************************************************************************************************'

SECTION data_user

rotate_bits:
    db 0

IFDEF __SPECTRUM__
EXTERN ScreenTables
ENDIF

EXTERN _CHARSET

SECTION code_user

PUBLIC _PutSprite1, _PutSprite1Merge, _PutSprite1Delete, _PutSprite2, _PutSprite3, _PrintChar
PUBLIC _PutSprite1_internal, _PutSprite1M_internal, _PutSprite1D_internal, _PutSprite2_internal

; **************************************************************************************************'
; (byte x, byte y, void * spr)
; **************************************************************************************************'

_PutSprite1:
    pop hl                  ; return
    pop bc                  ; coordenadas
    ex (sp),hl              ; sprite

_PutSprite1_internal:

    ; hl: sprite address
    ; b: y
    ; c: x

    GET_SCREEN_ADDR
                            ; hl => sprite data
                            ; de => target
    ld a,c
    and 7
    ld (rotate_bits),a

    ld a,8                  ; set counter TO 8 - Bytes of Character Data TO put down

Loop1:
IFDEF __ZX81__
    push af                 ; save off Counter
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF    
    ld a,(rotate_bits)      ; a = posiciones a rotar
    or a
    jr z, norotate1         ; if the the X value is on an actual Character boundary i.e. there's no need to shift anything

    push hl                 ; Data Address
    push de                 ; Screen Address

    ld b,a                  ; rotate times

    xor a
    ld e,(hl)
    ld d,a
    ld c,255

rotate1:
    srl e                   ; rotate sprite
    rr d

    srl c                   ; rotate mask
    rra
    djnz rotate1

    ld b,a                  ; mascara = c, b 
                
    pop hl                  ; recupero direccion destino

    ld a,c
    cpl
    ld c,a

    ld a,b
    cpl
    ld b,a

    ld a,(hl)               ; 1er byte rotado del sprite (con mascara)
    and c
    or e
    ld (hl),a

    inc l
    ld a,(hl)               ; 2er byte rotado del sprite (con mascara)
    and b
    or d
    ld (hl),a

    dec l
    ex de,hl

    pop hl                  ; get the Address of the Character Data back AND increment it ready FOR the NEXT BYTE of data

row_complete1:
IFDEF __ZX81__
    ld a,32
    add a,e
    ld e,a
    ld a,0
    adc a,d
    ld d,a                  ; it AND Increment the Y value in B AS well
ENDIF
IFDEF __SPECTRUM__
    inc d                   ; it AND Increment the Y value in B AS well

    ld a,d                  ; now check IF the Y value has gone OVER a Character Boundary i.e. we will need TO recalculate the Screen
                            ; Address IF we've jumped from one Character Line to another - messy but necessary especially for lines 7 and 15   '
    and 7
    jp nz, addr_ok1
    ld a,e
    add 32
    ld e,a
    jp c, addr_ok1
    ld a,d
    sub 8
    ld d,a

addr_ok1:
ENDIF

    inc hl

IFDEF __ZX81__
    pop af                  ; get the Counter value back, decrement it AND GO back FOR another write IF we haven't reached the end yet   '
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF    
    dec a
    jp nz, Loop1
    ret

norotate1:
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting
    ld (de),a

    jp row_complete1


; **************************************************************************************************'
; (byte x, byte y, void * spr)
; **************************************************************************************************'

_PutSprite1Merge:           ; Merge
    pop hl                  ; return
    pop bc                  ; coordenadas
    ex (sp),hl              ; sprite

_PutSprite1M_internal:

    ; hl: sprite address
    ; b: y
    ; c: x

    GET_SCREEN_ADDR
                            ; hl => sprite data
                            ; de => target

    ld a,c
    and 7
    ld (rotate_bits),a

    ld a,8                  ; set counter TO 8 - Bytes of Character Data TO put down

Loop1M:
IFDEF __ZX81__
    push af                 ; save off Counter
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF

    ld a,(rotate_bits)      ; a = posiciones a rotar
    or a
    jr z, norotate1M        ; if the the X value is on an actual Character boundary i.e. there's no need to shift anything

    ld b,a                  ; rotate times

    ld c,(hl)
    xor a

rotate1M:
    srl c                   ; rotate sprite
    rra
    djnz rotate1M

    ld b,a
                
    ld a,(de)               ; 1er byte rotado del sprite (con mascara)
    or c
    ld (de),a

    inc e
    ld a,(de)               ; 2er byte rotado del sprite (con mascara)
    or b
    ld (de),a

    dec e

row_complete1M:
IFDEF __ZX81__
    ld a,32
    add a,e
    ld e,a
    ld a,0
    adc a,d
    ld d,a                  ; it AND Increment the Y value in B AS well
ENDIF
IFDEF __SPECTRUM__
    inc d                   ; it AND Increment the Y value in B AS well
    
    ld a,d                  ; now check IF the Y value has gone OVER a Character Boundary i.e. we will need TO recalculate the Screen
                            ; Address IF we've jumped from one Character Line to another - messy but necessary especially for lines 7 and 15   '
    and 7
    jp nz, addr_ok1M
    ld a,e
    add 32
    ld e,a
    jp c, addr_ok1M
    ld a,d
    sub 8
    ld d,a

addr_ok1M:
ENDIF

    inc hl

IFDEF __ZX81__
    pop af                  ; get the Counter value back, decrement it AND GO back FOR another write IF we haven't reached the end yet   '
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF    
    dec a
    jp nz, Loop1M
    ret

norotate1M:
    ld a,(de)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting
    or (hl)
    ld (de),a

    jp row_complete1M

; **************************************************************************************************'
; (byte x, byte y, void * spr)
; **************************************************************************************************'

_PutSprite1Delete:
    pop hl                  ; return
    pop bc                  ; coordenadas
    ex (sp),hl              ; sprite

_PutSprite1D_internal:

    ; hl: sprite address
    ; b: y
    ; c: x

    GET_SCREEN_ADDR
                            ; hl => sprite data
                            ; de => target

    ld a,c
    and 7
    ld (rotate_bits),a

    ld a,8                  ; set counter TO 8 - Bytes of Character Data TO put down

Loop1D:
IFDEF __ZX81__
    push af                 ; save off Counter
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF    
    ld a,(rotate_bits)      ; a = posiciones a rotar
    or a
    jr z, norotate1D        ; if the the X value is on an actual Character boundary i.e. there's no need to shift anything

    ld b,a                  ; rotate times

    ld c,(hl)
    xor a

rotate1D:
    srl c                   ; rotate sprite
    rra
    djnz rotate1D

    cpl
    ld b,a

    ld a,c
    cpl
    ld c,a

    ld a,(de)               ; 1er byte rotado del sprite (con mascara)
    and c
    ld (de),a

    inc e
    ld a,(de)               ; 2er byte rotado del sprite (con mascara)
    and b
    ld (de),a

    dec e

row_complete1D:
IFDEF __ZX81__
    ld a,32
    add a,e
    ld e,a
    ld a,0
    adc a,d
    ld d,a                  ; it AND Increment the Y value in B AS well
ENDIF
IFDEF __SPECTRUM__
    inc d                   ; it AND Increment the Y value in B AS well

    ld a,d                  ; now check IF the Y value has gone OVER a Character Boundary i.e. we will need TO recalculate the Screen
                            ; Address IF we've jumped from one Character Line to another - messy but necessary especially for lines 7 and 15   '
    and 7
    jp nz, addr_ok1D
    ld a,e
    add 32
    ld e,a
    jp c, addr_ok1D
    ld a,d
    sub 8
    ld d,a

addr_ok1D:
ENDIF

    inc hl

IFDEF __ZX81__
    pop af                  ; get the Counter value back, decrement it AND GO back FOR another write IF we haven't reached the end yet   '
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF    
    dec a
    jp nz, Loop1D
    ret

norotate1D:
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting
    ex de,hl
    cpl
    and (hl)
    ld (hl),a
    ex de, hl

    jp row_complete1D


; **************************************************************************************************'
; (byte x, byte y, void * spr)
; **************************************************************************************************'

_PutSprite2:
    pop hl      ; return
    pop bc      ; coordenadas
    ex (sp),hl  ; sprite

_PutSprite2_internal:

    ; hl: sprite address
    ; b: y
    ; c: x

    GET_SCREEN_ADDR
                            ; hl => sprite data
                            ; de => target

    ld a,c
    and 7
    ld (rotate_bits),a

    ld a,8                  ; set counter TO 8 - Bytes of Character Data TO put down

Loop2:
IFDEF __ZX81__
    push af                 ; save off Counter
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF
    push hl                 ; save off Address of Character Data, Screen Address, Screen Address

    ld a,(rotate_bits)      ; a = posiciones a rotar
    or a
    jr z, norotate2         ; if the the X value is on an actual Character boundary i.e. there's no need to shift anything

    push de                 ; Screen Address
;    push de                 ; Screen Address

    ld b,a                  ; rotate times

    ld e,(hl)
    inc hl
    ld d,(hl)
    xor a
    ld h,255
    ld l,a

rotate2:
    srl e                   ; rotate sprite
    rr d
    rra

    srl h                   ; rotate mask
    rr l
    djnz rotate2

    ld c, h                 ; mascara = c, $ff, b 
    ld b, l
                
    pop hl                  ; recupero direccion destino

    push af                 ; guardo sprite rotado

    ld a,c
    cpl
    ld c,a

    ld a,b
    cpl
    ld b,a

    ld a,(hl)               ; 1er byte rotado del sprite (con mascara)
    and c
    or e
    ld (hl),a

    ld c,d                  ; 2do byte rotado lo paso a c
    pop de                  ; 3er recupero byte rotado (push af)

    inc l                   ; Increment the Screen Address AND check TO see IF it's at the end of a line,
    ld a,l
    and 31                  ; if so THEN there's no need to put down the second part of the sprite
    jp z, row_complete2b2

    ld (hl),c               ; 2do byte rotado del sprite (va directo, sin mascara)

    inc l
    ld a,l
    and 31                  ; if so THEN there's no need to put down the 3rd part of the sprite
    jp z, row_complete2b1

    ld a,(hl)               ; 3er byte rotado del sprite (con mascara)
    and b
    or d
    ld (hl),a

row_complete2b1:
    dec l
row_complete2b2:
    dec l
    ex de,hl

row_complete2b:
;    pop de                  ; get the Screen Address back into DE, increment Y

row_complete2:
IFDEF __ZX81__
    ld a,32
    add a,e
    ld e,a
    ld a,0
    adc a,d
    ld d,a                  ; it AND Increment the Y value in B AS well
ENDIF
IFDEF __SPECTRUM__
    inc d                   ; it AND Increment the Y value in B AS well
    ld a,d                  ; now check IF the Y value has gone OVER a Character Boundary i.e. we will need TO recalculate the Screen
                            ; Address IF we've jumped from one Character Line to another - messy but necessary especially for lines 7 and 15   '
    and 7
    jp nz, addr_ok2
    ld a,e
    add 32
    ld e,a
    jp c, addr_ok2
    ld a,d
    sub 8
    ld d,a

addr_ok2:
ENDIF

    pop hl                  ; get the Address of the Character Data back AND increment it ready FOR the NEXT BYTE of data
    inc hl
    inc hl

IFDEF __ZX81__
    pop af                  ; get the Counter value back, decrement it AND GO back FOR another write IF we haven't reached the end yet   '
ENDIF
IFDEF __SPECTRUM__
    ex af,af'
ENDIF    
    dec a
    jp nz, Loop2
    ret

norotate2:
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting
    ld (de),a

    inc hl

    inc e
    ld a,e
    and 31                  ; if so THEN there's no need to put down the 3rd part of the sprite
    jp z, skip_2nd_byte2

    ld a,(hl)
    ld (de),a
skip_2nd_byte2:
    dec e

    jp row_complete2

; -------------------------------------------------------
; (byte x, byte y, byte char, byte mode )

_PrintChar:
    pop hl
    pop bc
    ex (sp), hl   ; l = char, h = mode

    ex de, hl     ; e = char, d = mode

IFDEF _CHARSET
    ld a,e
    sub a,32
    ld l,a
ELSE
    ld l,e
ENDIF
    ld h,0

    ld a,d

    add hl,hl
    add hl,hl
    add hl,hl

IFDEF _CHARSET
    ld de, _CHARSET
ELSE
    ld de, (23606)
ENDIF
    add hl,de

    and a
    jp z, _PutSprite1_internal
    dec a
    jp z, _PutSprite1M_internal
    dec a
    jp z, _PutSprite1D_internal
    ret

; -------------------------------------------------------
; (byte x, byte y, void * spr)

_PutSprite3:
    pop hl      ; return
    pop bc      ; coordenadas
    ex (sp),hl  ; sprite

    push bc
    push hl

    call _PutSprite2_internal

    pop hl
    pop bc

    ld a,c
    add 16
    ld c,a

    ld de, 16
    add hl, de

    jp _PutSprite1_internal

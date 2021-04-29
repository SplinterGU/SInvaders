IFNDEF __ZX81__
EXTERN ScreenTables
ENDIF

SECTION code_user

PUBLIC _Point, _Point_internal

; ( x as ubyte, y as ubyte ) as byte
_Point:
    pop hl
    pop bc
    push hl

_Point_internal:

    ;  c: x = col
    ;  b: y = row

    ; switch row <-> col
    ld a,c ; col
    ld c,b ; row
    ld b,a ; col

    ;  b: x = col
    ;  c: y = row

    srl a
    srl a
    srl a
IFNDEF __ZX81__
    ld d,a

    ld h, ScreenTables/256
    ld l,c
    ld a,(hl)

    inc h
    ld l,(hl)
    ld h,a

    ld a,l
    add a,d
    ld l,a
ELSE
    ld e,a
    xor a
    ld d,a
    ld l,c
    ld h,a
    ; row x 32
    add hl,hl ; x2
    add hl,hl ; x4
    add hl,hl ; x8
    add hl,hl ; x16
    add hl,hl ; x32
    add hl,de
    ld de,(16518)
    add hl,de
ENDIF
    ld a,b
    and 7
    ld b,a
    ld a,(hl)
    inc b
loop1:
    rlca
    djnz loop1
    and 1
    ld l,a
    
    ret

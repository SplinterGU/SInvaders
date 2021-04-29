; *************************************************************************
; Rotate the Character Data BYTE D times - AND Shift the Mask BYTE AS well, forcing Zeroes into the
; Left hand side. The Mask will be used TO split the Rotated Character Data OVER a Character boundary
;
; IN:
;   a       byte to rotate
;   d       times
;
; OUT:
;   e       low rotated byte
;   d       high rotated byte
;
; MODIFIED REGISTERS
;   a
;   de
;   hl
;

define( `ROTATE_BYTE', `
    ld l,a
    ld a,d                  ; Grab our number of rotates
    dec a                   ; decrease so 1->0
    sla a                   ; Multiply by 2 because we have double tables
    add a, RotateTables/256 ; Add in the base for rotate tables
    ld h,a                  ; put it into our lookup
    ld d,(hl)               ; get high byte
    inc h
    ld e,(hl)               ; get low byte
')

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
    ex de,hl
IFDEF __ZX81__
    push de

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
ENDIF
IFDEF __SPECTRUM__
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
ENDIF
    ex de,hl
')

; **************************************************************************************************+
; High res Printing, based on code produced, with thanks, by Turkwel over on the WOS boards.
; Brought to ZX Basic by Britlion, June 2010.
; Modified & bug fixes by Juan Jose Ponteprino
; **************************************************************************************************'

IFDEF __SPECTRUM__
EXTERN ScreenTables
EXTERN RotateTables
ENDIF
IFDEF __ZX81__
EXTERN _CHARSET
ENDIF

SECTION code_user

PUBLIC _HRPrint

; **************************************************************************************************'

; (x AS UBYTE, y AS UBYTE, char AS UInteger, attribute AS UBYTE, method AS UBYTE)

_HRPrint:
    pop hl
    pop bc
    pop de
    ex (sp),hl

    ; h: method
    ; l: attribute
    ; de: character or address
    ; b: y
    ; c: x

IFDEF __SPECTRUM__
    push hl                 ; SAVE attribute
    push bc                 ; SAVE our co-ordinates.
ENDIF

    ld a,h
    push af                 ; SAVE method

; *** print_char ***
; if d is 0 then print from charset
; if d is <> 0 then print char from address

    ld a, d
    and a
    jp z, HRPrint_From_Charset
    ex de,hl                ; hl => character address
    jp HR_Print

HRPrint_From_Charset:
    ld  l,e                 ; character
    ld  h,0
IFDEF __ZX81__
    ld  a,l
    sub 32
    ld  l,a
    ld  de,_CHARSET
ENDIF
IFDEF __SPECTRUM__
    ld  de,(23606)
ENDIF
    add  hl,hl
    add  hl,hl
    add  hl,hl
    add  hl,de

HR_Print:
    GET_SCREEN_ADDR

    ; Choose method
    pop af                  ; Get method value
    and a                   ; = 0 ?
    jp z, HRP_DirectDrawMasked

    dec a
    jp nz, HRP_InvAnd

; ***************
; HRP_Or
; ***************
HRP_Or:

    ld a,8                  ; set counter TO 8 - Bytes of Character Data TO put down

Loop1:
    push af                 ; save off Counter

    push hl
    push de
    push de                 ; save off Address of Character Data, Screen Address, Screen Address

    ld a,c
    and 7

    jp z, norotate1         ; if the the X value is on an actual Character boundary i.e. there's no need to shift anything          '

    ld d,a
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting

IFDEF __SPECTRUM__
    ROTATE_BYTE             ; IN: a d OUT: de CHANGED: a de hl
ENDIF
IFDEF __ZX81__
    ld l,d
    ld d,a
    ld e,0
rot1:
    srl d
    rr e
    dec l
    jp nz, rot1
ENDIF

; PutByte1
    pop hl                  ; POP one of the Screen Addresses (formerly in DE) into HL

    ; Or1
    ld a,(hl)
    or d
    ld (hl),a

                            ; [remove the OR (HL) IF you just want a straight write rather than a merge]
                            ; or first byte
                            ; take the Rotated Character Data, mask it with the Mask BYTE AND the OR it with what's already on the Screen, '
                            ; this takes care of the first part of the BYTE

    inc l                   ; Increment the Screen Address AND check TO see IF it's at the end of a line,
    ld a,l
    and 31                  ; if so THEN there's no need to put down the second part of the Byte
    jp z, row_complete1

    ; Or1
    ld a,(hl)
    or e
    ld (hl),a

                            ; [again, remove the OR (HL) IF you just want a straight write rather than a merge]
                            ; Similar TO the first BYTE, we need TO Invert the mask with a CPL so we can put down the second part of the BYTE
                            ; in the NEXT Character location

row_complete1:
    pop de                  ; get the Screen Address back into DE, increment Y
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
ENDIF
    inc b

IFDEF __SPECTRUM__
    ld a,b                  ; now check IF the Y value has gone OVER a Character Boundary i.e. we will need TO recalculate the Screen
                            ; Address IF we've jumped from one Character Line to another - messy but necessary especially for lines 7 and 15   '
    and 7
    jp z, getscraddr1

getscraddr1_return:
ENDIF
    pop hl                  ; get the Address of the Character Data back AND increment it ready FOR the NEXT BYTE of data
    inc hl

    pop af                  ; get the Counter value back, decrement it AND GO back FOR another write IF we haven't reached the end yet   '
    dec a
    jp nz, Loop1
IFDEF __SPECTRUM__
    jp HRPrintAttributes
ENDIF
IFDEF __ZX81__
    ret
ENDIF

norotate1:
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting

    ; put only 1 byte
    pop hl                  ; POP one of the Screen Addresses (formerly in DE) into HL

    ; Or
    or (hl)
    ld (hl),a

    jp row_complete1

IFDEF __SPECTRUM__
getscraddr1:
    GET_SCREEN_ADDR
    jp getscraddr1_return
ENDIF



; ********************
; HRP_DirectDrawMasked
; ********************

HRP_DirectDrawMasked:

    ld a,8                  ; set counter TO 8 - Bytes of Character Data TO put down

Loop3:
    push af                 ; save off Counter

                            ; save off Address of Character Data, Screen Address, Screen Address
    push hl                 ; Data Address
    push bc                 ; save x and y
    push de                 ; Screen Address
    push de                 ; Screen Address

    ld a,c
    and 7

    jp z,norotate3          ; if the the X value is on an actual Character boundary i.e. there's no need to shift anything          '

    ld d,a
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting
    ld b,d                  ; preserve times to b

; rotate byte
IFDEF __SPECTRUM__
    ROTATE_BYTE             ; IN: a d OUT: de CHANGED: a de hl
ENDIF
IFDEF __ZX81__
    ld l,d
    ld d,a
    ld e,0
rot3:
    srl d
    rr e
    dec l
    jp nz, rot3
ENDIF

    ex de,hl                ; de -> hl

    ld d,b                  ; restore times

    ld c,l                  ; 2nd    hl -> bc
    ld b,h                  ; 1st

; rotate mask
    ld a,255                ; mask

IFDEF __SPECTRUM__
    ROTATE_BYTE             ; IN: a d OUT: de CHANGED: a de hl
ENDIF
IFDEF __ZX81__
    ld l,d
    ld d,a
    ld e,0
rot3b:
    srl d
    rr e
    dec l
    jp nz, rot3b
ENDIF

    ld a,d
    cpl
    ld d,a

    ld a,e
    cpl
    ld e,a

; PutByte3
    pop hl                  ; POP one of the Screen Addresses (formerly in DE) into HL

    ld a,(hl)
    and d
    or b
    ld (hl),a

    inc l                   ; Increment the Screen Address AND check TO see IF it's at the end of a line,
    ld a,l
    and 31                  ; if so THEN there's no need to put down the second part of the Byte
    jp z, row_complete3

    ld a,(hl)
    and e
    or c
    ld (hl),a

row_complete3:
    pop de                  ; get the Screen Address back into DE, increment Y
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
ENDIF

    pop bc
    inc b

IFDEF __SPECTRUM__
    ld a,b                  ; now check IF the Y value has gone OVER a Character Boundary i.e. we will need TO recalculate the Screen
                            ; Address IF we've jumped from one Character Line to another - messy but necessary especially for lines 7 and 15   '
    and 7
    jp z, getscraddr3

getscraddr3_return:
ENDIF

    pop hl                  ; get the Address of the Character Data back AND increment it ready FOR the NEXT BYTE of data
    inc hl

    pop af                  ; get the Counter value back, decrement it AND GO back FOR another write IF we haven't reached the end yet   '
    dec a
    jp nz, Loop3
IFDEF __SPECTRUM__
    jp HRPrintAttributes
ENDIF
IFDEF __ZX81__
    ret
ENDIF

norotate3:
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting

    ; put only 1 byte
    pop hl                  ; POP one of the Screen Addresses (formerly in DE) into HL

    ld (hl),a

    jp row_complete3

IFDEF __SPECTRUM__
getscraddr3:
    GET_SCREEN_ADDR
    jp getscraddr3_return
ENDIF


; ********************
; HRP_InvAnd
; ********************

HRP_InvAnd:

    ld a,8                  ; set counter TO 8 - Bytes of Character Data TO put down

Loop4:
    push af                 ; save off Counter

                            ; save off Address of Character Data, Screen Address, Screen Address
    push hl                 ; Data Address
    push bc                 ; save x and y
    push de                 ; Screen Address
    push de                 ; Screen Address

    ld a,c
    and 7

    jp z,norotate4          ; if the the X value is on an actual Character boundary i.e. there's no need to shift anything          '

NeedShift4:
    ld d,a

    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting

; rotate byte
IFDEF __SPECTRUM__
    ROTATE_BYTE             ; IN: a d OUT: de CHANGED: a de hl
ENDIF
IFDEF __ZX81__
    ld l,d
    ld d,a
    ld e,0
rot4:
    srl d
    rr e
    dec l
    jp nz, rot4
ENDIF

    ld a,d
    cpl
    ld d,a

    ld a,e
    cpl
    ld e,a

; PutByte4
    pop hl                  ; POP one of the Screen Addresses (formerly in DE) into HL

    ld a,(hl)
    and d
    ld (hl),a

    inc l                   ; Increment the Screen Address AND check TO see IF it's at the end of a line,
    ld a,l
    and 31                  ; if so THEN there's no need to put down the second part of the Byte
    jp z, row_complete4

    ld a,(hl)
    and e
    ld (hl),a

row_complete4:
    pop de                  ; get the Screen Address back into DE, increment Y
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
ENDIF

    pop bc
    inc b

IFDEF __SPECTRUM__
    ld a,b                  ; now check IF the Y value has gone OVER a Character Boundary i.e. we will need TO recalculate the Screen
                            ; Address IF we've jumped from one Character Line to another - messy but necessary especially for lines 7 and 15   '
    and 7
    jp z, getscraddr4

getscraddr4_return:
ENDIF

    pop hl                  ; get the Address of the Character Data back AND increment it ready FOR the NEXT BYTE of data
    inc hl

    pop af                  ; get the Counter value back, decrement it AND GO back FOR another write IF we haven't reached the end yet   '
    dec a
    jp nz, Loop4

IFDEF __SPECTRUM__
    jp HRPrintAttributes
ENDIF
IFDEF __ZX81__
    ret
ENDIF    

norotate4:
    ld a,(hl)               ; get a BYTE of Character Data TO put down - but ignore the following Mask shifting
    cpl

    ; put only 1 byte
    pop hl                  ; POP one of the Screen Addresses (formerly in DE) into HL

    and (hl)

    ld (hl),a

    jp row_complete4

IFDEF __SPECTRUM__
getscraddr4:
    GET_SCREEN_ADDR
    jp getscraddr4_return
ENDIF    


IFDEF __SPECTRUM__

; *************************************
; Attributes
; *************************************

HRPrintAttributes:

    pop bc                  ; recover our X-Y co-ordinates.
    pop de                  ; recover attribute
    ld a,e                  ; attribute
    and a
    jp z, HRPrintEnd        ; IF attribute=0, THEN we don't do attributes.   '
;    ld e,a                     ; pass TO e
                            ; transfer Attribute BYTE TO e FOR easier use

    ld a,b                  ; check Y position AND EXIT IF off bottom of screen
    cp 192
    jp nc, HRPrintEnd

    ld d,0

    push bc                 ; save off Y AND X values FOR later

    and 248                 ; calculate the correct Attribute Address FOR the Y\X values
    ld h,22
    ld l,a
    add hl,hl
    add hl,hl
    srl c
    srl c
    srl c
    ld b,d
    add hl,bc

    ld (hl),e               ; set the Attribute - this is ALWAYS set no matter what the valid Y\X values used

    pop bc                  ; get the Y AND X values back into BC

print_attributes1:          ; call the subroutine TO see IF an adjacent Horizontal Attribute needs TO be set
    ld a,c
    cp 248                  ; check TO see IF we are AT Horizontal character 31 - IF so THEN no need TO set adjacent Horizontal Attribute
    jp nc, endPrintAttributes1

    and 7                   ; and don't set the adjacent Horizontal Attribute if there's no need to
    jp z, endPrintAttributes1

    inc l                   ; increment the Attribute address - set the adjacent horizontal Attribute - THEN set the Attribute Address back
    ld (hl),e
    dec l

endPrintAttributes1:
    ld a,b
    cp 184                  ; check TO see IF we are AT Vertical character 23 - IF so THEN no need TO set adjacent Vertical Attribute & EXIT routine
    jp nc, HRPrintEnd

    and 7                   ; and don't set the adjacent Vertical Attribute if there's no need to & Exit routine
    jp z, HRPrintEnd

    ld a,l                  ; set the Attribute address TO the line below  - AND set the adjacent Vertical Attribute
    add a,32                ; drop through now into adjacent Horizontal Attribute subroutine - all RETs will now EXIT the routine completely
    ld l,a
    ld a,d
    adc a,h
    ld h,a
    ld (hl),e

HRPrintAttribute2:
    ld a,c
    cp 248                  ; check TO see IF we are AT Horizontal character 31 - IF so THEN no need TO set adjacent Horizontal Attribute
    jp nc, HRPrintEnd

    and 7                   ; and don't set the adjacent Horizontal Attribute if there's no need to
    jp z, HRPrintEnd

    inc l                   ; increment the Attribute address - set the adjacent horizontal Attribute - THEN set the Attribute Address back
    ld (hl),e
    dec l

HRPrintEnd:

    ret
ENDIF

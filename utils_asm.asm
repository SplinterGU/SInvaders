IFNDEF __ZX81__
EXTERN ScreenTables
ENDIF

IFDEF __ZX81__
EXTERN HRG_LineStart
ENDIF

EXTERN _readSysKeys, __ExitIfKeyPressed, _syskey

SECTION code_user

PUBLIC _ClearRows, _GetScreenAddr, _getDivideBy11, _getDivideBy12, _getDivideBy16, _DelayFrames

IF 0
PUBLIC _copymem, _outp, _inp
ENDIF

IFDEF __ZX81__
PUBLIC _GetAttrAddr, _WaitFrame, _zxpand_joyread, _zxpand_joyenabled
ENDIF

; ( y as ubyte, h as ubyte )
_ClearRows:
    pop hl
    pop bc
    push hl

    ;  c: row
    ;  b: height

    ; get screen addr
IFDEF __ZX81__
    ld l,c
    ld h,0
    ; row x 32
    add hl,hl ; x2
    add hl,hl ; x4
    add hl,hl ; x8
    add hl,hl ; x16
    add hl,hl ; x32
    ld a,(16518)
    add a,l
    ld l,a
    ld a,(16519)
    adc a,h
    ld h,a
ENDIF

IFDEF __ZX81__
    xor a
ENDIF
IFDEF __SPECTRUM__
    inc b
    jp getaddr
ENDIF
crloop:
IFDEF __SPECTRUM__
    xor a
    push hl
ENDIF
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
IFDEF __ZX81__
    inc hl
ENDIF
IFDEF __SPECTRUM__
    pop hl

    ; inc row
    inc c
    ld a,c
    and 7
    jp nz, nextrow
getaddr:
    ld h, ScreenTables/256
    ld l,c
    ld a,(hl)

    inc h
    ld l,(hl)
    ld h,a
    dec h ; faster than jp

nextrow:
    inc h
ENDIF
    djnz crloop

    ret

; -----------------------------------------
; ( x as ubyte, y as ubyte )
_GetScreenAddr:
    pop hl
    pop bc
    push hl

    ;  b: row
    ;  c: column

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
    add hl,de
    ; col / 8
    ld a,c
    srl a
    srl a
    srl a
    ld e,a
    ld d,0
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
    ret

; -----------------------------------------

IFDEF __ZX81__
_GetAttrAddr:
    xor a
    ld h,a
    ld l,a
    ld bc,7FEFh
    in a, (c)
    and 20h
    ret nz
    
    ld a,32+16   ; 32=colour enabled,  16="attribute file" mode, 0=black border
    out (c),a

    ld  hl,HRG_LineStart+2+$8000
    ret

ENDIF

; -----------------------------------------

IFDEF __ZX81__
_WaitFrame:
    ld hl,16436
    ld a,(hl)
l1:
    cp a,(hl)
    jr z, l1
    ret
ENDIF

; ---------------------------------
; int8_t DelayFrames( uint8_t frames ) __z88dk_fastcall;
; ---------------------------------
; Function DelayFrames
; ---------------------------------
_DelayFrames:
;utils.c:19: while ( frames-- ) {
    ld  c,l
l_DelayFrames_loop:
    ld  a, c
    dec c
    or  a
    jr  Z,l_DelayFrames_exit
;utils.c:20: WaitFrame();
IFDEF __SPECTRUM__
    halt
ENDIF
IFDEF __ZX81__
    call _WaitFrame
ENDIF
;utils.c:22: readSysKeys();
IFDEF __ZX81__
    push    bc
    call _readSysKeys
    pop bc
ENDIF
;utils.c:24: if ( _ExitIfKeyPressed && syskey.keyPressed ) return 1;
    ld  a, (__ExitIfKeyPressed)
    or  a
    jr  Z,l_DelayFrames_loop
    ld  a, (_syskey + 0)
    or  a
    jr  Z,l_DelayFrames_loop
    ld  l,0x01
    ret
l_DelayFrames_exit:
;utils.c:26: return 0;
    ld  l,0x00
    ret

; -----------------------------------------

IF 0

_copymem:
   pop af ; return
   pop de ; dest
   pop hl ; source
   pop bc ; size
   push af
   
   ld a,b
   or c
   ret z
      
   ; use ldir or lddr
   ld a,d
   cp h
   jr c, use_ldir ; src > dst use ldir
   jr nz, use_lddr ; src < dst use lddr
   
   ld a,e
   cp l
   jr c, use_ldir ; src > dst use ldir
   
   ret z       ; if dst == src, do nothing

use_lddr:
   dec bc
   
   add hl,bc
   ex de,hl
   add hl,bc
   ex de,hl
   
   inc bc
   lddr   
   ret

use_ldir:
   ldir
   ret

ENDIF

; -----------------------------------------

_getDivideBy11:
    ld a,l
    ld l,4
    cp 44
    ret nc
    dec l
    cp 33
    ret nc
    dec l
    cp 22
    ret nc
    dec l
    cp 11
    ret nc
    dec l
    ret

_getDivideBy12:
    ld a,l
    ld l,5
    cp 60
    ret nc
    dec l
    cp 48
    ret nc
    dec l
    cp 36
    ret nc
    dec l
    cp 24
    ret nc
    dec l
    cp 12
    ret nc
    dec l
    ret

_getDivideBy16:
    ld a,l
    srl a
    srl a
    srl a
    srl a
    ld l,a
    ret

IF 0
_inp:
    pop hl
    pop bc
    push hl
    in l,(c)
    ret

_outp:
    pop hl
    pop bc
    dec sp
    ex (sp),hl
    out (c),h
    ret
ENDIF

IFDEF __ZX81__
_zxpand_joyenabled:
    ld l,0
    push bc
    ld a,$aa
    ld bc,$e007
    out (c),a
    nop
    nop
    nop
    in a,(c)
    cp $f0
    jnz _zxpand_joyenabled_exit
    ld a,$55
    out (c),a
    nop
    nop
    nop
    in a,(c)
    cp $0f
    jnz _zxpand_joyenabled
    inc l
_zxpand_joyenabled_exit:
    pop bc
    ret

_zxpand_joyread:
    push bc
    ld a,$a0
    ld bc,$e007
    out (c),a
    nop
    nop
    nop
    in a,(c)
    ld l,a
    pop bc
    ret

ENDIF

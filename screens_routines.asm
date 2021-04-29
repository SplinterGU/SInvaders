EXTERN _ClearRows, _PrintChar, _PrintAt, _PrintAtArr, _PrintNumAt, _WaitFrame
EXTERN _numLives, _bonusLife, _displayCoinage, _soundSystem, _player
EXTERN _currentMenuScreen, _syskey

SECTION data_user

cursorPos:  db 0
key:        db 0
ukey:       db 0
x1:         db 0
x2:         db 0
y:          db 0

SECTION rodata_user

str_on:     db " ON",0
str_off:    db "OFF",0

; *********************************************

IFDEF __SPECTRUM__
inputTab:
    dw inputTab_str1
    dw inputTab_str2
    dw inputTab_str3
    dw inputTab_str4
    dw inputTab_str5
    dw inputTab_str6

inputTab_items: equ ( $-inputTab ) / 2

inputTab_str1: db "  KEYBOARD", 0
inputTab_str2: db "    CURSOR", 0
inputTab_str3: db "SINCLAIR 1", 0
inputTab_str4: db "SINCLAIR 2", 0
inputTab_str5: db "  KEMPSTON", 0
inputTab_str6: db "    FULLER", 0
ENDIF

; *********************************************

IFNDEF __NOSOUND__
soundTab:
    dw soundTab_str1
IFDEF __SPECTRUM__
    dw soundTab_str2
    dw soundTab_str3
    dw soundTab_str4
ENDIF
IFDEF __ZX81__
    dw soundTab_str5
ENDIF
soundTab_items: equ ( $-soundTab ) / 2 

    soundTab_str1: db "          OFF", 0
IFDEF __SPECTRUM__
    soundTab_str2: db "       BEEPER", 0
    soundTab_str3: db "SINCLAIR 128K", 0
    soundTab_str4: db "   FULLER BOX", 0
ENDIF
IFDEF __ZX81__
    soundTab_str5: db "        ZON-X", 0
ENDIF
ENDIF

; *********************************************

setupScreenTxt:
    db  40,  32
    dw setupScreenTxt_str1
    db  24,  56
    dw setupScreenTxt_str2
    db  24,  72
    dw setupScreenTxt_str3
    db  24,  88
    dw setupScreenTxt_str4
IFNDEF __NOSOUND__
    db  24, 104
    dw setupScreenTxt_str5
ENDIF
IFDEF __SPECTRUM__
    db  24, 120
    dw setupScreenTxt_str6
    db  24, 136
    dw setupScreenTxt_str7
ENDIF
    db 120, 160
    dw setupScreenTxt_str8
setupScreenTxt_size: equ ( $ - setupScreenTxt ) / 4

setupScreenTxt_str1: db "* CONFIGURE OPTIONS *",0
setupScreenTxt_str2: db "LIVES",0
setupScreenTxt_str3: db "BONUS LIFE",0
setupScreenTxt_str4: db "DISPLAY COINAGE",0
IFNDEF __NOSOUND__
setupScreenTxt_str5: db "SOUND", 0
ENDIF
IFDEF __SPECTRUM__
setupScreenTxt_str6: db "1PLAYER INPUT", 0
setupScreenTxt_str7: db "2PLAYER INPUT", 0
ENDIF
setupScreenTxt_str8: db "OK", 0

EXTERN _DelayFrames, _SetSoundCard_internal

SECTION code_user

PUBLIC _setup_Screen

; ---------------------------------
; Function setup_Screen
; ---------------------------------
_setup_Screen:
;screens.c:397: ClearRows( 16, 168 );
    ld  de,0xa810
    push de
    call _ClearRows

;screens.c:399: currentMenuScreen = 3;
    ld  hl,_currentMenuScreen
    ld  (hl),0x03

;screens.c:401: PrintAtArr( setupScreenTxt, sizeof( setupScreenTxt ) / sizeof( setupScreenTxt[0] ) );
    ld a, setupScreenTxt_size
    push af
    inc sp
    ld  hl,setupScreenTxt
    push hl
    call _PrintAtArr
    pop af
    inc sp

;screens.c:403: while ( 1 ) {
l_setup_while_1:

IFDEF __SPECTRUM__
    halt
    halt
    halt
ENDIF
IFDEF __ZX81__
    ld l,3
    call _DelayFrames
ENDIF

;screens.c:404: ukey = key & 0x3F;
    ld  a,(key)
    and a,0x3f
    ld  (ukey),a

;screens.c:406: key = ( ( ( ~inp( 0xF7FE ) ) & 0x10 ) << 1 ) | ( ( ~inp( 0xEFFE ) ) & 0x1F ) | | ( ( ~inp( 0xBFFE ) ) & 0x01 ) ;
    ld  bc,0xf7fe
    in  a,(c)
    cpl
    and a,0x10
    add a, a
    ld  e, a

    ld  bc,0xeffe
    in  a,(c)
    cpl
    and a,0x1f
    or  a, e

    ld  e,a

    ; key 0 or ENTER = fire
    ld  bc,0xbffe
    in  a,(c)
    cpl
    and 0x01
    or  e

    ld (key),a
    ld  e,a ; e = key 

; & 0x01 = shot   bit 0
; & 0x04 = right  bit 2
; & 0x08 = up     bit 3
; & 0x10 = down   bit 4
; & 0x20 = left   bit 5

;screens.c:419: flags = 0;
    ld d,0x00   ; flags

;screens.c:421: if ( !ukey ) {
    ld  a,(ukey)
    or  a, a
    jr  nz,l_setup_while_1

;screens.c:422: switch ( cursorPos ) {
    ld  a,(cursorPos)
    or  a, a
    jr  z,l_setup_lifes
    cp  0x01
    jr  z,l_setup_bonus_life
    cp  0x02
    jp  z,l_setup_display_coinage
    cp  0x03
IFNDEF __NOSOUND__
    jp  z,l_setup_sound_system
    cp  0x04
ENDIF
IFDEF __SPECTRUM__
    jp  z,l_setup_player1_input
IFDEF __NOSOUND__
    cp  0x04
ELSE
    cp  0x05
ENDIF
    jp  z,l_setup_player2_input
IFDEF __NOSOUND__
    cp  0x05
ELSE
    cp  0x06
ENDIF
ENDIF
    jp  Z,l_setup_item_ok
    jp  l_setup_exit_switch

;screens.c:423: case 0:
l_setup_lifes:
;screens.c:424: x1 = 216; x2 = 232; y = 56;
    ld  a,216
    ld  (x1),a
    ld  a,232
    ld  (x2),a
    ld  a,56
    ld  (y),a
    
;screens.c:426: if ( left && numLives > 3 ) numLives--;
    ld  hl,_numLives
    bit 5,e     ; left
    jr  z,l_setup_life_jmp1
    ld  a,0x03
    cp  (hl)
    jr  nc,l_setup_life_jmp1
    dec (hl)
l_setup_life_jmp1:

;screens.c:427: if ( right && numLives < 6 ) numLives++;
    bit 2,e     ; right
    jr  z,l_setup_life_jmp2
    ld  a, (hl)
    cp  6
    jr  nc,l_setup_life_jmp2
    inc (hl)
l_setup_life_jmp2:

;screens.c:429: if ( numLives > 3 ) flags |= 1;
    ld  a,0x03
    cp (hl)
    jr  nc, l_setup_life_jmp3
    ld  a,d     ; flags
    or  a,0x01
    ld  d,a     ; flags
l_setup_life_jmp3:

;screens.c:430: if ( numLives < 6 ) flags |= 2;
    ld  a, (hl)
    cp  6
    jr  nc, l_setup_life_jmp4
    ld  a,d     ; flags
    or  a,0x02

l_setup_set_flags:
    ld  d,a     ; flags
l_setup_life_jmp4:

    jp l_setup_exit_switch

l_setup_bonus_life:
;screens.c:435: x1 = 192; x2 = 232; y = 72;
    ld  a,192
    ld  (x1),a
    ld  a,232
    ld  (x2),a
    ld  a,72
    ld  (y),a

;screens.c:437: if ( left ) _bonusLife = 1000;
    bit 5,e     ; left
    jr  Z,l_setup_bonus_life_jmp1
    ld  hl,1000
    ld  (_bonusLife),hl

l_setup_bonus_life_jmp1:
;screens.c:438: if ( right ) _bonusLife = 1500;
    bit 2,e     ; right
    jr  z,l_setup_bonus_life_jmp2
    ld  hl,1500
    ld  (_bonusLife),hl
l_setup_bonus_life_jmp2:

;screens.c:440: if ( _bonusLife == 1500 ) flags = 1; else flags = 2;
    ld  hl,(_bonusLife)
    ld  a,l
    cp  1500%256
    jr  nz,l_setup_bonus_life_jmp3
    ld  a,h
    cp  1500/256
    jr  nz,l_setup_bonus_life_jmp3
    ld  a,0x01
    jr  l_setup_set_flags
l_setup_bonus_life_jmp3:
    ld  a,0x02
    jr  l_setup_set_flags

;screens.c:443: case 2:
l_setup_display_coinage:
;screens.c:444: x1 = 200; x2 = 232; y = 88;
    ld  a,200
    ld  (x1),a
    ld  a,232
    ld  (x2),a
    ld  a,88
    ld  (y),a

;screens.c:446: if ( left ) displayCoinage = 0;
    ld  hl,_displayCoinage
    bit 5,e     ; left
    jr  Z,l_setup_display_coinage_jmp1
    ld  (hl),0x00

l_setup_display_coinage_jmp1:
;screens.c:447: if ( right ) displayCoinage = 1;
    bit 2,e     ; right
    jr  z,l_setup_display_coinage_jmp2
    ld  (hl),0x01

l_setup_display_coinage_jmp2:
;screens.c:449: if ( displayCoinage ) flags = 1; else flags = 2;
    ld  a,(hl)
    or  a, a
    jr  Z,l_setup_display_coinage_jmp3
    ld  a,0x01
    jr  l_setup_set_flags
l_setup_display_coinage_jmp3:
    ld  a,0x02
    jr  l_setup_set_flags

IFNDEF __NOSOUND__
;screens.c:452: case 3:
l_setup_sound_system:
;screens.c:477: x1 = 120; x2 = 232; y = 104;
    ld  a,120
    ld  (x1),a
    ld  a,232
    ld  (x2),a
    ld  a,104
    ld  (y),a

;screens.c:479: if ( left  && soundSystem ) soundSystem--;
    ld  hl,_soundSystem

    bit 5,e     ; left
    jr  z,l_setup_sound_system_jmp1
    ld  a, (hl)
    or  a, a
    jr  z,l_setup_sound_system_jmp1
    dec (hl)

l_setup_sound_system_jmp1:
;screens.c:480: if ( right && soundSystem < sizeof( soundTab ) / sizeof( soundTab[ 0 ] ) - 1 ) soundSystem++;
    bit 2,e     ; right
    jr  z,l_setup_sound_system_jmp2
    ld  a, (hl)
    cp  soundTab_items - 1      ; items in soundTab
    jr  nc,l_setup_sound_system_jmp2
    inc (hl)

l_setup_sound_system_jmp2:

;screens.c:482: if ( soundSystem > 0 ) flags |= 1;
    ld  a, (hl)
    or  a
    jr  z,l_setup_sound_system_jmp3
    ld  a,d     ; flags
    or  0x01
    ld  d,a     ; flags

l_setup_sound_system_jmp3:
;screens.c:483: if ( soundSystem < sizeof( soundTab ) / sizeof( soundTab[ 0 ] ) - 1 ) flags |= 2;
    ld  a, (hl)
    cp soundTab_items - 1       ; items in soundTab
    jp  nc,l_setup_exit_switch
    ld  a,d     ; flags
    or  0x02
    jp  l_setup_set_flags
ENDIF

IFDEF __SPECTRUM__
;screens.c:452: case 3:
l_setup_player1_input:
;screens.c:477: x1 = 144; x2 = 232; y = 120;
    ld  a,144
    ld  (x1),a
    ld  a,232
    ld  (x2),a
    ld  a,120
    ld  (y),a

;screens.c:479: if ( left  && player[0].input ) player[0].input--;
    ld  hl,_player+87           ; player[0].input

    bit 5,e     ; left
    jr  z,l_setup_player1_input_jmp1
    ld  a, (hl)
    or  a, a
    jr  z,l_setup_player1_input_jmp1
    dec (hl)

l_setup_player1_input_jmp1:
;screens.c:480: if ( right && player[0].input < sizeof( inputTab ) / sizeof( inputTab[ 0 ] ) - 1 ) player[0].input++;
    bit 2,e     ; right
    jr  z,l_setup_player1_input_jmp2
    ld  a, (hl)
    cp  inputTab_items - 1      ; items in inputTab
    jr  nc,l_setup_player1_input_jmp2
    inc (hl)

l_setup_player1_input_jmp2:

;screens.c:482: if ( soundSystem > 0 ) flags |= 1;
    ld  a, (hl)
    or  a
    jr  z,l_setup_player1_input_jmp3
    ld  a,d     ; flags
    or  0x01
    ld  d,a     ; flags

l_setup_player1_input_jmp3:
;screens.c:483: if ( player[0].input < sizeof( inputTab ) / sizeof( inputTab[ 0 ] ) - 1 ) flags |= 2;
    ld  a, (hl)
    cp  inputTab_items - 1      ; items in inputTab
    jr  nc,l_setup_exit_switch
    ld  a,d     ; flags
    or  0x02
    jp  l_setup_set_flags

;screens.c:452: case 3:
l_setup_player2_input:
;screens.c:477: x1 = 144; x2 = 232; y = 136;
    ld  a,144
    ld  (x1),a
    ld  a,232
    ld  (x2),a
    ld  a,136
    ld  (y),a

;screens.c:479: if ( left  && player[1].input ) player[1].input--;
    ld  hl,_player+87+858       ; player[1].input

    bit 5,e     ; left
    jr  z,l_setup_player2_input_jmp1
    ld  a, (hl)
    or  a, a
    jr  z,l_setup_player2_input_jmp1
    dec (hl)

l_setup_player2_input_jmp1:
    bit 2,e     ; right
    jr  z,l_setup_player2_input_jmp2
    ld  a, (hl)
    cp  inputTab_items - 1      ; items in inputTab
    jr  nc,l_setup_player2_input_jmp2
    inc (hl)

l_setup_player2_input_jmp2:

;screens.c:482: if ( player[1].input > 0 ) flags |= 1;
    ld  a, (hl)
    or  a
    jr  z,l_setup_player2_input_jmp3
    ld  a,d     ; flags
    or  0x01
    ld  d,a     ; flags

l_setup_player2_input_jmp3:
;screens.c:483: if ( player[1].input < sizeof( inputTab ) / sizeof( inputTab[ 1 ] ) - 1 ) flags |= 2;
    ld  a, (hl)
    cp  inputTab_items - 1      ; items in inputTab
    jr  nc,l_setup_exit_switch
    ld  a,d     ; flags
    or  0x02
    jp  l_setup_set_flags

ENDIF

;screens.c:486: case 6:
l_setup_item_ok:
;screens.c:488: x1 = 136; x2 = 112; y = 160;
    ld  a,136
    ld  (x1),a
    ld  a,112
    ld  (x2),a
    ld  a,160
    ld  (y),a
;screens.c:490: if ( shot ) {
    bit 0,e     ; shot
    jr  Z,l_setup_continue
;screens.c:491: syskey.keyPressed = 0;
    ld  a,(_soundSystem)
    call _SetSoundCard_internal
    xor a
    ld  (_syskey),a
;screens.c:492: return 0;
    ld  l,0x00
    ret

l_setup_continue:
;screens.c:494: flags = 3;
    ld  a,0x03
    ld  d,a     ; flags

;screens.c:496: }
l_setup_exit_switch:

;screens.c:498: if ( up || down ) {
    ld  hl,cursorPos
    bit 4,e     ; down
    jr  nz,l_setup_down_pressed
    bit 3,e     ; up
    jr  z,l_setup_show_cursor

    dec (hl)

    ld a,(hl)
    or a
    jp p, l_setup_delete_cursor
IFDEF __SPECTRUM__
IFDEF __NOSOUND__
    ld a, 0x05      ; cursor new pos
ELSE
    ld a, 0x06      ; cursor new pos
ENDIF
ENDIF
IFDEF __ZX81__
IFDEF __NOSOUND__
    ld a, 0x03      ; cursor new pos
ELSE
    ld a, 0x04      ; cursor new pos
ENDIF
ENDIF
    ld (hl),a
    jr  l_setup_delete_cursor

l_setup_down_pressed:
    inc (hl)

    ld a,(hl)
IFDEF __SPECTRUM__
IFDEF __NOSOUND__
    cp 0x06         ; cursor limit
ELSE
    cp 0x07         ; cursor limit
ENDIF
ENDIF
IFDEF __ZX81__
IFDEF __NOSOUND__
    cp 0x04         ; cursor limit
ELSE
    cp 0x05         ; cursor limit
ENDIF
ENDIF
    jr c, l_setup_delete_cursor
    ld (hl),0

l_setup_delete_cursor:
;screens.c:499: PrintChar( x1, y, ' ', 0 );
    ld  hl,0x20
    push hl
    ld  a,(y)
    ld  h,a
    ld  a,(x1)
    ld  l,a
    push hl
    call _PrintChar

;screens.c:500: PrintChar( x2, y, ' ', 0 );
    ld  hl,0x20
    push hl
    ld  a,(y)
    ld  h,a
    ld  a,(x2)
    ld  l,a
    push hl
    call _PrintChar

    jr  l_setup_print_values

l_setup_show_cursor:
;screens.c:503: PrintChar( x1, y, ( ( flags & 1 ) ? '<' : ' ' ), 0 );
    ld a,d      ; flags
    push af     ; push flags
    and 0x01
    ld l,' '
    jr z, no_cursor_1
    ld l,'<'
no_cursor_1:
    ld  h,0
    push hl
    ld  a,(y)
    ld  h,a
    ld  a,(x1)
    ld  l,a
    push hl
    call _PrintChar

;screens.c:504: PrintChar( x2, y, ( ( flags & 2 ) ? '>' : ' ' ), 0 );
    pop af      ; pop flags
    and 0x02
    ld l,' '
    jr z, no_cursor_2
    ld l,'>'
no_cursor_2:
    ld  h,0
    push hl
    ld  a,(y)
    ld  h,a
    ld  a,(x2)
    ld  l,a
    push hl
    call _PrintChar

l_setup_print_values:
;screens.c:507: PrintNumAt( 224,  56, numLives,  1 );
    ld  a,0x01
    push af
    inc sp
    ld  a,(_numLives)
    ld  c, a
    rla
    sbc a, a
    ld  b, a
    push bc
    ld  de,0x38e0
    push de
    call _PrintNumAt
    pop af
    pop af
    inc sp

;screens.c:508: PrintNumAt( 200,  72, _bonusLife, 4 );
    ld  a,0x04
    push af
    inc sp
    ld  hl, (_bonusLife)
    push hl
    ld  de,0x48c8
    push de
    call _PrintNumAt
    pop af
    pop af
    inc sp

;screens.c:509: PrintAt( 208,  88, displayCoinage ? " ON" : "OFF" );
    ld  a,(_displayCoinage)
    or  a, a
    ld  bc,str_off
    jr  Z,l_setup_print_display_coinage_off
    ld  bc,str_on
l_setup_print_display_coinage_off:
    push bc
    ld  de,0x58d0
    push de
    call _PrintAt
    pop af
    pop af

IFNDEF __NOSOUND__
;screens.c:515: PrintAt( 128, 104, soundTab[ soundSystem ] );
    ld  a,(_soundSystem)
    ld  l, a
    ld  h, 0
    add hl, hl
    ld  de,soundTab
    add hl, de
    ld  c, (hl)
    inc hl
    ld  b, (hl)
    push bc
    ld  de,0x6880
    push de
    call _PrintAt
    pop af
    pop af
ENDIF

IFDEF __SPECTRUM__
;screens.c:515: PrintAt( 144, 120, inputTab[ player[0].input ] );
    ld  a,(_player+87)
    ld  l, a
    ld  h, 0
    add hl, hl
    ld  de, inputTab
    add hl, de
    ld  c, (hl)
    inc hl
    ld  b, (hl)
    push bc
    ld  de,0x7898
    push de
    call _PrintAt
    pop af
    pop af

;screens.c:515: PrintAt( 144, 136, inputTab[ player[1].input ] );
    ld  a,(_player+87+858)
    ld  l, a
    ld  h, 0
    add hl, hl
    ld  de, inputTab
    add hl, de
    ld  c, (hl)
    inc hl
    ld  b, (hl)
    push bc
    ld  de,0x8898
    push de
    call _PrintAt
    pop af
    pop af
ENDIF

    jp l_setup_while_1

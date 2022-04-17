SECTION data_user

PUBLIC _input, _syskey

IFDEF __ZX81__
PUBLIC _zxpandJoyEnabled
ENDIF

; -------------------------------------------------

;union _syskey {
;    uint8_t keyPressed;
;    struct {
;        uint8_t keyCredit           :1;
;        uint8_t keyStart1UP         :1;
;        uint8_t keyStart2UP         :1;
;        uint8_t showSetup           :1;
;        uint8_t showHelp            :1;
;#ifdef __ZXN__
;        uint8_t showIntro           :1;
;#endif
;    };
;};
;union _syskey syskey;

_syskey:
_keyPresesed:
    db 0

;union _input {
;    uint8_t pulsed;
;    struct {
;        uint8_t moveLeft:1;
;        uint8_t moveRight:1;
;        uint8_t shot:1;
;    };
;};
;union _input input;
_input:
    db 0

IFDEF __ZX81__
_zxpandJoyEnabled:
    db 0
ENDIF

keyCreditEnable:
    db 1

; -------------------------------------------------

IFDEF __ZX81__
EXTERN _zxpand_joyenabled, _zxpand_joyread
ENDIF

EXTERN _numCredits, _DrawCredits, _readSysKeys, _playerPtr

SECTION code_user

PUBLIC _InputDetect, _readInput

; -------------------------------------------------

_InputDetect:
IFDEF __ZX81__
    call _zxpand_joyenabled
    ld a,l
    ld (_zxpandJoyEnabled),a
ENDIF
    ret

; -------------------------------------------------

_readSysKeys:

    ld a,(_syskey)
    ld d,a

IFDEF __ZXN__
    ld bc,0xdffe    ; in y-p
    in a,(c)        ; in y-p
    cpl             ; in y-p
    bit 2,a         ; key "I"
    jp z, test_setup_key
    set 5,d         ; key show intro 
ENDIF

test_setup_key:
; key setup
    ld bc,0xfefe    ; in CS-V
    in a,(c)        ; in CS-V
    cpl             ; in CS-V

;    ld d,0          ; key = 0

    and 0x08        ; Key Setup (c)
    or d            ; Key Setup (c)
    ld d,a
;    ld d,a          ; Key Setup (c)

; key help & credit
    ld bc,0xbffe    ; in ENTER - H
    in a,(c)        ; in ENTER - H
    cpl             ; in ENTER - H

; key help
    bit 4,a                 ; test key H
    jp z,test_credit_key
    set 4,d                 ; key help

test_credit_key:
; key credit
    ld hl,keyCreditEnable

    and 0x04
    jp z, test_credit_reset
    
    ld a,(hl)
    and a
    jp z, test_players_start
    set 0,d                ; key credit
    ld (hl),0

    ld hl,_numCredits
    ld a,(hl)
    cp 99
    jp nc,test_players_start
    inc a
    ld (hl),a

    push de
    call _DrawCredits
    pop de
    jp test_players_start

test_credit_reset:
    ld (hl),1

test_players_start:
    ld a,(_numCredits)
    and a
    jp z, syskey_end
    ld bc,0xf7fe    ; in 1 - 5
    in c,(c)        ; in 1 - 5

test_player1:
    bit 0,c
    jp nz, test_player2
    set 1,d

test_player2:
    cp 2
    jp c,syskey_end ; numcredits < 2

    bit 1,c
    jp nz, syskey_end
    set 2,d

syskey_end:
    ld a,d
    ld (_syskey),a
    ret

; -------------------------------------------------

_readInput:

IFDEF __ZX81__
    call _readSysKeys
ENDIF
    ld de,(_playerPtr)
    ld hl,87                ; WARNING: offset struct player.input
    add hl,de
    ld e,(hl)
    ld d,0
    ld hl,read_Input_switch
    add hl,de
    add hl,de
    add hl,de
    jp (hl)

read_Input_switch:
    jp i_keyboad
IFDEF __SPECTRUM__
    jp i_cursor
    jp i_sinclar1
    jp i_sinclar2
    jp i_kempston
    jp i_fuller
    jp i_ts2068_1
    jp i_ts2068_2
ENDIF

i_keyboad:
    ld bc,0xdffe    ; in y-p
    in a,(c)        ; in y-p
    cpl             ; in y-p
    ld l,a          ; in y-p

    and 2           ; left
    srl a           ; left
    ld h,a          ; left

    ld a,l          ; right
    and 1           ; right
    sla a           ; right

    or h            ; left + right
    ld h,a          ; left + right

    ld bc,0xfefe    ; fire SHIFT
    in a,(c)        ; fire SHIFT
    cpl             ; fire SHIFT
    ld l,a          ; fire SHIFT
    ld bc,0xfdfe    ; fire A
    in a,(c)        ; fire A
    cpl             ; fire A
    or l            ; fire A + fire SHIFT
    and 1           ; fire A + fire SHIFT
    sla a           ; fire A + fire SHIFT
    sla a           ; fire A + fire SHIFT
    or h            ; fire A + fire shift + right + left

IFDEF __ZX81__
    ; Bit -- Direction
    ; 7 Up
    ; 6 Down
    ; 5 Left
    ; 4 Right
    ; 3 Fire

    ld h,a
    ld a,(_zxpandJoyEnabled)
    or a, a
    jp z, zxpand_end

    call _zxpand_joyread

    bit 5,l
    jp nz,zxpand_test_right
    set 0,h

zxpand_test_right:
    bit 4,l
    jp nz,zxpand_test_shot
    set 1,h

zxpand_test_shot:
    bit 3,l
    jp nz,zxpand_end
    set 2,h

zxpand_end:
    ld a,h
ENDIF

    ld (_input),a   ; fire + left + right
    ret

IFDEF __SPECTRUM__
i_cursor:
    ld bc,0xf7fe    ; in 1-5
    in a,(c)        ; in 1-5

    ld l,0

    bit 4,a
    jp nz, test_cursor_right
    set 0,l         ; left

test_cursor_right:
    ld bc,0xeffe    ; in 6-0
    in a,(c)        ; in 6-0

    bit 2,a
    jp nz, test_cursor_shot
    set 1,l         ; right

test_cursor_shot:
    and 1
    jp nz, test_cursor_end
    set 2,l         ; shot

test_cursor_end:
    ld a,l
    ld (_input),a   ; fire + left + right
    ret

i_sinclar1:
    ld bc,0xeffe    ; in 6-0
    in a,(c)        ; in 6-0

    ld l,0

    bit 4,a
    jp nz, test_sinclair1_right
    set 0,l         ; left

test_sinclair1_right:
    bit 3,a
    jp nz, test_sinclair1_shot
    set 1,l         ; right

test_sinclair1_shot:
    and 1           ; shot
    jp nz, test_sinclair1_end
    set 2,l         ; shot

test_sinclair1_end:
    ld a,l
    ld (_input),a   ; fire + left + right
    ret

i_sinclar2:
    ld bc,0xf7fe    ; in 1-5
    in a,(c)        ; in 1-5
    cpl

    ld l,0

    bit 4,a
    jp z, test_sinclair2_left_right
    set 2,l         ; shot

test_sinclair2_left_right:
    and 3
    or l

    ld (_input),a   ; fire + left + right
    ret

i_kempston:
    in a,(0x1f)

    ld l,0

    bit 1,a
    jp z, test_kempston_right
    set 0,l

test_kempston_right:
    bit 0,a
    jp z, test_kempston_shot
    set 1,l

test_kempston_shot:
    bit 4,a
    jp z, test_kempston_end
    set 2,l

test_kempston_end:
    ld a,l

    ld (_input),a   ; fire + left + right
    ret

i_fuller:
    in a,(0x7f)

    ld l,0

    bit 2,a
    jp z, test_fuller_right
    set 0,l

test_fuller_right:
    bit 3,a
    jp z, test_fuller_shot
    set 1,l

test_fuller_shot:
    bit 7,a
    jp z, test_fuller_end
    set 2,l

test_fuller_end:
    ld a,l
    ld (_input),a   ; fire + left + right
    ret

i_ts2068_1:
    ld h,1

ts2068_common:
    ld a,7
    out (0xf5),a  ;set r7

    in a,(0xf6)
    and 0xbf      ;clear bit 6 to read from i/o port a - r14
    out (0xf6),a

    ld a,14
    out (0xf5),a  ;set r14
    ld a,h        ;(3=both joysticks, 2=left only, 1=right only)

    ld l,0

    in a,(0xf6)   ;(fxxxrldu, active low)
    bit 2,a       ; left
    jp nz, test_ts2068_right
    set 0,l

test_ts2068_right:
    bit 3,a
    jp nz, test_ts2068_shot
    set 1,l

test_ts2068_shot:
    bit 7,a
    jp nz, test_ts2068_end
    set 2,l

test_ts2068_end:
    ld a,l
    ld (_input),a   ; fire + left + right
    ret

i_ts2068_2:
    ld h,2
    jp ts2068_common

ENDIF

; -------------------------------------------------

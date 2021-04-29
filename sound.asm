include "common.inc"

; ---------------------------------

IFDEF __SPECTRUM__
EXTERN _playFX, _stopFX
PUBLIC _playingSound
ENDIF

; ---------------------------------

PUBLIC _soundSystem

; ---------------------------------

SECTION data_user

cmd:                db 0
mix:                db 0

_soundSystem:       db SOUND_SYS_OFF

soundPIORegister:   dw 0
soundPIOData:       dw 0

IFDEF __SPECTRUM__
_playingSound:      db 0
soundStopped:       db 0

soundPriority:
    db    0 ; NO SOUND
    db   20 ; SOUND_UFO                A
    db   10 ; SOUND_PLAYER_SHOT        B
    db   50 ; SOUND_PLAYER_EXPLOSION   C
    db   30 ; SOUND_ALIEN_EXPLOSION    B
    db    0 ; SOUND_ALIEN_STEP1        A
    db    0 ; SOUND_ALIEN_STEP2        A
    db    0 ; SOUND_ALIEN_STEP3        A
    db    0 ; SOUND_ALIEN_STEP4        A
    db   40 ; SOUND_UFO_EXPLOSION      C
    db   60 ; SOUND_EXTRA_LIFE         A
ENDIF

ufo_sound:
    db 228,252,0,27,228,245,0,0,228,238,0,28,228,231,0,0,228,224,0,29,228,217,0,0,228,224,0,30,228,231,0,0,228,238,0,31,228,245,0,0
    ;,208,32
ufo_sound_sz: equ $-ufo_sound

player_shot_sound:
    db 109,51,0,8,108,52,0,9,107,53,0,10,106,54,0,11,105,55,0,12,104,56,0,13,103,57,0,14,102,58,0,15,101,59,0,16,228,60,0,17,227,61,0,18,226,62,0,19,226,63,0,20,226,0,0,0,130,130,208,32
player_shot_sound_sz: equ $-player_shot_sound

player_explosion_sound:
    db 109,128,0,20,109,0,2,8,123,0,0,0,91,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,89,0,89,30,87,0,23,87,30,87,0,22,22,86,30,86,0,21,21,85,30,85,0,168,1,0,208,32
player_explosion_sound_sz: equ $-player_explosion_sound

alien_explosion_sound:
    db 170,171,0,170,129,0,170,97,0,170,73,0,170,55,0,170,42,0,170,32,0,208,32
alien_explosion_sound_sz: equ $-alien_explosion_sound

alien_step_sound:
;    db 229,79,3,31,165,50,2,165,63,3,165,58,2,165,34,2,165,219,1,165,172,7,165,27,5,165,60,1,165,248,2,165,34,2,165,84,1,165,58,2,176,255,15,208,32
    db 236,89,2,6,237,189,2,0,174,61,3,208,32
;    db 0xe4,89,2,6,0xe5,189,2,0,0xa6,61,3,208,32
;db 47,200,1,47,1,2,47,65,2,47,137,2,47,218,2,47,53,3,47,155,3,46,14,4,44,143,4,42,32,5,40,196,5,208,32
alien_step_sound_sz: equ $-alien_step_sound

ufo_explosion_sound:
    db 238,96,0,30,238,128,0,0,174,96,0,174,128,0,174,192,0,174,0,1,174,64,1,174,128,1,174,64,1,174,0,1,174,192,0,174,128,0,174,96,0,172,128,0,172,192,0,172,0,1,172,64,1,172,128,1,172,64,1,172,0,1,172,192,0,172,128,0,172,96,0,208,32
ufo_explosion_sound_sz: equ $-ufo_explosion_sound

extra_life_sound:
    db 174,106,1,173,181,0,174,106,1,173,181,0,174,106,1,160,0,0,128,128,128,128,174,106,1,173,181,0,174,106,1,173,181,0,174,106,1,160,0,0,128,128,128,128,174,106,1,173,181,0,174,106,1,173,181,0,174,106,1,160,0,0,128,128,128,128,208,32
extra_life_sound_sz: equ $-extra_life_sound

ay_sounds:
    dw 0
    dw ufo_sound
    dw player_shot_sound
    dw player_explosion_sound
    dw alien_explosion_sound
    dw alien_step_sound
    dw alien_step_sound
    dw alien_step_sound
    dw alien_step_sound
    dw ufo_explosion_sound
    dw extra_life_sound

ay_sounds_sz:
    dw 0
    dw ufo_sound_sz
    dw player_shot_sound_sz
    dw player_explosion_sound_sz
    dw alien_explosion_sound_sz
    dw alien_step_sound_sz
    dw alien_step_sound_sz
    dw alien_step_sound_sz
    dw alien_step_sound_sz
    dw ufo_explosion_sound_sz
    dw extra_life_sound_sz

ay_used_channels_id:
    db 0, 0, 0

ay_play_remains:
    dw 0, 0, 0

ay_play_ptr:
    dw 0, 0, 0

; ---------------------------------

SECTION code_user

PUBLIC _SoundSetCard, _SoundDetectCard, _SoundPlay, _SoundStop, _SoundStopAll, _SoundExecute
PUBLIC _SetSoundCard_internal

; ---------------------------------

; void SoundSetCard(byte type);
; ---------------------------------
; Function _SoundSetCard
; ---------------------------------
_SoundSetCard:
    ld  a,l

_SetSoundCard_internal:

IFDEF __SPECTRUM__
    cp  SOUND_SYS_FULLERBOX+1
ENDIF
IFDEF __ZX81__
    cp  SOUND_SYS_ZONX+1
ENDIF
    ret nc

    ld  (_soundSystem),a
    cp  SOUND_SYS_OFF
    ret z

IFDEF __SPECTRUM__
    cp  SOUND_SYS_BEEPER
    ret z

    cp  SOUND_SYS_SINCLAIR128K
    jr  nz, test_set_fuller

    ; Sinclair 128k
    ld  hl,0xfffd           ; soundPIORegister = 65533
    ld  de,0xbffd           ; soundPIOData = 49149
    jr  set_sound_system

test_set_fuller:
    cp  SOUND_SYS_FULLERBOX
    ret nz

    ; Fuller Box
    ld  hl,0x3f             ; soundPIORegister = 63
    ld  de,0x5f             ; soundPIOData = 95
ENDIF

IFDEF __ZX81__
    ; Zon-X
    ld  hl,0x00cf           ; soundPIORegister = 207
    ld  de,0x000f           ; soundPIOData = 15
ENDIF

set_sound_system:
    ld  (soundPIORegister),hl
    ld  (soundPIOData),de
    ld  (_soundSystem),a
    ret

; ---------------------------------
; hl - register port
; de - data port
; a  - system id
IFDEF __SPECTRUM__
test_card:
    push af
    ; Channel A - Volume 0
    ld  c,l ; soundPIORegister
    ld  b,h
    ld  a,8
    out (c),a

    ld  c,e ; soundPIOData
    ld  b,d
    xor a
    out (c),a

    ; Channel A - Tone Fine 170
    ld  c,l ; soundPIORegister
    ld  b,h
    xor a
    out (c),a

    ld  c,e ; soundPIOData
    ld  b,d
    ld  a,170
    out (c),a

    ; Channel A - Tone Fine
    ld  c,l ; soundPIORegister
    ld  b,h
    xor a
    out (c),a

    ; if ( inp( soundPIORegister ) == 170 )
    in  a,(c)
    cp  170
    pop bc
    ret nz

    ld  a,b
    jr  set_sound_system
ENDIF

; void SoundDetect();
; ---------------------------------
; Function SoundDetect
; ---------------------------------
_SoundDetectCard:
IFDEF __SPECTRUM__
    ; Sinclair 128k
    ld  hl,0xfffd           ; soundPIORegister = 65533
    ld  de,0xbffd           ; soundPIOData = 49149
    ld  a, SOUND_SYS_SINCLAIR128K
    call test_card
    ret z

    ; Fuller Box
    ld  hl,0x3f             ; soundPIORegister = 63
    ld  de,0x5f             ; soundPIOData = 95
    ld  a, SOUND_SYS_FULLERBOX
    call test_card
    ret z

    ; SOUND_SYS_BEEPER
    ld  a, SOUND_SYS_BEEPER
    ld  (_soundSystem),a
ENDIF

IFDEF __ZX81__
    ; Zon-X
    ld  hl,0x00cf           ; soundPIORegister = 207
    ld  (soundPIORegister),hl
    ld  hl,0x000f           ; soundPIOData = 15
    ld (soundPIOData),hl
    ld  a, SOUND_SYS_ZONX
    ld  (_soundSystem),a
ENDIF
    ret

; void SoundPlay( int8_t id )
; ---------------------------------
; Function SoundPlay
; ---------------------------------
_SoundPlay:
    ld  c, l        ; id
    ld  a,(_soundSystem)

IFDEF __SPECTRUM__
;sound.c:188: if ( soundSystem == SOUND_SYS_BEEPER )
    cp  SOUND_SYS_BEEPER
    jr  nz, l_SoundPlay_no_sound_beeper

;sound.c:190: if ( playingSound )
    ld  a,(_playingSound)
    or  a
    jr  z,l_SoundPlay_Sound_not_playing

;sound.c:191: if ( soundPriority[ playingSound ] >= soundPriority[ id ] ) return;
    ld  de, soundPriority

    ld  l, a        ; playingSound
    ld  h, 0
    add hl, de      ; soundPriority[ playingSound ]

    ld  a, (hl)     ; a = soundPriority[ playingSound ]

    ld  l, c        ; id
    ld  h, 0
    add hl, de      ; soundPriority[ id ]

    cp  (hl)        ; cp soundPriority[ id ]
    ret nc

;sound.c:192: SoundStop();
    push bc
    call _SoundStop
    pop bc

l_SoundPlay_Sound_not_playing:
;sound.c:194: playingSound = id;
    ld  a,c
    ld  (_playingSound),a
    ret

l_SoundPlay_no_sound_beeper:
ENDIF

;sound.c:198: if ( soundSystem != SOUND_SYS_OFF )
    cp  SOUND_SYS_OFF
    ret z

;sound.c:201: if ( !ay_sounds[ id ] ) return;
    ld  hl, ay_sounds
    ld  b, 0
    add hl, bc
    add hl, bc

    ld  a, (hl)
    inc hl
    or (hl)
    ret z

    ld  hl, ay_used_channels_id
    ld  d, 0        ; idx = 0
    ld  e, -1       ; available = -1

l_SoundPlay_loop:
    ld  a,(hl)      ; sound in this channel
    
    cp  c           ; sound id is playing on this channel?
    ret z           ; already playing

    or  a           ; channel is free?
    jr  nz, l_SoundPlay_next
    ld  e, d        ; available = idx

l_SoundPlay_next:
    inc hl          ; next channel
    inc d           ; idx++

    ld  a, d        ; idx != 3
    cp  3
    jr  nz, l_SoundPlay_loop

;sound.c:218: if ( available != -1)
    ld  a, e
    cp  -1
    ret z           ; no channels available

;sound.c:219: ay_used_channels_id[ available ] = id;
    xor a
    ld  d, a        ; de = available (16 bits)
    ld  hl, ay_used_channels_id
    add hl, de      ; hl = ay_used_channels_id[ available ]
    ld  (hl),c      ; ay_used_channels_id[ available ] = id

;sound.c:220: ay_play_ptr[ available ] = ay_sounds[ id ];
    ld  hl, ay_play_ptr
    add hl, de
    add hl, de      ; hl = ay_play_ptr[ available ]

; de = available
; hl = ay_play_ptr[ available ]
; bc = id

    push de         ; de = available
    ex  de, hl      ; de = ay_play_ptr[ available ]

    ld  b, a        ; bc = id
    ld  hl, ay_sounds
    add hl, bc
    add hl, bc      ; hl = ay_sounds[ id ]

    ld a,(hl)
    ld (de),a
    inc hl
    inc de
    ld a,(hl)
    ld (de),a       ; ay_play_ptr[ available ] = ay_sounds[ id ]

;sound.c:221: ay_play_remains[ available ] = ay_sounds_sz[ id ];
    pop de          ; de = available

    ld  hl, ay_play_remains
    add hl, de
    add hl, de      ; hl = ay_play_remains[ available ]

    ex de, hl       ; de = ay_play_remains[ available ]

    ld  hl, ay_sounds_sz
    add hl, bc
    add hl, bc      ; hl = ay_sounds_sz[ id ]

    ld a,(hl)
    ld (de),a
    inc hl
    inc de
    ld a,(hl)
    ld (de),a       ; ay_play_remains[ available ] = ay_sounds_sz[ id ]

    ret

; ---------------------------------
; void SoundStop()
; ---------------------------------
; Function SoundStop
; ---------------------------------
_SoundStop:
IFDEF __SPECTRUM__
;sound.c:159: if ( soundSystem == SOUND_SYS_BEEPER )
    ld  a,(_soundSystem)
    cp  SOUND_SYS_BEEPER
    ret nz
;sound.c:160: stopFX();
    call _stopFX
;sound.c:161: playingSound = 0;
    xor a
    ld  (_playingSound),a
;sound.c:162: soundStopped = 1;
    inc a
    ld  (soundStopped),a
ENDIF
    ret

; ---------------------------------
; void SoundStopAll()
; ---------------------------------
; Function SoundStopAll
; ---------------------------------

_SoundStopAll:
;sound.c:169: if ( soundSystem == SOUND_SYS_BEEPER )
    ld  a,(_soundSystem)

;sound.c:175: if ( soundSystem != SOUND_SYS_OFF )
    cp  SOUND_SYS_OFF
    ret z

IFDEF __SPECTRUM__
    cp  SOUND_SYS_BEEPER
    jr  z, _SoundStop       ; SoundStop();
ENDIF

;    ; Mixer all off
;    ld  bc,(soundPIORegister)
;    ld  a,7
;    out (c),a
;
;    ld  bc,(soundPIOData)
;    ld  a,255
;    out (c),a

    xor a
    ld (ay_used_channels_id),a
    ld (ay_used_channels_id+1),a
    ld (ay_used_channels_id+2),a

    ld  e, 8        ; volume canal A
l_SoundStopAll_loop:
    ; Channel X - Volume 0
    ld  bc,(soundPIORegister)
    out (c),e

    ld  bc,(soundPIOData)
    xor a
    out (c),a

    inc e
    ld  a,e
    cp  11          ; canal C done
    jr  nz, l_SoundStopAll_loop

    ret

; ---------------------------------

execute_channel:
    ld  a,(ay_used_channels_id)
used1: equ $-2

    or  a
    ret z                   ; !ay_used_channels_id[ channel ] then return

    ld  hl,(ay_play_remains)
remains1: equ $-2

    bit 7,h
    jp  nz,free_channel     ; ay_play_remains[ channel ] < 0  then free_channel
    ld  a,l
    or  h
    jp  z,free_channel      ; !ay_play_remains[ channel ]     then free_channel

    ex  de,hl               ; de = ay_play_remains[ channel ]

    ld  hl,(ay_play_ptr)
play_data1: equ $-2

    ld  a,(hl)              ; cmd
    inc hl                  ; inc ay_play_ptr
    dec de                  ; dec remains

    push de                 ; push remains

    ld  (cmd),a             ; cmd
    ld  e,a                 ; cmd
    
    cpl
    and 0x90                ; get tone and noise mixer bits

    ; rotate mixer flags to right
    ; 4 if channel is A (bits 0 and 3) 0x09
    ; 3 if channel is B (bits 1 and 4) 0x12
    ; 2 if channel is C (bits 2 and 5) 0x24

    srl a                   ; CB 3F
    srl a
rotate_mixer1:
    srl a
rotate_mixer2:
    srl a

    ; mixer
    cpl
    ld  b,a
    ld  a,(mix)
    and b
    ld  (mix),a

    ; volume
    ld  bc,(soundPIORegister)
    ld  a,8
volume1: equ $-1
    out (c),a

    ld  a,e                 ; cmd
    and 0x0f                ; volume value = cmd & 0x0f

    ld  bc,(soundPIOData)
    out (c),a

    ; tone frequency
    ld  a,e                 ; cmd
    pop de                  ; pop de = remains
    and 0x20                ; data tone is available?
    jp  z, check_if_noise

    ; tone fine
    ld  bc,(soundPIORegister)
    ld  a,0
tone1: equ $-1
    out (c),a

    ld  a,(hl)              ; get fine tone data
    inc hl                  ; inc ay_play_ptr
    dec de                  ; dec remains

    ld  bc,(soundPIOData)
    out (c),a

    ; tone coarse
    ld  bc,(soundPIORegister)
    ld  a,1
tone2: equ $-1
    out (c),a

    ld  a,(hl)              ; get coarse tone data
    and 0x0f                ;
    inc hl                  ; inc ay_play_ptr
    dec de                  ; dec remains

    ld  bc,(soundPIOData)
    out (c),a

check_if_noise:
    ; noise
    ld  a,(cmd)             ; cmd
    and 0x40                ; noise is available?
    jp  z, channel_done   

    ; noise frequency
    ld  bc,(soundPIORegister)
    ld  a,6
    out (c),a

    ld  a,(hl)              ; get noise data
    and 0x1f                ;
    inc hl                  ; inc ay_play_ptr
    dec de                  ; dec remains

    ld  bc,(soundPIOData)
    out (c),a

    jr  channel_done

free_channel:
    ; volume
    ld  bc,(soundPIORegister)
    ld  a,8
volume2: equ $-1
    out (c),a

    ld  bc,(soundPIOData)
    xor a
    out (c),a               ; set volume to 0

    ld  (ay_used_channels_id),a     ; free channel
used2: equ $-2

    ; de = 0
    ld  d,a
    ld  e,a                 ; remains = 0

channel_done:
    ld  (ay_play_remains),de
remains2: equ $-2

    ld  (ay_play_ptr),hl
play_data2: equ $-2

    ret

; ---------------------------------
; cmd+vol byte:  [NntTvvvv]            T(one)/N(oise) -> 1=off;  v=0 silence
; tone (word):   [dddddddd][xxxxdddd]  (only if t=1)  d=tone value
; noise (byte):  [EEEnnnnn]            (only if n=1) E=EndOfSfx n=noise value
; 
; end marker:
; cmd_vol byte   [11010000] 0xD0        ; T and N are off, volume is 0
; noise (byte)   [00100000] 0x20        ; noise is 0
; ---------------------------------

; ---------------------------------
; Function SoundExecute
; ---------------------------------

_SoundExecute:
    
    ld hl,_soundSystem
    ld a,(hl)
    cp SOUND_SYS_OFF        ; SOUND_SYS_OFF
    ret z

IFDEF __SPECTRUM__
    cp SOUND_SYS_BEEPER     ; SOUND_SYS_BEEPER
    jp nz, no_sys_beeper

    ld hl,_playingSound
    ld a,(hl)
    or a
    ret z
    
    ld l,(hl)
;    di
    call _playFX
;    ei

    ld hl,soundStopped
    ld a,(hl)
    or a
    jp nz, set_stopped
    
    ld (_playingSound),a ; = 0
    ret

set_stopped:
    ld (hl),0
    ret

no_sys_beeper:
ENDIF

IFDEF __SPECTRUM__
    di
ENDIF
    ld a,0xff
    ld (mix),a

    ; channel A

    ld hl,ay_used_channels_id
    ld (used1),hl
    ld (used2),hl

    ld hl,ay_play_remains
    ld (remains1),hl
    ld (remains2),hl

    ld hl,ay_play_ptr
    ld (play_data1),hl
    ld (play_data2),hl

    ld hl,0x3fcb ; rlc a
    ld (rotate_mixer1),hl
    ld (rotate_mixer2),hl

    ld a,8
    ld (volume1),a
    ld (volume2),a

    ld a,0
    ld (tone1),a
    inc a
    ld (tone2),a

    call execute_channel

    ; channel B

    ld hl,ay_used_channels_id+1
    ld (used1),hl
    ld (used2),hl

    ld hl,ay_play_remains+2
    ld (remains1),hl
    ld (remains2),hl

    ld hl,ay_play_ptr+2
    ld (play_data1),hl
    ld (play_data2),hl

    ld hl,0x3fcb ; rlc a
    ld (rotate_mixer1),hl
    ld hl,0x0000 ; nop + nop
    ld (rotate_mixer2),hl

    ld a,9
    ld (volume1),a
    ld (volume2),a

    ld a,2
    ld (tone1),a
    inc a
    ld (tone2),a

    call execute_channel

    ; channel C

    ld hl,ay_used_channels_id+2
    ld (used1),hl
    ld (used2),hl

    ld hl,ay_play_remains+4
    ld (remains1),hl
    ld (remains2),hl

    ld hl,ay_play_ptr+4
    ld (play_data1),hl
    ld (play_data2),hl

    ld hl,0x0000 ; nop nop
    ld (rotate_mixer1),hl
    ld (rotate_mixer2),hl

    ld a,10
    ld (volume1),a
    ld (volume2),a

    ld a,4
    ld (tone1),a
    inc a
    ld (tone2),a

    call execute_channel

    ; setup mixer

    ld bc,(soundPIORegister)
    ld a,7
    out (c),a

    ld bc,(soundPIOData)
    ld a,(mix)
    out (c),a

IFDEF __SPECTRUM__
    ei
    halt
ENDIF
    ret

; ---------------------------------


include "common.inc"

; typedef struct {                
;     uint8_t active;             +0   
;     uint8_t aniFrame;           +1     
;     int16_t explodingCnt;       +2        
;     int16_t x, y;               +4, +6
; } _alienShotInfo;                


;struct {
;    uint8_t demo:1;
;    uint8_t killed:1;
;    uint8_t shotReady:1;
;    uint8_t currPlayer:1;
;    uint8_t playerIsAlive:1;    
;    uint8_t waitForEventsComplete:1;
;    uint8_t downFleet:2;
;} state1;

;state1 & 0x01      demo
;state1 & 0x10      playerIsAlive
;
;state1 | 0x20      waitForEventsComplete
;state1 & 0xEF      playerIsAlive = 0

defc DEMO_BIT                   = 0
defc KILLED_BIT                 = 1
defc SHOTREADY_BIT              = 2
defc CURRPLAYER_BIT             = 3
defc PLAYERISALIVE_BIT          = 4
defc WAITFOREVENTSCOMPLETE_BIT  = 5
;defc DOWNFLEET_BIT              = 6

defc DEMO_MASK                  = 0x01
defc KILLED_MASK                = 0x02
defc SHOTREADY_MASK             = 0x04
defc CURRPLAYER_MASK            = 0x08
defc PLAYERISALIVE_MASK         = 0x10
defc WAITFOREVENTSCOMPLETE_MASK = 0x20

defc DOWNFLEET_1_MASK           = 0x40
defc DOWNFLEET_2_MASK           = 0x80
defc DOWNFLEET_MASK             = ( DOWNFLEET_1_MASK | DOWNFLEET_2_MASK )

EXTERN _playerPtr, _playerX, _state1, _playerExplodingCnt
EXTERN _Point, _Point_internal, _PutSprite1Merge, _PutSprite1Delete
EXTERN _AShotExplo

IFNDEF __NOSOUND__
IFDEF __ZXN__
EXTERN _SoundStop
ENDIF
EXTERN _SoundPlay
ENDIF

SECTION code_user

; ----------------------------------------------------------

PUBLIC _handleAlienShot

; ----------------------------------------------------------

; _alienShotInfo * asi, void * _sprite
_handleAlienShot:
    pop hl              ; return
    pop de              ; _alienShotInfo
    ex (sp),hl          ; _sprite

    ; return is not shot
    ld a, (de)
    or a
    ret z

    push de             ; push _alienShotInfo
    ex (sp),ix          ; put ix in stack
                        ; ix = _alienShotInfo

    ld b,h
    ld c,l

    ld a,(ix+1)         ; aniFrame
    ld e,a 
    add a,8 
    and 0x1f 
    ld (ix+1),a         ; asi->aniFrame += 8 
    ld l,a
    xor a
    ld h,a

    add hl,bc
    push hl             ; next animation sprite + aniframe

    ld l,e
    ld h,a
    add hl,bc           ; sprite + aniframe

    ld c,(ix+4)         ; x
    ld b,(ix+6)         ; y

    push bc
    
    call _PutSprite1D_internal

    pop bc

    inc b
    inc b
    ld a,b              ; asi->y += 2
    ld (ix+6),a         ; y

    ; if ( asi->y < PLAYERY + 8 ) ; menor al fin bajo del player
    cp PLAYERY+8
    jp nc, hAS_draw_alien_shot_explosion

    ; if ( asi->y + 8 > PLAYERY && asi->x < playerX + 14 && asi->x + 2 > playerX + 2 )
    cp PLAYERY  ; -8
    jp c, hAS_test_shield_collision

    ld a,(_playerX)
    dec a
    cp a,c
    jp nc, hAS_test_shield_collision

    add a, 15   ; 14
    cp a,c
    jp c, hAS_test_shield_collision

    ld (ix+0),0         ; asi->active = 0

    ld a,(_state1)
    bit PLAYERISALIVE_BIT,a             ; playerIsAlive
    jp z, hAS_pop_sprite_and_exit

    ; player collision

    or WAITFOREVENTSCOMPLETE_MASK       ; waitForEventsComplete = 1
    and ~PLAYERISALIVE_MASK             ; playerIsAlive = 0 (0xef)
    ld (_state1),a

IFNDEF __NOSOUND__
    and DEMO_MASK
    jp nz, hAS_nosound  ; if ( !state1.demo ) SoundPlay( SOUND_PLAYER_EXPLOSION );
IFDEF __ZXN__
    ld l, SOUND_PLAYER_SHOT
    call _SoundStop
ENDIF
    ld l, SOUND_PLAYER_EXPLOSION
    call _SoundPlay
hAS_nosound:
ENDIF

    ld a,60
    ld (_playerExplodingCnt),a
    jp hAS_pop_sprite_and_exit

hAS_test_shield_collision:
    ; Shield Collision?

    ; if ( asi->y + 8 > playerPtr->currentShieldTopY - 4 && asi->y + 8 < SHIELDTOPY + 24 )
    ld hl,(_playerPtr)
    ld de, 88           ; playerPtr->currentShieldTopY
    add hl,de
    ld a,(hl)
    sub 12
    ld l,a

    ld a,b              ; asi->y
    cp l
    jp c, hAS_draw_shot2

    cp SHIELDTOPY + 24 - 8
    jp nc, hAS_draw_shot2

    ; if ( Point( asi->x, asi->y + 6 ) || Point( asi->x + 1, asi->y + 6 ) || Point( asi->x + 2, asi->y + 6 ) )

;    ld l,c              ; x
    ld a,b              ; y

    push bc             ; push x,y

    add a,6
    ld b,a
    push bc
    call _Point_internal

    ld a,l
    pop bc
    or a
    jp nz, hAS_shield_collision

    inc c
    push bc
    call _Point_internal

    ld a,l
    pop bc
    or a
    jp nz, hAS_shield_collision

    inc c
    call _Point_internal

    ld a,l
    or a
    jp z, hAS_draw_shot    

hAS_shield_collision:
    pop bc
;    ld a,(ix+6)
    ld  a,b
    add a,2             ; asi->y += 2
    jp hAS_draw_alien_shot_explosion_Y

hAS_draw_shot:
    pop bc
hAS_draw_shot2:
    pop hl              ; restore sprite pre-calculated
;    ld b,(ix+6)         ; y
;    ld c,(ix+4)         ; x
    call _PutSprite1M_internal
    jp hAS_end

hAS_draw_alien_shot_explosion:
    ld a, PLAYERY+8

hAS_draw_alien_shot_explosion_Y:
    ld (ix+6),a         ; y
    ld hl, _AShotExplo  ; Sprite Alien Shot Explosion
    ld b,a              ; y
;    ld c,(ix+4)         ; x
    dec c
    dec c
    call _PutSprite1M_internal

    xor a
    ld (ix+0),a         ; asi->active = 0
    ld (ix+2),8         ; asi->explodingCnt = 8
    ld (ix+3),a

hAS_pop_sprite_and_exit:
    pop de              ; pop sprite

hAS_end:
    pop ix
    ret

; ----------------------------------------------------------

EXTERN _aRow, _aCol, _getDivideBy12

PUBLIC _getAlienIdx

; playerPtr->alienIdx is the next idx
; getAlienIdx( word x, word y, byte skipAdjust )

_getAlienIdx:
    pop bc          ; return
    pop hl          ; x
    pop de          ; y
    dec sp
    pop af          ; b = skip
    push bc

    ld b,a

    push ix         ; save ix

    ld ix,(_playerPtr)

gAI_entry:
    ld a,l
    sub (ix+66)     ; aliensX

    cp 175
    jp nc, gAI_fail

    srl a
    srl a
    srl a
    srl a           ; divide by 16

    ld (_aCol),a    ;
    ld d,a          ; d = col

    ld a,(ix+68)    ; aliensY
    sub e 

    cp 4 * ( 8 + FLEETDELTAY ) + 7
    jp nc, gAI_fail

    push hl

    ld l,a
    call _getDivideBy12

    ld a,l          ; faster that ld (_aRow),l
    ld (_aRow),a    ;

    push de         ; preserve y
    push de

    xor a
    ld h,a
    
    ld d,h
    ld e,l

    add hl,hl
    add hl,hl
    add hl,hl
    add hl,de
    add hl,de
    add hl,de       ; row * 11

    pop de

    ld e,d          ; col
    ld d,a
    add hl,de       ;

                    ; hl = row * 11 + col
    pop de

    ld a,b          ; skip adjust
    or a
    jp nz, gAI_ret_idx

    ld a,l
    ld b,(ix+72)    ; aliensIdx
    cp b
    jp c, gAI_ret_idx

    pop hl  ; restore x

    ld a,(_state1)
    and DOWNFLEET_MASK
    jp z, gAI_no_downfleet

    ex de,hl
    ld bc,FLEETDELTAY
    add hl,bc
    ex de,hl
    ld b,1
    jp gAI_entry

gAI_no_downfleet:
    ld a,(ix+70) ; aliensDeltaX
    ld bc,-2
    or a
    jp m, gAI_deltaX

    ld a,(ix+0)  ; numAliens
    ld bc,2
    cp c
    jp nc, gAI_deltaX

    ld bc,3
gAI_deltaX:
    add hl,bc
    ld b,1
    jp gAI_entry

gAI_fail:
    pop ix
    ld hl,-1
    ret

gAI_ret_idx:
    pop af  ; pop hl to trash
            ; hl = idx
    pop ix
    ret

; ----------------------------------------------------------

PUBLIC _getAlienColumn
; WARNING: check if aliensX must be 16bits in this function
_getAlienColumn:
    ld a,l

    ld hl,(_playerPtr)
    ld de,66        ; aliensX
    add hl,de
    ld h,(hl)
    sub h

    cp 175
    jp nc, gAC_fail

    srl a
    srl a
    srl a
    srl a           ; divide by 16

    ld l,a          ; l = col
    ret

gAC_fail:
    ld l,-1
    ret

; ----------------------------------------------------------


EXTERN _shotX, _shotY, _PlayerShotSpr, _shotYOld, _ShotExploding
EXTERN _PutSprite1_internal, _PutSprite1M_internal, _PutSprite1D_internal, _PutSprite2_internal
EXTERN _SoundExecute
EXTERN _shotExplodingCnt

PUBLIC _handleAShotCollision

; _alienShotInfo * asi, short aShotYH, void * spr
_handleAShotCollision:
    pop hl              ; return
    pop de              ; _alienShotInfo
    dec sp
    pop bc              ; aShotYH (alienShotY Height)
    ex (sp),hl          ; _sprite <-> return

    ld a,(_state1)      ; killed?
    and KILLED_MASK
    ret nz

    push de             ; push _alienShotInfo
    ex (sp),ix          ; put ix in stack
                        ; ix = _alienShotInfo

    ld a,(ix+0)         ; asi->active?
    or a
    jp z, hASC_no_collision

; hl = sprite
; ix = _alienShotInfo
; b = aShotYH (alienShotY Height)

    ; if ( ( uint16_t ) ( shotX - asi->x ) < 3 && shotY + 4 < asi->y + aShotYH && shotY + 8 > asi->y )
    ld a,(_shotX)
    sub (ix+4)          ; asi->x
    cp 3
    jp nc, hASC_no_collision

    ld a,(_shotY)
    ld d,(ix+6)         ; asi->y
    add 4
    sub b
    cp d
    jp nc, hASC_no_collision

    add b
    add 3
    cp d
    jp c, hASC_no_collision

    ; PutSprite1Delete( asi->x, asi->y, spr + asi->aniFrame ); // Delete
    ld e,(ix+1)         ; aniFrame
    ld d,0              ;
    add hl,de           ; sprite + aniframe
    ld c,(ix+4)         ; x
    push bc             ; save x and aShotYH
    ld b,(ix+6)         ; y
    call _PutSprite1D_internal

    ; PutSprite1Delete( shotX, shotYOld + 2, PlayerShotSpr ); // Delete
    ld hl,_PlayerShotSpr
    ld a,(_shotYOld)    ; y
;    inc a
;    inc a
    ld b,a
    ld a,(_shotX)       ; x
    ld c,a
    call _PutSprite1D_internal

    ; PutSprite1Merge( shotX - 4, shotY + 2, ShotExploding );
    ld hl,_ShotExploding
    ld a,(_shotY)       ; y
;    inc a
;    inc a
    ld b,a
    ld a,(_shotX)       ; x
    dec a
    dec a
    dec a
    dec a
    ld c,a
    call _PutSprite1M_internal

    ld hl,(_shotY)
    xor a               ; neg hl
    sub l               ; neg hl
    ld l,a              ; neg hl
    sbc a,a             ; neg hl
    sub h               ; neg hl
    ld h,a              ; neg hl
    ld (_shotY),hl      ; _shotY

    xor a
    ld (ix+0),a

    ld hl,_state1       ; killed
    ld a,(hl)           ; killed
    or KILLED_MASK      ; killed
    ld (hl),a           ; killed

    ld a,8
    ld (_shotExplodingCnt),a

    ; Draw Alien Shot Explosion
    pop bc              ; restore x and aShotYH
    ld a,(ix+6)         ; y
    add b               ; + aShotYH

    push de             ; for pop in hAS_draw_alien_shot_explosion_Y
    jp hAS_draw_alien_shot_explosion_Y

hASC_no_collision:
    pop ix
    ret

; ----------------------------------------------------------

SECTION data_user

deltaX: dw 0
deltaY: dw 0
row: db 0
posX: db 0
posY: db 0

SECTION code_user

EXTERN _aliensFrames, _alienAnimationStatus, _alienSoundCnt, _DeleteTopAlien, _ClearRows
EXTERN _getAliensDeltaPos
EXTERN _AlienSprites
IFDEF __ZXN__
EXTERN _SoundIsPlaying
ENDIF

PUBLIC _handleNextAlien

_handleNextAlien:
    ld hl,_aliensFrames     ; aliensFrames++
    inc (hl)                ; aliensFrames++
    ld a,(hl)               ; 
    sub ALIENSPEED          ; 
    ret nz                  ; aliensFrames >= ALIENSPEED
    ld (hl),a ; = 0         ; aliensFrames = 0

    push ix
    ld ix,(_playerPtr)

    ld hl,(_playerPtr)
    ld de,0x09
    add hl,de               ; playerPtr->aliens

    ld e,l
    ld d,h                  ; save playerPtr->aliens

    ld a,(ix+72)            ; playerPtr->alienIdx
    ld c,a
    ld b,0
    add hl,bc               ; &playerPtr->aliens[playerPtr->alienIdx]

    ld b,c
    jp hNA_loop1_test

hNA_loop1:
    ld a,(hl)
    or a
    jp nz,hNA_idx_found

    inc hl

    inc c
    ld a,c
hNA_loop1_test:
    cp 55
    jp c, hNA_loop1

    ld l,e                  ; restore playerPtr->aliens
    ld h,d                  ; playerPtr->aliens

    ld c,0                  ; playerPtr->alienIdx = 0

hNA_loop2:
    ld a,(hl)
    or a
    jp nz,hNA_idx_found2do

    inc hl

    inc c
    ld a,c
    cp b
    jp c, hNA_loop2

    jp hNA_exit         ; error!

hNA_idx_found2do:
    ld (ix+72),c        ; playerPtr->alienIdx


IFNDEF __NOSOUND__
    ; if ( !state1.demo ) SoundPlay( SOUND_ALIEN_STEP1 + ( ( alienSoundCnt++ ) & 0x03 ) );
    ld a,(_state1)
    and DEMO_MASK
    jp nz, hNA_nosound1

IFDEF __ZXN__
    ld l, SOUND_ALIEN_EXPLOSION ; play alien step sound if no alien explosion
    call _SoundIsPlaying
    xor a
    cp l
    jr nz, hNA_nosound1

    ld hl,_alienSoundCnt
    add SOUND_ALIEN_STEP1
    push hl
    ld l,a
    call _SoundStop
    pop hl
    ld a,(hl)
    inc a
    and 0x03
    ld (hl),a
    add SOUND_ALIEN_STEP1
    ld l, a
ENDIF
IFNDEF __ZXN__
    ld l, SOUND_ALIEN_STEP1
ENDIF
    call _SoundPlay
hNA_nosound1:
ENDIF

    ld hl,_alienAnimationStatus
    ld a,(hl)
    xor 16
    ld (hl),a

    ; state1.downfleet = 0
    ld hl,_state1
    ld a,(hl)
    and ~DOWNFLEET_MASK         ; 0x3f
    ld (hl),a

    ; tDeltaX = playerPtr->aliensDeltaX < 0 ? -2 : playerPtr->numAliens > 1 ? 2 : 3;

    ld a,(ix+70)                ; playerPtr->aliensDeltaX
    ld bc,-2
    or a
    jp m, hNA_incAlienRow       ; right to left and is_negative

    ld a,(ix+0)                 ; playerPtr->numAliens
    ld bc,2
    cp c
    jp nc, hNA_incAlienRow      ; left to right and numAliens > 1

    ld c,3                      ; left to right and numAliens == 1

                                ; tDeltaX = bc

hNA_incAlienRow:

    ld l,(ix+66)        ; playerPtr->aliensX
    ld h,(ix+67)        ; playerPtr->aliensX
    add hl,bc           ; playerPtr->aliensX += tDeltaX
    ld (ix+66),l        ; playerPtr->aliensX
    ld (ix+67),h        ; playerPtr->aliensX

    ; if ( playerPtr->aliensX < playerPtr->leftLimit || ...

    ld e,(ix+3)         ; playerPtr->leftLimit
    ld d,(ix+4)         ; playerPtr->leftLimit

    or a                ; cp hl,de
    sbc hl,de           ; cp hl,de
    add hl,de           ; cp hl,de

    jp m, hNA_reach_limits

    ; if ... || playerPtr->aliensX > playerPtr->rightLimit )

    ld e,(ix+5)         ; playerPtr->rightLimit
    ld d,(ix+6)         ; playerPtr->rightLimit

    or a                ; cp hl,de
    sbc hl,de           ; cp hl,de
    add hl,de           ; cp hl,de
    jp m, hNA_no_reach_limits

hNA_reach_limits:

    ld de,_state1
    ld a,(de)           ; state1.downFleet = 0x02
    and ~DOWNFLEET_MASK
    or DOWNFLEET_2_MASK ; state1.downFleet = 0x02
    ld (de),a           ; state1.downFleet = 0x02

    or a                ; reset Carry
    sbc hl,bc           ; playerPtr->aliensX -= tDeltaX
    ld (ix+66),l        ; playerPtr->aliensX
    ld (ix+67),h        ; playerPtr->aliensX

    ld e,(ix+70)        ;
    ld d,(ix+71)        ; aliensDeltaX
    xor a               ; neg hl
    sub e               ; neg hl
    ld e,a              ; neg hl
    sbc a,a             ; neg hl
    sub d               ; neg hl
    ld d,a              ; neg hl
    ld (ix+70),e        ;
    ld (ix+71),d        ; aliensDeltaX

    ld bc,FLEETDELTAY
    ld l, (ix+68)       ; playerPtr->aliensY
    ld h, (ix+69)       ; playerPtr->aliensY
    add hl,bc           ; playerPtr->aliensY += FLEETDELTAY
    ld (ix+68),l        ; playerPtr->aliensY
    ld (ix+69),h        ; playerPtr->aliensY

hNA_no_reach_limits:
    jp hNA_draw_alien

hNA_idx_found:
    ld (ix+72),c

hNA_draw_alien:

; REVISAR
    ld bc,row
    ld de,deltaY
    ld hl,deltaX

    push bc
    push de
    push hl
    call _getAliensDeltaPos
    ld hl,6
    add hl,sp
    ld sp,hl

    ; uint8_t posX = playerPtr->aliensX + deltaX,
    ;         posY = playerPtr->aliensY + deltaY;
    ; b = posY
    ; c = posX

    ld a,(ix+68)    ; aliensY
    ld b,a
    ld a,(deltaY)
    add a,b
    ld b,a

    ld a,(ix+66)    ; aliensX
    ld c,a
    ld a,(deltaX)
    add a,c
    ld c,a

    ld (posX),bc

    ld a,(_state1)
    and DOWNFLEET_MASK      ; if ( state1.downFleet )
    jp z,hNA_put_alien

    ; PutSprite1Delete(    posX    , posY - FLEETDELTAY, DeleteTopAlien );
    ld hl,_DeleteTopAlien   ; sprite
    ld a,-FLEETDELTAY       ; posY - FLEETDELTAY
    add a,b
    ld b,a
    push bc
    call _PutSprite1D_internal

    ; PutSprite1Delete(    posX + 8, posY - FLEETDELTAY, DeleteTopAlien );
    ld hl,_DeleteTopAlien   ; sprite
    pop bc
    ld a,8
    add a,c
    ld c,a
    call _PutSprite1D_internal

    ld a,(_state1)
    and DOWNFLEET_2_MASK    ; if ( state1.downFleet & 0x02 )
    jp z,hNA_test_alien_reach_player

    ld a,(posY)
    ld c,a
    add 8
    ld c,a
    ld a,(ix+88)        ; posY + 8 > playerPtr->currentShieldTopY
    cp c
    jp nc,hNA_test_alien_reach_player

    ld e,c      ; save bc, posX and posY

    ld a,-FLEETDELTAY
    add a,c
    ld c,a
    ld b,FLEETDELTAY
    push    bc
    call _ClearRows

    ld (ix+88),e        ; playerPtr->currentShieldTopY = posY + 8

    ld hl,_state1
    ld a,(hl)
    and ~DOWNFLEET_MASK ; state1.downFleet = 0x01
    or DOWNFLEET_1_MASK ; state1.downFleet = 0x01
    ld (hl),a

hNA_test_alien_reach_player:

    ld a,(posY)
    add a,FLEETDELTAY
    cp PLAYERY
    jp c,hNA_put_alien

    ld a,60
    ld (_playerExplodingCnt),a

    ld hl,_state1
    ld a,(hl)
    or WAITFOREVENTSCOMPLETE_MASK   ; waitForEventsComplete = 1
    and ~PLAYERISALIVE_MASK         ; playerIsAlive = 0
    ld (hl),a

IFNDEF __NOSOUND__
    and DEMO_MASK
    jp nz, hNA_nosound2     ; if ( !state1.demo ) SoundPlay( SOUND_PLAYER_EXPLOSION );
IFDEF __ZXN__
    ld l, SOUND_PLAYER_SHOT
    call _SoundStop
ENDIF
    ld l, SOUND_PLAYER_EXPLOSION
    call _SoundPlay
hNA_nosound2:
ENDIF

    ld a,60
    ld (_playerExplodingCnt),a

    ld a,(ix+85)       ; playerPtr->numShips
    or a
    jp z,hNA_put_alien ; reach but finish
    ld a,1
    ld (ix+85),a       ; playerPtr->numShips = 1
  
hNA_put_alien:
    ld de, _AlienSprites
    ld a,(row)
    ld l,a
    ld h,0
    add hl,hl
    add hl,de ; &AlienSprites[ row ]

    ld a,(hl)
    inc hl
    ld h,(hl)
    ld l,a    ; AlienSprites[ row ]

    ld a,(_alienAnimationStatus)
    ld e,a 
    ld d,0
    add hl,de
    ld bc,(posX)
    call _PutSprite2_internal

    inc (ix+72)         ; playerPtr->alienIdx++

hNA_exit:
    pop ix
    ret

; ---------------------------------

SECTION data_user

clearScoreStr:      db "      ", 0
groundLineStr:      db "################################", 0
gameOverStr:        db "GAME OVER", 0
gameOverPlayerStr:  db "GAME OVER  PLAYER< >", 0
playPlayerStr:      db "PLAY PLAYER< >", 0

SECTION code_user

EXTERN _DelayFrames, _DrawShips, _DrawScoreHeaderAndCredits, _DrawShields, _iterGame, _StoreShields, _hiScoreUpdate
EXTERN _PrintAt, _PrintChar, _PrintNumAt, _PrintAtDelay
EXTERN _playersInGame, _gameState, _playersInGame, _player, _reloadCnt

PUBLIC _playGame

; ---------------------------------
; Function playGame
; ---------------------------------
_playGame:

;round.c:965: state1.demo = _demo;
    ld  a,l
    and DEMO_MASK
    ld  b,a

    ld  hl,_state1
    ld  a,(hl)
    and ~DEMO_MASK
    or  b
    ld  (hl), a

;round.c:969: resetPlayer( 1, 1 );
    ld  hl,0x0101
    push hl
    call _resetPlayer

;round.c:970: resetPlayer( 0, 1 );
    ld  hl,0x0100
    push hl
    call _resetPlayer

;round.c:974: state1.currPlayer = 0;
    ld  hl,_state1
    res CURRPLAYER_BIT, (hl)

;round.c:976: if ( state1.demo ) playersInGame = 1;
    bit DEMO_BIT, (hl)
    jr  Z,start_round
    ld  a,0x01
    ld  (_playersInGame),a

start_round:
;round.c:979: gameState = 0;
    xor  a
    ld  (_gameState),a


IFNDEF __NOSOUND__
IFDEF __ZXN__
    ld l,-1
    call _SoundStop
ENDIF
ENDIF

;round.c:981: ClearRows( 16, 168 );
    ld  de, 16 + ( 168 * 256 )
    push de
    call _ClearRows

;round.c:985: DrawShips();
    call _DrawShips

;round.c:987: if ( !state1.demo ) {
    ld  a,(_state1)
    and DEMO_MASK
    jr  NZ,l_playGame_demo1

;round.c:983: DrawScoreHeaderAndCredits();
    call _DrawScoreHeaderAndCredits

;round.c:988: PrintAt(  81,  78, "PLAY PLAYER< >" );
    ld  hl, playPlayerStr
    push hl
    ld  de, 81 + 78 * 256   ; x=81, y=78
    push de
    call _PrintAt
    pop af
    pop af

;round.c:989: PrintChar( 177,  78, ( !state1.currPlayer ? '1' : '2' ), 0 );
    ld hl, _state1
    bit CURRPLAYER_BIT, (hl)
    jr  nz,l_playGame_player2
    ld  hl,0x0031
    ld  e, 16           ; x for score player 1
    jr  l_playGame_print_player_num
l_playGame_player2:
    ld  hl,0x0032
    ld  e, 208          ; x for score player 1
l_playGame_print_player_num:
    push de             ; save x for score
    push hl
    ld  hl, 177 + ( 78 * 256 )  ; x=177, y=78
    push hl
    call _PrintChar

    ; e = x
    pop de              ; restore x for score
;round.c:991: for ( n = 0; n < 17; n++ ) {

    ld  b,17
l_playGame_blink_score_loop:

;round.c:992: PrintAt( !state1.currPlayer ? 16 : 208, 8, "      " );
    push bc          ; loop
    push de          ; save x

    ld  hl,clearScoreStr
    push hl
    ld  h,0x08
    ld  l,e             ; x
    push hl
    call _PrintAt
    pop af
    pop af

    ld l,3
    call _DelayFrames

;round.c:997: PrintNumAt( !state1.currPlayer ? 16 : 208, 8, playerPtr->score, 4 | NUM_LEFTZERO );
    ld  de, (_playerPtr)
    ld  hl, 79            ; playerPtr->score 
    add hl, de
    ld  e, (hl)
    inc hl
    ld  d, (hl)
    ex de,hl

    pop de
    push de

    ld  a, 4 | NUM_LEFTZERO
    push af
    inc sp
    push hl
    ld d,0x08
    push de
    call _PrintNumAt
    pop af
    pop af
    inc sp

    ld l,3
    call _DelayFrames

    pop de
    pop bc

    djnz l_playGame_blink_score_loop


;round.c:1003: ClearRows( 16, 168 );
    ld  de, 16 + ( 168 * 256 )
    push de
    call _ClearRows

l_playGame_demo1:
;round.c:1006: DrawShields();
    call _DrawShields

;round.c:1008: PrintAt( 0, ( uint8_t ) ( PLAYERY + 8 ), "################################" );
    ld  hl, groundLineStr
    push hl
    ld  hl, 0 + ( PLAYERY + 8 ) * 256
    push hl
    call  _PrintAt
    pop af
    pop af

;round.c:1010: resetRoundVars();
    call _resetRoundVars

;round.c:1012: gameState = 1;
    ld  hl,_gameState
    ld  (hl),0x01

;round.c:1015: while ( 1 ) {
l_playGame_forever_loop:
;round.c:1020: gameState = iterGame();

IFNDEF __NOSOUND__
;    ld  a,(_state1)
;    and DEMO_MASK
;    call z,_SoundExecute
    call _SoundExecute
ENDIF
IFDEF __ZX81__
    call _iterGame
    ld  a, l
    ld (_gameState),a
ENDIF

IFDEF __SPECTRUM__
    ld a,(_gameState)
ENDIF

;round.c:1023: switch ( gameState ) {

    or  a,a
    jr  Z,l_playGame_demo_complete
    cp  1
    jr  Z,l_playGame_forever_loop
    cp  2
    jr  Z,l_playGame_key_on_demo
    cp  3
    jr  Z,l_playGame_next_round
    cp  4
    jp  Z,l_playGame_game_over          ; numShip = 0 - Game Over
    cp  6
    jr  Z,l_playGame_player_death       ; player lost 1 life
    jr  l_playGame_forever_loop

;round.c:1024: case    0: // demo complete
l_playGame_demo_complete:
;round.c:1025: DelayFrames( 100 ); // 2 seconds
    ld  l,100
    call _DelayFrames

;round.c:1026: return 0;
    ld  l,0x00
    ret

;round.c:1031: case    2: // key pressed on demo mode
l_playGame_key_on_demo:
;round.c:1032: return 2;
    ld  l,0x02
    ret

;round.c:1034: case    3: // next round
l_playGame_next_round:
;round.c:1035: DelayFrames( 100 ); // 2 seconds
    ld l,100
    call _DelayFrames
;round.c:1036: goto start_round;
    jp  start_round

;round.c:1041: case    6: // player death a life
l_playGame_player_death:
;round.c:1042: DelayFrames( 100 ); // 2 seconds
    ld  l,100
    call _DelayFrames

;round.c:1043: reloadCnt = 0;
    xor a
    ld  (_reloadCnt),a
;round.c:1044: if ( playersInGame > 1 ) {
    ld  hl,_playersInGame
    ld  a,1
    cp  (hl)
    jr  nc, l_playGame_cond1_false

;round.c:1045: if ( player[ state1.currPlayer ^ 1 ].numShips > 0 ) {

    ld hl, _state1
    bit CURRPLAYER_BIT, (hl)                 ; currentPlayer
IFDEF __ZX81__
    ld hl, (_player)
ENDIF
IFDEF __SPECTRUM__
    ld hl, _player
ENDIF
    jr  NZ,l_playGame_cond1a
    ; current is player 1 (bit3=0)
    ld de, 858
    add hl, de
l_playGame_cond1a:
    push hl
    ld de, 85                   ; player[^1].numShips
    add hl, de

    xor a
    cp (hl)
    jr nc, l_playGame_cond1_false_pop

    ld l, 0                     ; store  Shields
    call _StoreShields

    ld hl, _state1
    ld a,(hl)
    xor CURRPLAYER_MASK         ; switch currPlayer
    ld (hl),a

    pop hl
    ld (_playerPtr), hl

    jp  start_round

l_playGame_cond1_false_pop:
    pop af

l_playGame_cond1_false:
;round.c:1052: state1.waitForEventsComplete = 0;
    ld  hl,_state1
    res WAITFOREVENTSCOMPLETE_BIT, (hl)

;round.c:1053: state1.playerIsAlive = 1;
    set PLAYERISALIVE_BIT, (hl)

;round.c:1054: playerX = 14;
    ld  hl, 14
    ld (_playerX),hl

;round.c:1055: gameState = 1; // continue
    ld  hl,_gameState
    ld  (hl),0x01

;round.c:1058: }
    jp  l_playGame_forever_loop

;round.c:1061: game_over:
l_playGame_game_over:
;round.c:1062: hiScoreUpdate( playerPtr->score );
    ld  hl, (_playerPtr)
    ld  bc, 79
    add hl, bc
    ld  c, (hl)
    inc hl
    ld  b, (hl)
    push bc
    call _hiScoreUpdate
    pop af

;round.c:1063: if ( playersInGame == 1 ) {
    ld  a,(_playersInGame)
    dec a
    jr  NZ,l_playGame_check_is_two_players

;round.c:1064: PrintAtDelay( 88, 26, "GAME OVER", 6 );
    ld  a,0x06
    push af
    inc sp
    ld  hl, gameOverStr
    push hl
    ld  de, 88 + ( 26 * 256 )   ; x=88, y=26
    push de
    call _PrintAtDelay
    pop af
    pop af
    inc sp

;round.c:1065: DelayFrames( 100 ); // 2 seconds
    ld  l,100
    call _DelayFrames

;round.c:1066: return 1;
    ld  l,0x01
    ret

l_playGame_check_is_two_players:
;round.c:1068: } else if ( playersInGame == 2 ) {
    dec a
    jr  NZ,l_playGame_exit_gameState_0
;round.c:1069: PrintAtDelay( 48, ( uint8_t ) ( PLAYERY + 4 ), "GAME OVER  PLAYER< >", 6 );
    ld  a,0x06
    push af
    inc sp
    ld  hl, gameOverPlayerStr
    push  hl
    ld de, 48 + ( PLAYERY + 4 ) * 256   ; x=48, y=PLAYERY + 4
    push de
    call _PrintAtDelay
    pop af
    pop af
    inc sp

;round.c:1070: PrintChar( 192, ( uint8_t ) ( PLAYERY + 4 ), ( !state1.currPlayer ? '1' : '2' ), 0 );

    ld hl, _state1
    bit CURRPLAYER_BIT, (hl)                 ; current player  
IFDEF __ZX81__
    ld hl, (_player)
ENDIF
IFDEF __SPECTRUM__
    ld hl, _player
ENDIF
    ld bc, '2'                  ; current player number
    jr  NZ,l_playGame_cond2a
    ld de, 858
    add hl, de
    ld bc, '1'                  ; current player number
l_playGame_cond2a:
    push hl

    push bc
    ld  hl, 192 + ( PLAYERY + 4 ) * 256     ; x=192, y=PLAYERY + 4
    push hl
    call _PrintChar

;round.c:1071: DelayFrames( 100 ); // 2 seconds
    ld  l,100
    call _DelayFrames

;round.c:1073: state1.currPlayer ^= 1;
    ld hl, _state1
    ld a,(hl)
    xor CURRPLAYER_MASK         ; switch currPlayer
    ld (hl),a

;round.c:1074: playerPtr = &player[ state1.currPlayer ];
    pop hl
    ld (_playerPtr), hl

;round.c:1076: if ( !playerPtr->numShips ) return 1;
    ld  bc, 85                  ; numShips
    add hl, bc
    ld  a, (hl)
    or  a
    jr  z, l_playGame_return_1
    jp  start_round

;round.c:1078: goto start_round;
l_playGame_exit_gameState_0:
;round.c:1081: gameState = 0;
    ld  hl,_gameState
    ld  (hl),0x00

l_playGame_return_1:
;round.c:1083: return 1;
    ld  l,0x01
    ret


EXTERN _GetScreenAddr

PUBLIC _StoreShields

; void StoreShields( uint8_t op ) __z88dk_fastcall;
;   ---------------------------------
; Function StoreShields
; ---------------------------------
; 0 - store
;        l_storeShields_store_or_restore2 = nop
;        l_storeShields_store_or_restore1 = nop
;        l_storeShields_saved + 1 = 1
; 1 - restore
;        l_storeShields_store_or_restore2 = ex de, hl
;        l_storeShields_store_or_restore1 = ex de, hl
;        l_storeShields_saved + 1 = 0

_StoreShields:
    xor a               ; 0x00 = nop
    cp l
    ld l, 1
    jr z, l_storeShields_do_store
    dec l
    ld a, 0xeb          ; 0xeb = ex de, hl

l_storeShields_do_store:
    ld (l_storeShields_store_or_restore1),a
    ld (l_storeShields_store_or_restore2),a
    ld a,l
    ld (l_storeShields_saved + 1),a

;round.c:362: for ( i = playerPtr->currentShieldTopY, ii = 0; i < SHIELDTOPY + 24u; i++, ii+=32 )
    ld bc, (_playerPtr)

    ld hl, 90           ; shieldBackup
    add hl, bc
    ex de,hl            ; de = shieldBackup

    ld hl, 88           ; currentShieldTopY
    add hl, bc
    ld b, (hl)

; 17 bytes
l_storeShields_loop:
    push bc

    ld c,0
    push bc
    call _GetScreenAddr

    ; normal
    ; hl = screen
    ; de = backupArea

l_storeShields_store_or_restore1:
    ex de, hl           ; de = scresen
                        ; hl = backupArea

    ld bc,32
    ldir

l_storeShields_store_or_restore2:
    ex de, hl           ; hl = screen
                        ; de = backupArea

    pop bc
    inc b
    ld a,b
    cp SHIELDTOPY + 24
    jr c, l_storeShields_loop

    ld bc, (_playerPtr)
    ld hl, 89           ; shieldBackupSaved
    add hl, bc

l_storeShields_saved:
    ld (hl),0
    ret


; ---------------------------------

EXTERN _getReloadRate, _numLives, _AlienStartTable, _alienShotInfo, _asRol, _asPlu, _asSqu
IFNDEF __ZXN__
EXTERN _SoundStopAll
ENDIF

PUBLIC _resetPlayer

;round.c:273: void resetPlayer( int8_t p, int8_t isFirst ) {
; ---------------------------------
; Function resetPlayer
; ---------------------------------
_resetPlayer:
    pop hl
    pop bc
    push hl

IFDEF __ZX81__
    ld hl, (_player)            ; next player        
ENDIF
IFDEF __SPECTRUM__
    ld hl, _player              ; next player
ENDIF
    ld a,c                      ; parameter: player
    or a
    jr  z,l_resetPlayer_player_1
    ld de, 858
    add hl, de
l_resetPlayer_player_1:
    ld  (_playerPtr),hl

    ; if ( first )
    ld a,b                      ; parameter: first 
    or a

    ld b,h
    ld c,l
    
    jr z,l_resetPlayer_no_first

;round.c:291: playerPtr->score = 0;
    ld  hl, 79                  ; playerPtr->score
    add hl, bc
    xor a
    ld  (hl), a
    inc hl
    ld  (hl), a

;round.c:298: playerPtr->reloadRate = state1.demo ? 8 : getReloadRate();
    ld  a,(_state1)
    and DEMO_MASK
    jr  Z,l_resetPlayer_no_demo
    ld  de,0x0008
    jr  l_resetPlayer_setReloadRate

l_resetPlayer_no_demo:
    push bc
    call _getReloadRate
    pop bc
    ex  de, hl

l_resetPlayer_setReloadRate:
    ld  hl, 81
    add hl, bc
    ld  (hl), e                 ; hl = playerPtr->reloadRate (81-82)
    inc hl
    ld  (hl), d

;round.c:295: playerPtr->pluShotColIdx = 0;
    inc hl                      ; playerPtr->pluShotColIdx (83)
    ld  (hl),0

;round.c:296: playerPtr->squShotColIdx = 6;
    inc hl                      ; playerPtr->squShotColIdx (84)
    ld  (hl),0x06

;round.c:289: playerPtr->numShips = numLives;
    inc hl                      ; playerPtr->numShips (85)
    ld a,(_numLives)
    ld  (hl),a

;round.c:290: playerPtr->round = 0;
    inc hl                      ; playerPtr->round (86)
    ld  (hl),0

;round.c:323: playerPtr->fleetTopBase = FLEETPOSSTART;
    ld a, FLEETPOSSTART
    jr l_resetPlayer_setFleetTopBase
    ; else

l_resetPlayer_no_first:
    ld  hl, 86                  ; playerPtr->round
    add hl, bc
    inc (hl)                    ; playerPtr->round++

;round.c:323: playerPtr->fleetTopBase = AlienStartTable[ ( playerPtr->round - 1 ) & 7 ];
    ld  a,(hl)
    dec a
    and 7

    ld  l,a
    ld  h, 0
    ld  de, _AlienStartTable
    add hl, de
    ld  a,(hl)

l_resetPlayer_setFleetTopBase:
    ld  hl, 64                  ; playerPtr->fleetTopBase                       
    add hl, bc
    ld (hl), a
    ld  e, a                    ; playerPtr->fleetTopBase
    inc hl
    ld (hl),0

; l_resetPlayer_endif:

; reset a
    xor a

;round.c:315: playerPtr->numAliens = 55;
    ld  l, c
    ld  h, b
    ld  (hl), 55

;round.c:318: playerPtr->leftLimitCol = 0;
    inc hl
    ld  (hl),a

;round.c:317: playerPtr->rightLimitCol = 10;
    inc hl
    ld  (hl), 10

;round.c:321: playerPtr->leftLimit = 0;
    inc hl
    ld  (hl),a
    inc hl
    ld  (hl),a

; playerPtr->rightLimit = 256 - ( ( playerPtr->rightLimitCol * 16 ) + 16 ) - 1;
    inc hl
    ld  (hl), 79
    inc hl
    ld  (hl),a

;round.c:332: playerPtr->aliensColMask = 0b11111111111;
    inc hl
    ld  (hl),0xff
    inc hl
    ld  (hl),0x07

; init aliens[*]
    ld d, 55
    ld a, 1
l_resetPlayer_alien_reset_loop:
    inc hl 
    ld (hl),a 
    dec d
    jr nz,l_resetPlayer_alien_reset_loop

; reset a
    xor a

;round.c:328: playerPtr->aliensX = 40;
    ld hl, 66                   ; playerPtr->aliensX (66-67)
    add hl, bc
    ld  (hl), 40
    inc hl
    ld  (hl),a

;round.c:327: playerPtr->aliensY = playerPtr->fleetTopBase;
    inc hl                      ; playerPtr->aliensY (68-69)
    ld  (hl),e
    inc hl
    ld  (hl),a

;round.c:329: playerPtr->aliensDeltaX = 2;
    inc hl                      ; playerPtr->aliensDeltaX (70-71)
    ld  (hl), 2
    inc hl
    ld  (hl),a

;round.c:330: playerPtr->alienIdx = 0;
    inc hl                      ; playerPtr->alienIdx (72)
    ld  (hl),a

;round.c:306: playerPtr->tillSaucer = SAUCERTIMER; // Original Arcade 0x0600
    inc hl                      ; playerPtr->tillSaucer (73-74)
    ld  (hl), SAUCERTIMER % 256
    inc hl
    ld  (hl), SAUCERTIMER / 256

;round.c:307: playerPtr->sauScore = 0;
    inc hl                      ; playerPtr->sauScore (75)
    ld  (hl),a

;round.c:333: playerPtr->alienShotMask = 0b00101101;
    inc hl                      ; playerPtr->alienShotMask (76)
    ld  (hl), 0x2d

;round.c:311: playerPtr->shotsCounter = 0;
    inc hl                      ; playerPtr->shotCounter(77-78)
    ld  (hl),a
    inc hl
    ld  (hl),a

;round.c:337: playerPtr->currentShieldTopY = SHIELDTOPY;
    ld  hl, 88                  ; playerPtr->currentShieldTopY (88)
    add hl, bc
    ld  (hl), SHIELDTOPY

;round.c:339: playerPtr->shieldBackupSaved = 0;
    inc hl                      ; playerPtr->shieldBackupSaved (89)
    ld  (hl),a

;round.c:278: asRol = &alienShotInfo[ AS_ROL ];
    ld  hl, _alienShotInfo
    ld  (_asRol), hl

;round.c:279: asPlu = &alienShotInfo[ AS_PLU ];
    ld  hl, _alienShotInfo + 0x0008
    ld  (_asPlu), hl

;round.c:280: asSqu = &alienShotInfo[ AS_SQU ];
    ld  hl, _alienShotInfo + 0x0010
    ld  (_asSqu), hl

; clear alienShotInfo[*]
IF 0
    ; faster
    ld hl, _alienShotInfo
    ld de, _alienShotInfo + 1
    ld bc, 0x18 - 1
    ld (hl),0
    ldir
ENDIF

    ; code size
    ld hl, _alienShotInfo 
    ld b, 0x18
    xor a 
alienShotInfo_reset_loop:
    ld (hl),a 
    inc hl 
    djnz alienShotInfo_reset_loop

IFNDEF __NOSOUND__
;round.c:342: if ( !state1.demo ) SoundStopAll();
    ld  a,(_state1)
    and DEMO_MASK
IFDEF __ZXN__
    ld l, -1
    call z, _SoundStop
ELSE
    call z, _SoundStopAll
ENDIF
ENDIF
    ret

; ---------------------------------

EXTERN _alienExplodingCnt, _saucerStart, _saucerActive, _saucerExplodingCnt, _alienShotTimer, _saucerFrames, _shotFrames, _anybodyExploding, _playerFrames

PUBLIC _resetRoundVars

;round.c:218: void resetRoundVars()
; ---------------------------------
; Function resetRoundVars
; ---------------------------------
_resetRoundVars:
    xor a
;round.c:222: alienAnimationStatus = 0;
    ld  (_alienAnimationStatus),a
;round.c:224: alienExplodingCnt = 0;
    ld  (_alienExplodingCnt),a
;round.c:228: saucerStart = 0;
    ld (_saucerStart),a
;round.c:229: saucerActive = 0;
    ld (_saucerActive),a
;round.c:231: saucerExplodingCnt = 0;
    ld (_saucerExplodingCnt),a
;round.c:238: shotExplodingCnt = 0;
    ld (_shotExplodingCnt),a
;round.c:240: playerExplodingCnt = 0;
    ld (_playerExplodingCnt),a
;round.c:244: alienShotTimer = 0;
    ld (_alienShotTimer),a
;round.c:246: reloadCnt = 0;
    ld (_reloadCnt),a
;round.c:251: saucerFrames = 0;
    ld (_saucerFrames),a
;round.c:252: aliensFrames = 0;
    ld (_aliensFrames),a
;round.c:254: shotFrames = 0;
    ld (_shotFrames),a
;round.c:260: anybodyExploding = 0;
    ld (_anybodyExploding),a
;round.c:235: playerX = 14;
    ld hl, 14
    ld (_playerX),hl
;round.c:236: shotY = -1;
    ld hl, -1
    ld (_shotY),hl
;round.c:253: playerFrames = -100;
    ld a, -100
    ld (_playerFrames),a
;round.c:237: state1.shotReady = 1;
    ld hl, _state1
    ld a,(hl)
    or SHOTREADY_MASK | PLAYERISALIVE_MASK
;    set SHOTREADY_BIT, (hl)
;round.c:256: state1.playerIsAlive = 1;
;    set PLAYERISALIVE_BIT, (hl)
;round.c:257: state1.waitForEventsComplete = 0;
;    res WAITFOREVENTSCOMPLETE_BIT, (hl)
;round.c:258: state1.downFleet = 0;
;    ld  a, (hl)
;    and a,0x3f
    and ~(WAITFOREVENTSCOMPLETE_MASK|DOWNFLEET_MASK)    ; 0x1f
    ld  (hl), a

; reset alienShotInfo
    ld  hl, _alienShotInfo
    ld  a, 0x18
j1:
    ld  (hl),0
    inc hl
    dec a 
    jr nz, j1

    ret

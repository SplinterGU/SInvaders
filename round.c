#ifdef __SPECTRUM__
//#include <string.h>
#include <arch/zx.h>
#include <z80.h>
#endif

#include "common.h"
#include "utils_asm.h"
#include "utils.h"
#include "Point.h"
#include "sprites.h"
#include "tables.h"
#include "screens.h"
#include "PutSprite.h"

#include "input.h"

#ifndef __NOSOUND__
#include "sound.h"
#endif

#include "round_routines.h"

/* ********************************************* */
 
//#define bittest(  v, n )      ( v )[ ( n ) >> 3 ] &   ( 1u << ( ( n ) & 7 ) )
//#define bitset(   v, n )      ( v )[ ( n ) >> 3 ] |=  ( 1u << ( ( n ) & 7 ) )
//#define bitreset( v, n )      ( v )[ ( n ) >> 3 ] &= ~( 1u << ( ( n ) & 7 ) )

/* ********************************************* */
/* Global Vars                                   */
/* ********************************************* */

/* Player */

int16_t playerX;
uint8_t playerExplodingCnt = 0;
int8_t  playerFrames = 0; // Must be signed!!!

/* Player Shot */

int16_t shotX, shotY, shotYOld; // shotX don't need be initialized
uint8_t shotExplodingCnt = 0;
uint8_t shotFrames = 0;

/* Aliens */

uint8_t alienAnimationStatus = 0;
uint8_t alienExplodingCnt = 0;
int16_t alienExplodingX = 0, alienExplodingY = 0;
int16_t tDeltaX;
uint8_t aliensFrames = 0;

/* Alien Shot */

int8_t alienShotTimer = 0;
uint8_t alienShotFrameCnt = 0b00000001;
int8_t reloadCnt = 0;
//int8_t aShotFrame = 0;

enum {
    AS_ROL = 0,
    AS_PLU,
    AS_SQU
};

_alienShotInfo * asRol, * asPlu, * asSqu;
_alienShotInfo alienShotInfo[3];

/* Saucer */

int8_t saucerStart = 0;
int8_t saucerActive = 0;
int8_t saucerExplodingCnt = 0;
int16_t saucerX = 0;
int16_t saucerDeltaX = 0;
uint8_t saucerFrames = 0;

/* Collision */

int16_t aCol = 0, aRow = 0;

/* Demo */

int8_t demoFrame = DEMOSPEED;
uint8_t demoCurCommand = 0;

/* Others */

int8_t gameState = 0;

#ifndef __NOSOUND__
uint8_t alienSoundCnt = 0;
#endif

uint8_t anybodyExploding = 0;

struct {
    uint8_t demo:1;
    uint8_t killed:1;
    uint8_t shotReady:1;
    uint8_t currPlayer:1;

    uint8_t playerIsAlive:1;    
    uint8_t waitForEventsComplete:1;
    uint8_t downFleet:2;
} state1;


/* ********************************************* */
// playerPtr->alienIdx is the current idx

void getAliensDeltaPos( int16_t * dX, int16_t * dY, uint8_t * row ) {
    *row = getDivideBy11( playerPtr->alienIdx ); // / 11;
    *dX = ( playerPtr->alienIdx - ( *row * 11 ) ) * 16;
    *dY = -( ( 8 + FLEETDELTAY ) * *row );
}

/* ********************************************* */
// playerPtr->alienIdx is the next idx

void getAliensDeltaPos2( int8_t idx, int16_t * dX, int16_t * dY ) {
    int16_t _dx = 0, _dy = 0;
    if ( idx >= playerPtr->alienIdx ) {
        if ( state1.downFleet ) {
            _dy = FLEETDELTAY;
        } else {
            _dx = playerPtr->aliensDeltaX < 0 ? -2 : playerPtr->numAliens > 1 ? 2 : 3;
        }
    }

    int8_t r = getDivideBy11( idx ); // = idx / 11;
    *dX = ( idx - r * 11 ) * 16 - _dx;
    *dY = -( ( 8 + FLEETDELTAY ) * r + _dy );
}

/* ********************************************* */
/*
int16_t getDivideBy8( int16_t n ) {
    int8_t i = 0;
    int8_t u = 8;
    while( n - u >= 0 ) {
        u <<= 1;
        i++;
    }
    return i;
}
*/

/*
int8_t getAlienColumn( uint8_t x ) {
    int16_t delta = x - playerPtr->aliensX;

    if ( delta < 0 || delta > 175 ) return -1;
//    delta /= 16; // divide by 16
    delta = getDivideBy16( delta );
    return ( int8_t ) delta;
}
*/

/* ********************************************* */
// playerPtr->alienIdx is the next idx
/*
int16_t getAlienIdx( int16_t x, int16_t y, int8_t skipAdjust ) {
    int16_t idx = -1;

    int16_t c = x - playerPtr->aliensX;
    if ( c < 0 || c > 175 ) return -1;
    //c /= 16; // divide by 16
    c = getDivideBy16( c );

    int16_t r = playerPtr->aliensY - y;
    if ( r < 0 || r > ( 4 * ( 8 + FLEETDELTAY ) + 7 ) ) return -1;
//    r /= 8 + FLEETDELTAY;
    r = getDivideBy12( r );

    idx = r * 11 + c;

    if ( !skipAdjust && idx >= playerPtr->alienIdx ) {
        int16_t _dx = 0, _dy = 0;
        if ( state1.downFleet ) {
            _dy = FLEETDELTAY;
        } else {
            _dx = playerPtr->aliensDeltaX < 0 ? -2 : playerPtr->numAliens > 1 ? 2 : 3;
        }
        return getAlienIdx( x + _dx, y + _dy, 1 );
    }

    aCol = c;
    aRow = r;

    return idx;
}
*/
/* ********************************************* */

int8_t getLowestAlien( int8_t col ) {
    if ( col < 0 || col > 10 ) return -1;

    int8_t i;
    for ( i = 0; i < 55; i+=11 ) {
        if ( playerPtr->aliens[ col + i ] ) return col + i;
    }
    return -1;
}

/* ********************************************* */

int16_t getReloadRate() {
    int8_t n;
    if ( !playerPtr->score ) return ShotReloadRate[ 0 ];
    for ( n = 0; n < sizeof( AReloadScoreTab ) / sizeof ( AReloadScoreTab[ 0 ] ) && playerPtr->score > AReloadScoreTab[ n ]; n++ );
    return ShotReloadRate[ n - 1 ];
}

/* ********************************************* */

#if 0
void resetRoundVars() {

    /* Aliens */

    alienAnimationStatus = 0;

    alienExplodingCnt = 0;

    /* Saucer */

    saucerStart = 0;
    saucerActive = 0;

    saucerExplodingCnt = 0;

    /* Player */

    playerX = 14;
    shotY = -1;
    state1.shotReady = 1;
    shotExplodingCnt = 0;

    playerExplodingCnt = 0;

    /* Alien Shot */

    alienShotTimer = 0;

    reloadCnt = 0;
//    aShotFrame = 0;

    /* General for round */

    saucerFrames = 0;
    aliensFrames = 0;
    playerFrames = -100;
    shotFrames = 0;

    state1.playerIsAlive = 1;
    state1.waitForEventsComplete = 0;
    state1.downFleet = 0;

    anybodyExploding = 0;

    __asm
        push bc
        push hl
        ; code size
        ld hl, _alienShotInfo 
        ld b, 0x18 
        xor a 
    j1:
        ld (hl),a 
        inc hl 
        djnz j1
        pop hl
        pop bc
    __endasm;

/*
    int8_t i;
    for ( i = 0; i < 3; i++ ) {
        alienShotInfo[ i ].active = 0;
        alienShotInfo[ i ].aniFrame = 0;
        alienShotInfo[ i ].explodingCnt = 0;
    }
*/

}
#endif

#if 0

/* ********************************************* */

void resetPlayer1( int8_t p, int8_t isFirst ) {
    int8_t n;

    playerPtr = &player[ p ];

    if ( isFirst ) {
        playerPtr->score = 0;

        /* Alien Shot */

        playerPtr->pluShotColIdx = 0;
        playerPtr->squShotColIdx = 6;

        playerPtr->numShips = numLives;
        playerPtr->round = 0;

        playerPtr->reloadRate = state1.demo ? 8 : getReloadRate();

    } else {
        playerPtr->round++;
    }

    /* Aliens */

    playerPtr->numAliens = 55;

    playerPtr->leftLimitCol = 0;
    playerPtr->rightLimitCol = 10;

    playerPtr->leftLimit = 0;
    playerPtr->rightLimit = 256 - ( ( playerPtr->rightLimitCol * 16 ) + 16 ) - 1;

    playerPtr->aliensColMask = 0b11111111111;

    for ( n = 0; n < playerPtr->numAliens; n++ ) playerPtr->aliens[ n ] = 1;

    playerPtr->fleetTopBase = ( playerPtr->round == 0 ? FLEETPOSSTART : AlienStartTable[ ( playerPtr->round - 1 ) & 7 ] );

    playerPtr->aliensX = 40;
    playerPtr->aliensY = playerPtr->fleetTopBase;
    playerPtr->aliensDeltaX = 2;
    
    playerPtr->alienIdx = 0;

    /* Saucer */

    playerPtr->tillSaucer = SAUCERTIMER; // Original Arcade 0x0600
    playerPtr->sauScore = 0;

    /* Alien Shot */

    playerPtr->alienShotMask = 0b00101101;

    /* Player */

    playerPtr->shotsCounter = 0;

    /* Shield */

    playerPtr->currentShieldTopY = SHIELDTOPY;

    playerPtr->shieldBackupSaved = 0;

    asRol = &alienShotInfo[ AS_ROL ];
    asPlu = &alienShotInfo[ AS_PLU ];
    asSqu = &alienShotInfo[ AS_SQU ];

    for ( n = 0; n < 3; n++ ) {
        alienShotInfo[ n ].active = 0;
        alienShotInfo[ n ].aniFrame = 0;
        alienShotInfo[ n ].explodingCnt = 0;
    }

#ifndef __NOSOUND__
    if ( !state1.demo ) SoundStopAll();
#endif

}

#endif

/* ********************************************* */
#if 0
void StoreShields() {
    uint8_t i;
    uint16_t ii;
    for ( i = playerPtr->currentShieldTopY, ii = 0; i < SHIELDTOPY + 24u; i++, ii+=32 )
        copymem( playerPtr->shieldBackup + ii, GetScreenAddr( 0, i ), 32 );
    playerPtr->shieldBackupSaved = 1;
}

/* ********************************************* */

void RestoreShields() {
    uint8_t i;
    uint16_t ii;
    for ( i = playerPtr->currentShieldTopY, ii = 0; i < SHIELDTOPY + 24u; i++, ii+=32 )
        copymem( GetScreenAddr( 0, i ), playerPtr->shieldBackup + ii, 32 );
    playerPtr->shieldBackupSaved = 0;
}

#endif

/* ********************************************* */

void DrawShields() {
    if ( playerPtr->shieldBackupSaved ) {
//        RestoreShields();
        StoreShields( 1 );  // 1 - Restore
    } else {
        uint8_t n;
        for ( n = 0; n < 4; n++ ) {
            PutSprite3( ( uint8_t ) ( 32u + 56u * n ), ( ( uint8_t ) SHIELDTOPY )     , ShieldImage       );
            PutSprite3( ( uint8_t ) ( 32u + 56u * n ), ( ( uint8_t ) SHIELDTOPY ) + 8u, ShieldImage + 24u );
        }
    }
}

/* ********************************************* */

void DrawShips() {
    int8_t n;
    uint8_t c = 24;
    PrintNumAt( 8, 184, playerPtr->numShips, 1 | NUM_LEFTZERO );
    int8_t l = ( ( playerPtr->numShips > 6 ) ? 6 : playerPtr->numShips ) - 1;
    for ( n = 0; n < l; n++, c+=16 ) {
        PutSprite2( c, 184, PlayerSprite );
    }
    PutSprite2( c, 184, DeleteSprite16 );
}

/* ********************************************* */

void scoreUpdate( int16_t points ) {
    // Extra Life
    if ( playerPtr->score < bonusLife && ( playerPtr->score + points ) >= bonusLife ) {
#ifndef __NOSOUND__
        SoundPlay( SOUND_EXTRA_LIFE );
#endif
        playerPtr->numShips++;
        DrawShips();
    }

    playerPtr->score += points;
    PrintNumAt( !state1.currPlayer ? 16 : 208, 8, playerPtr->score, 4 | NUM_LEFTZERO );

    playerPtr->reloadRate = getReloadRate();

}

/* ********************************************* */

void hiScoreUpdate( int16_t score ) {
    if ( score > hiScore ) {
        hiScore = score;
        PrintNumAt( 104, 8, hiScore, 4 | NUM_LEFTZERO | NUM_UNSIGNED );
    }
}

/* ********************************************* */

void createAlienShotCol( _alienShotInfo * asi, int8_t * colIdx, int8_t colMin, int8_t colMax ) {
    if ( !asi->active && !asi->explodingCnt && !shotExplodingCnt ) {
        uint8_t col = ColFireTable[ *colIdx ];

        int8_t aidx = getLowestAlien( col );
        if ( aidx != -1 ) {
            getAliensDeltaPos2( aidx, &asi->x, &asi->y );
            asi->x += playerPtr->aliensX + 8 - 1;
            asi->y += playerPtr->aliensY + 16;
            asi->active = 1;
            asi->aniFrame = 0;
            reloadCnt = 0;
        }
        ( *colIdx )++;
        if ( *colIdx > colMax ) *colIdx = colMin;
    }
}

/* ********************************************* */
/*
void handleAlienShot( _alienShotInfo * asi, uint8_t * _sprite ) {
    int8_t hit = 0;

    PutSprite1Delete( asi->x, asi->y, _sprite + asi->aniFrame ); // Delete

    asi->y += 2;
    asi->aniFrame += 8;

    if ( asi->aniFrame >= 32 ) asi->aniFrame = 0;

    if ( asi->y < PLAYERY + 8 ) {
        if ( asi->y + 8 > PLAYERY && asi->x < playerX + 14 && asi->x + 2 > playerX + 2 ) {
            asi->active = 0;
            if ( state1.playerIsAlive ) {
                playerExplodingCnt = 60; // 0x100;
                state1.waitForEventsComplete = 1;
                state1.playerIsAlive = 0;
#ifndef __NOSOUND__
                if ( !state1.demo ) SoundPlay( SOUND_PLAYER_EXPLOSION );
#endif
            }
        } else {
            // Shield Collision?
            if ( asi->y + 8 > playerPtr->currentShieldTopY - 4 && asi->y + 8 < SHIELDTOPY + 24 ) {
                if ( Point( asi->x, asi->y + 6 ) || Point( asi->x + 1, asi->y + 6 ) || Point( asi->x + 2, asi->y + 6 ) ) {
                    asi->y += 2;
                    PutSprite1Merge( asi->x - 2, asi->y, AShotExplo );
                    asi->active = 0;
                    asi->explodingCnt = 8; // 60;
                    hit = 1;
                }
            }

            if ( !hit ) PutSprite1Merge( asi->x, asi->y, _sprite + asi->aniFrame );
        }
    } else {
        asi->y = PLAYERY + 8;
        PutSprite1Merge( asi->x - 2, asi->y, AShotExplo );
        asi->active = 0;
        asi->explodingCnt = 8; //60;
    }
}
*/
/* ********************************************* */

void deleteOldPlayerShot() {
    if ( shotYOld < PLAYERY ) PutSprite1Delete( shotX, shotYOld /*+ 2*/, PlayerShotSpr ); // Delete
}

/* ********************************************* */

void drawShotExploding( uint8_t y ) {
    PutSprite1Merge( shotX - 4, y, ShotExploding );
}

/* ********************************************* */
/*
void handleAShotCollision( _alienShotInfo * asi, int8_t aShotYH, uint8_t * spr ) {
    if ( ( uint16_t ) ( shotX - asi->x ) < 3 && shotY + 4 < asi->y + aShotYH && shotY + 8 > asi->y ) {
        PutSprite1Delete( asi->x, asi->y, spr + asi->aniFrame ); // Delete
        deleteOldPlayerShot();
        drawShotExploding( shotY + 2 );
        shotY = -shotY;
        asi->active = 0;
        shotExplodingCnt = 8; //60;
        state1.killed = 1;
    }
}
*/
/* ********************************************* */

void handleDeleteAShotExplodingCnt( _alienShotInfo * asi ) {
    if ( asi->explodingCnt ) {
        asi->explodingCnt--;
        if ( !asi->explodingCnt ) {
            PutSprite1Delete( asi->x - 2, asi->y, AShotExplo ); // Delete
        }
    }
}

/* ********************************************* */

void handleSauScore() {
    playerPtr->shotsCounter++;
    playerPtr->sauScore++;
    if ( playerPtr->sauScore == sizeof( SaucerScrTab ) / sizeof( SaucerScrTab[ 0 ] ) ) {
        playerPtr->sauScore = 0;
    }
}

/* ********************************************* */

int8_t iterGame() {
    int8_t n;

    anybodyExploding = 0;

    if ( state1.demo ) {
#ifdef __ZX81__
        readSysKeys();
#endif
        if ( syskey.keyPressed ) return 2; // Key pressed on demo mode
        if ( playerFrames >= 0 ) {
            demoFrame++;
            if ( demoFrame >= DEMOSPEED ) {
                uint8_t key;
                demoFrame = 0;
                key = DemoCommands[ demoCurCommand ];
                input.moveLeft  = ( key & 2 ) >> 1;
                input.moveRight =   key & 1;
                input.shot = 1;
                state1.shotReady = 1;
                demoCurCommand++;
                if ( demoCurCommand > sizeof( DemoCommands ) / sizeof( DemoCommands[ 0 ] ) ) {
                    demoCurCommand = 0;
                }
            }
        }
    }

    if ( playerPtr->aliensY != playerPtr->fleetTopBase ) {
        playerPtr->tillSaucer--;
        if ( playerPtr->tillSaucer <= 0 ) {
            saucerStart = 1;
            playerPtr->tillSaucer = SAUCERTIMER; // Original Arcade 0x0600
        }
    }

    // Clear Alien Explosion
    if ( alienExplodingCnt ) {
        alienExplodingCnt--;
        if ( !alienExplodingCnt ) {
            PutSprite2( alienExplodingX, alienExplodingY, DeleteSprite16 );
            if ( !playerPtr->numAliens ) {
                resetPlayer( state1.currPlayer, 0 );
                return 3; // Next round
            }                
            handleSauScore();
        } else {
            anybodyExploding = 1;            
        }
    }

    // Clear Shot Explosion
    if ( shotExplodingCnt ) {
        shotExplodingCnt--;
        if ( !shotExplodingCnt ) {
            PutSprite1Delete( shotX - 4, -shotY /*+ 2*/, ShotExploding );
            if ( saucerActive == 1 && shotY == -16 ) PutSprite3( saucerX, 16, SpriteSaucer );
            handleSauScore();
            shotY = -1;
        } else {
            anybodyExploding = 1;
        }
    }

    // Saucer Explosion
    if ( saucerActive < 0 ) {
        saucerExplodingCnt--;
        if ( saucerExplodingCnt == 24 ) {
            anybodyExploding = 1;
            handleSauScore();
            if ( !state1.demo ) scoreUpdate( SaucerScrTab[ playerPtr->sauScore ] );
            PrintNumAt( saucerX, 16, SaucerScrTab[ playerPtr->sauScore ], 3 );
        } else if ( !saucerExplodingCnt ) {
            // ClearRows( 16, 8 );
            PutChars( saucerX, 16, ' ', 3, 0 );
            saucerActive = 0;
        }
    }

    handleDeleteAShotExplodingCnt( asRol );
    handleDeleteAShotExplodingCnt( asPlu );
    handleDeleteAShotExplodingCnt( asSqu );

    if ( !state1.playerIsAlive ) {
        int16_t i;
#ifdef __SPECTRUM__
#define NOTALIVE_PAUSE 1000
#endif
#ifdef __ZX81__
#define NOTALIVE_PAUSE 600
#endif
        for ( i = 0; i < NOTALIVE_PAUSE; i++ ) {
            __asm
                nop
            __endasm;
        }
    }

    if ( state1.playerIsAlive && playerPtr->numAliens ) {
        handleNextAlien();
#if 0
        aliensFrames++;
        if ( aliensFrames >= ALIENSPEED ) {
            aliensFrames = 0;
            for ( ; playerPtr->alienIdx < 55 && !playerPtr->aliens[ playerPtr->alienIdx ]; playerPtr->alienIdx++ );

            if ( playerPtr->alienIdx == 55 ) {
                for ( playerPtr->alienIdx = 0; playerPtr->alienIdx < 55 && !playerPtr->aliens[ playerPtr->alienIdx ]; playerPtr->alienIdx++ );
#ifndef __NOSOUND__
                // Alien Sound
                if ( !state1.demo ) SoundPlay( SOUND_ALIEN_STEP1 + ( ( alienSoundCnt++ ) & 0x03 ) );
#endif
                alienAnimationStatus ^= 1;            

                // Right to Left allways -2
                tDeltaX = playerPtr->aliensDeltaX < 0 ? -2 : playerPtr->numAliens > 1 ? 2 : 3;
                playerPtr->aliensX += tDeltaX;

                state1.downFleet = 0;

                if ( playerPtr->aliensX < playerPtr->leftLimit || playerPtr->aliensX > playerPtr->rightLimit ) {
                    state1.downFleet = 0x02;

                    playerPtr->aliensX -= tDeltaX;
                    playerPtr->aliensDeltaX = -playerPtr->aliensDeltaX;

                    playerPtr->aliensY += FLEETDELTAY;
                }
            }

            int16_t dX, dY;
            uint8_t row;
            getAliensDeltaPos( &dX, &dY, &row );
            uint8_t posX = playerPtr->aliensX + dX,
                    posY = playerPtr->aliensY + dY;
            if ( state1.downFleet ) {
    #if FLEETDELTAY == 4
                PutSprite1Delete(    posX    , posY - FLEETDELTAY, DeleteTopAlien );
                PutSprite1Delete(    posX + 8, posY - FLEETDELTAY, DeleteTopAlien );
    #else
                PutSprite2(   posX    , posY - FLEETDELTAY, DeleteSprite16 );
    #endif
                if ( ( state1.downFleet & 0x02 ) && posY + 8 > playerPtr->currentShieldTopY ) {
                    ClearRows( posY + 8 - FLEETDELTAY, FLEETDELTAY );
                    playerPtr->currentShieldTopY = posY + 8;
                    state1.downFleet = 0x01;
                }

                // Aliens reached the Player
    #if FLEETDELTAY == 4
                if ( posY + FLEETDELTAY >= PLAYERY ) 
    #else
                if ( posY >= PLAYERY ) 
    #endif
                {
                    playerExplodingCnt = 60; //0x100;
                    state1.waitForEventsComplete = 1;
                    state1.playerIsAlive = 0;
    #ifndef __NOSOUND__
                    if ( !state1.demo ) SoundPlay( SOUND_PLAYER_EXPLOSION );
    #endif
                    if ( playerPtr->numShips ) playerPtr->numShips = 1;
                }
            }

            PutSprite2( posX, posY, AlienSprites[ row ] + ( alienAnimationStatus * 16 ) );
            playerPtr->alienIdx++;
        }
#endif
        /* Player */

        playerFrames++;
        if ( playerFrames >= PLAYERSPEED ) {
            playerFrames = 0;

            if ( !state1.demo ) readInput();

            if ( input.moveLeft  && playerX > 0   ) playerX--;
            if ( input.moveRight && playerX < 240 ) playerX++;

            // Don't need delete old sprite
            PutSprite2( playerX, PLAYERY, PlayerSprite );
        }

        if ( saucerStart && !asSqu->active && playerPtr->numAliens >= 8 ) {
            saucerActive = 1;
            if ( playerPtr->shotsCounter & 1 ) {
                saucerDeltaX = 2;
                saucerX = 0;
            } else {
                saucerDeltaX = -2;
                saucerX = 232;
            }
            saucerFrames = SAUCERSPEED;
            saucerStart = 0;
        }
    }

    if ( playerExplodingCnt ) {
        playerExplodingCnt--;
        if ( playerExplodingCnt ) {
            anybodyExploding = 1;
            if ( !( playerExplodingCnt & 0x03 ) ) {
                PutSprite2( playerX, PLAYERY, ( void * ) ( PlrBlowupSprites + ( ( playerExplodingCnt & 0x04 ) * 4 ) ) );
            }
        } else {
            PutSprite2( playerX, PLAYERY, DeleteSprite16 );
            playerPtr->numShips--;
            DrawShips();
        }
    }

    if ( state1.waitForEventsComplete                                           &&
         !anybodyExploding                                                      &&
         !( asRol->explodingCnt | asPlu->explodingCnt | asSqu->explodingCnt )   &&
         !( asRol->active | asPlu->active | asSqu->active | saucerActive )      &&
/*#ifdef __SPECTRUM__
#ifndef __NOSOUND__
         !playingSound                                                          &&
#endif
#endif*/
         shotY == -1 
    ) {
#ifndef __NOSOUND__
        if ( !state1.demo ) SoundStopAll();
#endif
        if ( state1.demo ) return 0; // demo complete

        if ( !playerPtr->numShips ) return 4; // game over

        return 6; // player death, but have ships availables
    }

    if ( saucerActive == 1 ) {
#ifndef __NOSOUND__
        if ( !state1.demo ) SoundPlay( SOUND_UFO );
#endif
        saucerFrames++;
        if ( saucerFrames >= SAUCERSPEED ) {
            saucerFrames = 0;
            saucerX += saucerDeltaX;
            if ( saucerX < 0 || saucerX > 232 ) {
                PutChars( saucerX - saucerDeltaX, 16, ' ', 3, 0 );
                saucerActive = 0;
            } else {
                PutSprite3( saucerX, 16, SpriteSaucer );
            }
        }
    }

    shotFrames++;
    if ( playerFrames >= 0 /*shotFrames >= SHOTSPEED */ ) {
        shotFrames = 0;

        if ( !state1.demo ) {
            readInput();
            if ( !input.shot ) state1.shotReady = 1;
        }

        if ( input.shot && state1.shotReady && shotY == -1 && state1.playerIsAlive && !anybodyExploding ) {
#ifndef __NOSOUND__
            if ( !state1.demo ) SoundPlay( SOUND_PLAYER_SHOT );
#endif
            shotY = PLAYERY - 8;
            shotX = playerX + 8;
            state1.shotReady = 0;
        }

        if ( shotY > 0 ) {
            shotYOld = shotY;
            shotY -= 4;

            state1.killed = 0;

            int8_t collision = 0;

            // Shot collision with aliens shots

            handleAShotCollision( asRol, 7, RollShot    );
            handleAShotCollision( asPlu, 6, PlungerShot );
            handleAShotCollision( asSqu, 7, SquiglyShot );

            // Shot collision with saucer
            if ( !state1.killed && saucerActive > 0 && 
                  shotY + 4 >= SAUCERROW && shotY + 7 < SAUCERROW + 8 &&
                  shotX >= saucerX + 4 && shotX < saucerX + 20
               ) {
                deleteOldPlayerShot();
                PutSprite3( saucerX, 16, SpriteSaucerExp );
                saucerActive = -1;
                saucerExplodingCnt = 32;

#ifndef __NOSOUND__
                if ( !state1.demo ) SoundPlay( SOUND_UFO_EXPLOSION );
#endif
                shotY = -1;
                state1.killed = 1;
            }

            // Shot collision with shield
            if ( !state1.killed && shotY + 8 > playerPtr->currentShieldTopY && shotY + 4 < SHIELDTOPY + 16 ) {
                if ( Point( shotX, shotY + 4 ) || Point( shotX, shotY + 5 ) ||
                     Point( shotX, shotY + 6 ) || Point( shotX, shotY + 7 ) ) {
                    deleteOldPlayerShot();
                    shotY = -( shotY + 2 );
                    drawShotExploding( -shotY );
                    shotExplodingCnt = 6; //60;
                    state1.killed = 1;
                }
            }

            // Shot collision with aliens
            if ( !state1.killed ) {
                int16_t idx = getAlienIdx( shotX, shotY /*+ 4 - 6*/, 0 ), lowest;

                if ( idx >= 0 && idx < 55 && playerPtr->aliens[ idx ] ) {

// Alien A = 12px width (2 + 12 + 2)
// Alien B = 11px width (3 left + 11 alien + 2 right)
// Alien C = 8px width  (4 + 8 + 4)
                    getAliensDeltaPos2( idx, &alienExplodingX, &alienExplodingY );
                    alienExplodingX += playerPtr->aliensX;
                    alienExplodingY += playerPtr->aliensY;

                    int hit = 0;

                    switch ( aRow ) {
                        case 0:
                        case 1:
                            if ( shotX >= alienExplodingX + 2 && shotX < alienExplodingX + 14 ) hit = 1;
                            break;

                        case 2:
                        case 3:
                            if ( shotX >= alienExplodingX + 3 && shotX < alienExplodingX + 14 ) hit = 1;
                            break;

                        case 4:
                            if ( shotX >= alienExplodingX + 4 && shotX < alienExplodingX + 12 ) hit = 1;
                            break;

                    }

                    if ( hit ) {
                        deleteOldPlayerShot();
                        PutSprite2( alienExplodingX, alienExplodingY, AlienExplode );

                        playerPtr->aliens[ idx ] = 0;
                        playerPtr->numAliens--;
                        alienExplodingCnt = 8;
                        shotY = -1;
                        state1.killed = 1;

                        if ( !state1.demo ) {
                            scoreUpdate( AlienScores[ aRow ] );
#ifndef __NOSOUND__
                            SoundPlay( SOUND_ALIEN_EXPLOSION );
#endif
                        }
                        if ( playerPtr->numAliens < 9 ) playerPtr->alienShotMask = 0b111111;

                        if ( ( lowest = getLowestAlien( aCol ) ) == -1 ) playerPtr->aliensColMask &= ~( 0x0001u << aCol );

                        if ( lowest && ( aCol == playerPtr->leftLimitCol || aCol == playerPtr->rightLimitCol ) ) {
                            if ( getLowestAlien( aCol ) == -1 ) {
                                int16_t ll = 10, lr = 0;
                                uint16_t bitl = 0x0400u, bitr = 0x0001u;

                                playerPtr->aliensColMask &= ~( 0x0001u << aCol );

                                for ( n = 0; n < 11; n++, bitl >>= 1, bitr <<= 1 ) {
                                    if ( playerPtr->aliensColMask & bitl ) ll = ( 10 - n );
                                    if ( playerPtr->aliensColMask & bitr ) lr = n;
                                }

                                playerPtr->leftLimitCol = ll;
                                playerPtr->rightLimitCol = lr;

                                playerPtr->leftLimit  = -( ll * 16 );
                                playerPtr->rightLimit = 256 - ( ( lr * 16 ) + 16 ) - 1;
                            }
                        }
                    }
                }
            }

            if ( !state1.killed ) {
                deleteOldPlayerShot();
                if ( shotY <= 16 ) {
                    drawShotExploding( 16 );
                    shotY = -( 16 /*- 2*/ );
                    shotExplodingCnt = 4; //40;
                    state1.killed = 1;
                } else {
                    PutSprite1Merge( shotX, shotY /*+ 2*/, PlayerShotSpr );
                }
            }
        }
    }

    /* Aliens Shots */

//    aShotFrame++;
//    if ( aShotFrame >= ALIENSHOTSPEED ) {
//        aShotFrame = 0;
    reloadCnt++;
    if ( state1.playerIsAlive && playerFrames >= 0 ) {
        if ( reloadCnt >= playerPtr->reloadRate ) {
            reloadCnt = 0;
            switch ( alienShotTimer ) {
                case    0:  // rolling-shot
                    if ( !asRol->active && !asRol->explodingCnt && !shotExplodingCnt ) {
                        // Track the player
                        int8_t aidx = getLowestAlien( getAlienColumn( playerX + 8 ) );

                        if ( aidx != -1 ) {
                            getAliensDeltaPos2( aidx, &asRol->x, &asRol->y );
                            asRol->x += playerPtr->aliensX + 8 - 1;
                            asRol->y += playerPtr->aliensY + 16;
                            asRol->active = 1;
                            asRol->aniFrame = 0;
                        }
                    }
                    alienShotTimer++;
                    break;

                case    1:  // plunger-shot
                    if ( playerPtr->numAliens > 1 ) createAlienShotCol( asPlu, &playerPtr->pluShotColIdx, 0, 15 );
                    alienShotTimer++;
                    break;

                case    2:  // squiggly-shot or saucer
                    if ( !saucerActive ) createAlienShotCol( asSqu, &playerPtr->squShotColIdx, 6, 20 );
                    alienShotTimer = 0;
                    break;

            }
        }
    }
    
    if ( alienShotFrameCnt & playerPtr->alienShotMask ) {
        /* if ( asRol->active ) */ handleAlienShot( asRol,    RollShot );
        /* if ( asPlu->active ) */ handleAlienShot( asPlu, PlungerShot );
        /* if ( asSqu->active ) */ handleAlienShot( asSqu, SquiglyShot );
    }
    if ( alienShotFrameCnt == 0b00100000 ) alienShotFrameCnt = 0b00000001;
    else                                   alienShotFrameCnt <<= 1;
//    }

    return 1; // frame complete, return for continue

}

/* ********************************************* */
#if 0
int8_t playGame( int8_t _demo ) {

    int8_t ret = 0, n;

    state1.demo = _demo;

    /* Reset Players */

    resetPlayer( 1, 1 );
    resetPlayer( 0, 1 );

    /* Round */

    state1.currPlayer = 0;

    if ( state1.demo ) playersInGame = 1;

start_round:
    gameState = 0;

    ClearRows( 16, 168 );

    DrawShips();
    
    if ( !state1.demo ) {
        DrawScoreHeaderAndCredits();
        PrintAt(  81,  78, "PLAY PLAYER< >" );
        PrintChar( 177,  78, ( !state1.currPlayer ? '1' : '2' ), 0 );

        for ( n = 0; n < 17; n++ ) {
            PrintAt( !state1.currPlayer ? 16 : 208, 8, "      " );
            DelayFrames(3);

            PrintNumAt( !state1.currPlayer ? 16 : 208, 8, playerPtr->score, 4 | NUM_LEFTZERO );
            DelayFrames(3);

        }
        ClearRows( 16, 168 );
    }
    
    DrawShields();

    PrintAt( 0, ( uint8_t ) ( PLAYERY + 8 ), "################################" );

    resetRoundVars();

    gameState = 1;

    // Main Loop
    while ( 1 ) {
#ifndef __NOSOUND__
        SoundExecute();
#endif
#ifdef __ZX81__
        gameState = iterGame();
#endif

        switch ( gameState ) {
            case    0: // demo complete
                DelayFrames( 100 ); // 2 seconds
                return 0;

            case    1: // continue game
                break;

            case    2: // key pressed on demo mode
                return 2;

            case    3: // next round
                DelayFrames( 100 ); // 2 seconds
                goto start_round;

            case    4: // game over
                goto game_over;

            case    6: // player death a life
                    DelayFrames( 100 ); // 2 seconds
                    reloadCnt = 0;
                    if ( playersInGame > 1 ) {
                        if ( player[ state1.currPlayer ^ 1 ].numShips > 0 ) {
                            StoreShields();
                            state1.currPlayer ^= 1;
                            playerPtr = &player[ state1.currPlayer ];
                            goto start_round;
                        }
                    }
                    state1.waitForEventsComplete = 0;
                    state1.playerIsAlive = 1;
                    playerX = 14;
                    gameState = 1; // continue
                    break;

        }
    }

game_over:
    hiScoreUpdate( playerPtr->score );
    if ( playersInGame == 1 ) {
        PrintAtDelay( 88, 26, "GAME OVER", 6 );
        DelayFrames( 100 ); // 2 seconds
        return 1;

    } else if ( playersInGame == 2 ) {
        PrintAtDelay( 48, ( uint8_t ) ( PLAYERY + 4 ), "GAME OVER  PLAYER< >", 6 );
        PrintChar( 192, ( uint8_t ) ( PLAYERY + 4 ), ( !state1.currPlayer ? '1' : '2' ), 0 );
        DelayFrames( 100 ); // 2 seconds

        state1.currPlayer ^= 1;
        playerPtr = &player[ state1.currPlayer ];

        if ( !playerPtr->numShips ) return 1;

        goto start_round;
    }

    gameState = 0;

    return 1;

}
#endif

/* ********************************************* */

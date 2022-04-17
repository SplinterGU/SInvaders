#include <stdint.h>
//#include <stdio.h>
//#include <stdlib.h>

#ifdef __SPECTRUM__
#include <arch/zx.h>
#include <z80.h>
#endif

#ifdef __ZX81__
//////////////////////////
// CHROMA-81 ONLY
//////////////////////////

#define INK_BLACK      0x00
#define INK_BLUE       0x01
#define INK_RED        0x02
#define INK_MAGENTA    0x03
#define INK_GREEN      0x04
#define INK_CYAN       0x05
#define INK_YELLOW     0x06
#define INK_WHITE      0x07

#define PAPER_BLACK    0x00
#define PAPER_BLUE     0x10
#define PAPER_RED      0x20
#define PAPER_MAGENTA  0x30
#define PAPER_GREEN    0x40
#define PAPER_CYAN     0x50
#define PAPER_YELLOW   0x60
#define PAPER_WHITE    0x70

#define BRIGHT         0x08
#define PAPER_BRIGHT   0x80
#define INK_BRIGHT     0x08

#endif

#pragma preproc_asm +

#include "common.h"

#include "input.h"

#include "utils_asm.h"
#include "utils.h"
#include "sprites.h"
#include "PutSprite.h"

#include "screens.h"

#ifndef __NOSOUND__
#include "sound.h"
#endif

typedef struct {
    uint8_t x, y;
    char * text;
} scrtextA;

/* ********************************************* */

#ifdef __SPECTRUM__
#ifdef __ZXN__
    #define HELP_TXT_Y      24
    #define HELP_BASE_Y     40
#else
    #define HELP_TXT_Y      32
    #define HELP_BASE_Y     56
#endif
#endif
#ifdef __ZX81__
    #define HELP_TXT_Y      32
    #define HELP_BASE_Y     56
#endif

scrtextA helpScreenTxt[] = {
    { 96,  HELP_TXT_Y          ,          "* HELP *"                },
    { 40,  HELP_BASE_Y         ,    "PUSH +/K FOR CREDITS"          },
    { 80,  HELP_BASE_Y + 16    ,         "1   FOR 1 PLAYER"         },
    { 80,  HELP_BASE_Y + 16 * 2,         "2   FOR 2 PLAYERS"        },
    { 80,  HELP_BASE_Y + 16 * 3,         "C   FOR CONFIGURE"        },
#ifdef __SPECTRUM__
    { 40,  HELP_BASE_Y + 16 * 4,    "O/P/CS   FOR KEYBOARD"         },
#ifdef __ZXN__
    { 80,  HELP_BASE_Y + 16 * 5,         "I   SHOW INTRO SCREEN"    },
    { 80,  HELP_BASE_Y + 16 * 6,         "H   FOR THIS HELP"        },
    { 32,                160   ,   "ZX SPECTRUM NEXT VERSION BY"    },
#else
    { 80,  HELP_BASE_Y + 16 * 5,         "H   FOR THIS HELP"        },
    { 40,                160   ,    "ZX SPECTRUM VERSION BY"        },
#endif
#endif
#ifdef __ZX81__
    { 16,  HELP_BASE_Y + 16 * 4, "O/P/SHIFT   FOR KEYBOARD"         },
    { 80,  HELP_BASE_Y + 16 * 5,         "H   FOR THIS HELP"        },
    { 64,                160   ,        "ZX81 VERSION BY"           },
#endif
    { 32,                168   ,   "JUAN JOSE PONTEPRINO V1.6.2"    }
};

scrtextA scoreScreenTxt[] = {
    {  96,  112, "=? MYSTERY"                      },
    {  96,  128, "=30 POINTS"                      },
    {  96,  144, "=20 POINTS"                      },
    {  96,  160, "=10 POINTS"                      }
};

scrtextA insertCoinScreenTxt[] = {
    {  72, 124, "*1 PLAYER  1 COIN"                },
    {  72, 144, "*2 PLAYERS 2 COINS"               }
};

/* ********************************************* */

int8_t currentMenuScreen = 0;

/* ********************************************* */

void PrintAtArr( scrtextA * st, int8_t n ) {
    while ( n-- ) {
        PrintAt( st->x, st->y, st->text );
        st++;
    }
}

/* ********************************************* */

int PrintAtDelayArr( scrtextA * st, int8_t n, uint8_t delay ) {
    int ret = 0;
    while ( n-- && !ret ) {
        ret = PrintAtDelay( st->x, st->y, st->text, delay );
        st++;
    }
    return ret;
}

/* ********************************************* */

void DrawScreenColors() {
    int16_t n;
    uint8_t * ScreenAttrAddr = NULL;
    ScreenAttrAddr = ( uint8_t * )
#ifdef __SPECTRUM__
    0x5800;
    #define COLSBYROW 32
#endif
#ifdef __ZX81__
    GetAttrAddr();
    #define COLSBYROW 35
    if ( ScreenAttrAddr ) {
#endif
        for ( n = 0; n < 24 * COLSBYROW; n++ ) {
            ScreenAttrAddr[ n ] = PAPER_BLACK | INK_WHITE | ( brightActive ? BRIGHT : 0 );
        }
        for ( n = 2 * COLSBYROW; n < 4 * COLSBYROW; n++ ) {
            ScreenAttrAddr[ n ] = PAPER_BLACK | INK_RED | ( brightActive ? BRIGHT : 0 );
        }
        for ( n = 18 * COLSBYROW; n < 23 * COLSBYROW; n++ ) {
            ScreenAttrAddr[ n ] = PAPER_BLACK | INK_GREEN | ( brightActive ? BRIGHT : 0 );
        }
        for ( n = 23 * COLSBYROW + 3; n < 23 * COLSBYROW + 23; n++ ) {
            ScreenAttrAddr[ n ] = PAPER_BLACK | INK_GREEN | ( brightActive ? BRIGHT : 0 );
        }
#ifdef __ZX81__
    }
#endif
}

/* ********************************************* */

void DrawCredits() {
    PrintAt(     184, 184, "CREDIT " );
    PrintNumAt(  240, 184, numCredits, 2 | NUM_LEFTZERO );
}

/* ********************************************* */

void DrawScoreHeaderAndCredits() {
    PrintAt(        0,   0, "SCORE<1>    HI-SCORE    SCORE<2>" );

    PrintNumAt(       16,   8, player[ 0 ].score, 4 | NUM_LEFTZERO | NUM_UNSIGNED );
    PrintNumAt(      104,   8, hiScore          , 4 | NUM_LEFTZERO | NUM_UNSIGNED );

    if ( playersInGame != 1 ) {
        PrintNumAt(      208,   8, player[ 1 ].score, 4 | NUM_LEFTZERO | NUM_UNSIGNED );
    } else {
        PrintAt(         208,   8, "    " );
    }

    DrawCredits();
}

/* ********************************************* */

static int8_t animateSpriteX( int y, int from_x, int to_x, int8_t deltax, uint8_t * sprite1, uint8_t * sprite2 ) {
    int px, opx = -1;
    uint8_t anim = 0;

    for ( px = from_x; ( deltax < 0 ) ? px >= to_x : px <= to_x; opx = px, px += deltax ) {
        if ( opx != -1 )    PutSprite2( opx, y, DeleteSprite16 );
                            PutSprite2(  px, y, anim ? sprite2 : sprite1 );
        anim ^= 1;
        if ( DelayFrames( 2 ) ) return 1;
    }

    return 0;
}

/* ********************************************* */

static int8_t animateAlienShot( int x, int from_y, int to_y, uint8_t * sprite ) {
    int py, opy = -1;
    uint8_t anim = 0;

    for ( py = from_y; py <= to_y; opy = py, py++ ) {
        if ( opy != -1 )    PutSprite1Delete( x, opy, sprite + ( ( anim & 3 ) << 3 ) );
        anim++;
                            PutSprite1Merge(  x,  py, sprite + ( ( anim & 3 ) << 3 ) );
        if ( DelayFrames( 1 ) ) return 1;
    }

    return 0;
}

/* ********************************************* */

int8_t scoreTable_Screen( int8_t invertY ) {

    ClearRows( 16, 168 );

    currentMenuScreen = 1;

    DrawScoreHeaderAndCredits();

    int8_t ret = DelayFrames( 50 ); // 1 seconds

    if ( !ret ) ret = PrintAtDelay( 112,  40, invertY ? "PLA\"" : "PLAY"    , 5 );
    if ( !ret ) ret = PrintAtDelay(  72,  64, "SPACE  INVADERS"             , 5 );

    if ( !ret ) ret = DelayFrames( 100 ); // 2 seconds

    if ( !ret ) {
                      PrintAt(   48,  96, "*SCORE ADVANCE TABLE*" );
                      PutSprite3( 76, 112, SpriteSaucer   );
                      PutSprite2( 80, 128, AlienSprC      );
                      PutSprite2( 80, 144, AlienSprB + 16 );
                      PutSprite2( 80, 160, AlienSprA      );
    }
    
    if ( !ret ) ret = PrintAtDelayArr( scoreScreenTxt, sizeof( scoreScreenTxt ) / sizeof( scoreScreenTxt[0] ), 5 );

    return ret;

}

/* ********************************************* */

int8_t animateAlienCY() {
    int8_t ret;
    
    ret = scoreTable_Screen( 1 );
    if ( !ret ) ret = DelayFrames( 50 ); // 1 seconds
    if ( !ret ) ret = animateSpriteX( 40,      254, 112 + 24 + 4, -2,   AlienSprC, AlienSprC + 16 );
    if ( !ret ) ret = animateSpriteX( 40, 112 + 24,          254,  2, AlienSprCYA, AlienSprCYB    );
    if ( !ret ) ret = DelayFrames( 100 ); // 2 seconds
    if ( !ret ) ret = animateSpriteX( 40,      254, 112 + 24    , -2,  AlienSprCA, AlienSprCB     );
    if ( !ret ) ret = DelayFrames( 100 ); // 2 seconds
    if ( !ret ) PrintAt( ( uint8_t ) ( 112 + 24 ), 40, "Y " );

    return 0;
}

/* ********************************************* */

int8_t inserCoin_Screen( int8_t extraC ) {
    int8_t ret;

    ClearRows( 16, 168 );

    currentMenuScreen = 2;

          PrintAt(       88,  72, "INSERT  COIN" );
    if ( extraC )
          PrintChar( ( uint8_t ) ( 88 + 56 ), 72, 'C', 0 );

    ret = PrintAtDelay(  72, 104, "<1 OR 2 PLAYERS>" , 0 );

    if ( displayCoinage ) {
        if ( !ret ) ret = PrintAtDelayArr( insertCoinScreenTxt, sizeof( insertCoinScreenTxt ) / sizeof( insertCoinScreenTxt[0] ), 5 );
    }

    return ret;
}

/* ********************************************* */

int8_t inserCoin_ScreenC() {
    int8_t ret;

    ret = inserCoin_Screen( 1 );
    if ( !ret ) ret = DelayFrames( 50 ); // 1 seconds
    if ( !ret ) ret = animateSpriteX( 24, 2, 88 + 56 - 4, 2, AlienSprC, AlienSprC + 16 );
    if ( !ret ) ret = animateAlienShot( 88 + 56 - 4 + 6, 24 + 8, 72, SquiglyShot );

    if ( !ret ) {
        PutSprite1Merge( ( uint8_t ) ( 88 + 56 ), 72, AShotExplo );
        if ( DelayFrames( 5 ) ) return 1;
        PrintChar( ( uint8_t ) ( 88 + 56 ), 72, ' ', 0 );
    }

    return ret;
}

/* ********************************************* */

void pushPlayerButton_Screen() {

    if ( currentMenuScreen != 100 ) ClearRows( 16, 168 );

    currentMenuScreen = 100;

    PrintAt ( 112, 72, "PUSH" );
    PrintAt ( 48,  96, ( numCredits == 1 ) ? "ONLY 1PLAYER  BUTTON" : "1 OR 2PLAYERS BUTTON" );

    syskey.keyPressed = 0;

}

/* ********************************************* */

//#ifdef __SPECTRUM__
/*
void showCursor( uint8_t x1, uint8_t x2, uint8_t y, int8_t flags ) {
    PrintChar( x1, y, ( ( flags & 1 ) ? '<' : ' ' ), 0 );
    PrintChar( x2, y, ( ( flags & 2 ) ? '>' : ' ' ), 0 );
}

void deleteCursor( uint8_t x1, uint8_t x2, uint8_t y ) {
    PrintChar( x1, y, ' ', 0 );
    PrintChar( x2, y, ' ', 0 );
}
*/
/* ********************************************* */
/*
static int8_t cursorPos = 0, left, right, up, down, shot, flags = 0;
static uint8_t key = 0, ukey = 0, x1 = 0, x2 = 0, y = 0;

int8_t setup_Screen() {
    ClearRows( 16, 168 );

    currentMenuScreen = 3;

    PrintAtArr( setupScreenTxt, sizeof( setupScreenTxt ) / sizeof( setupScreenTxt[0] ) );

    while ( 1 ) {
        ukey = key & 0x3F;

        key = ( ( ( ~inp( 0xF7FE ) ) & 0x10 ) << 1 ) | ( ( ~inp( 0xEFFE ) ) & 0x1F ) ;
        left    = key & 0x20;
        right   = key & 0x04;
        up      = key & 0x08;
        down    = key & 0x10;
        shot    = key & 0x01 | ( ( ~inp( 0xBFFE ) ) & 0x01 );

        __asm
            halt
            halt
            halt
        __endasm;

        flags = 0;

        if ( !ukey ) {
            switch ( cursorPos ) {
                case 0:
                    x1 = 216; x2 = 232; y = 56;

                    if ( left && numLives > 3 ) numLives--;
                    if ( right && numLives < 6 ) numLives++;

                    if ( numLives > 3 ) flags |= 1;
                    if ( numLives < 6 ) flags |= 2;

                    break;

                case 1:
                    x1 = 192; x2 = 232; y = 72;

                    if ( left ) bonusLife = 1000;
                    if ( right ) bonusLife = 1500;

                    if ( bonusLife == 1500 ) flags = 1; else flags = 2;
                    break;

                case 2:
                    x1 = 200; x2 = 232; y = 88;

                    if ( left ) displayCoinage = 0;
                    if ( right ) displayCoinage = 1;

                    if ( displayCoinage ) flags = 1; else flags = 2;
                    break;

                case 3:
#ifdef __SPECTRUM__
                    x1 = 144; x2 = 232; y = 104;

                    if ( left  && player[ 0 ].input ) player[ 0 ].input--;
                    if ( right && player[ 0 ].input < sizeof( inputTab ) / sizeof( inputTab[ 0 ] ) - 1 ) player[ 0 ].input++;

                    if ( player[ 0 ].input > 0                                                ) flags |= 1;
                    if ( player[ 0 ].input < sizeof( inputTab ) / sizeof( inputTab[ 0 ] ) - 1 ) flags |= 2;
                    break;

                case 4:
                    x1 = 144; x2 = 232; y = 120;

                    if ( left  && player[ 1 ].input ) player[ 1 ].input--;
                    if ( right && player[ 1 ].input < sizeof( inputTab ) / sizeof( inputTab[ 0 ] ) - 1 ) player[ 1 ].input++;

                    if ( player[ 1 ].input > 0                                                ) flags |= 1;
                    if ( player[ 1 ].input < sizeof( inputTab ) / sizeof( inputTab[ 0 ] ) - 1 ) flags |= 2;
                    break;

                case 5:
#endif
#ifndef __NOSOUND__
                    x1 = 120; x2 = 232; y = 136;

                    if ( left  && soundSystem ) soundSystem--;
                    if ( right && soundSystem < sizeof( soundTab ) / sizeof( soundTab[ 0 ] ) - 1 ) soundSystem++;

                    if ( soundSystem > 0                                                ) flags |= 1;
                    if ( soundSystem < sizeof( soundTab ) / sizeof( soundTab[ 0 ] ) - 1 ) flags |= 2;
                    break;

#ifdef __ZX81__
                case 4:
#else
                case 5:
#endif
#endif
                    x1 = 136; x2 = 112; y = 160;

                    if ( shot ) {
                        syskey.keyPressed = 0;
                        return 0;
                    }
                    flags = 3;
                    break;
            }

            if ( up || down ) {
                PrintChar( x1, y, ' ', 0 );
                PrintChar( x2, y, ' ', 0 );

                if ( up ) cursorPos--; else cursorPos++;

#ifdef __SPECTRUM__
#ifndef __NOSOUND__
                if ( cursorPos < 0 ) cursorPos = 6;
                if ( cursorPos > 6 ) cursorPos = 0;
#else
                if ( cursorPos < 0 ) cursorPos = 5;
                if ( cursorPos > 5 ) cursorPos = 0;
#endif
#endif
#ifdef __ZX81__
#ifndef __NOSOUND__
                if ( cursorPos < 0 ) cursorPos = 3;
                if ( cursorPos > 3 ) cursorPos = 0;
#else
                if ( cursorPos < 0 ) cursorPos = 4;
                if ( cursorPos > 4 ) cursorPos = 0;
#endif
#endif
            }
            else {
                PrintChar( x1, y, ( ( flags & 1 ) ? '<' : ' ' ), 0 );
                PrintChar( x2, y, ( ( flags & 2 ) ? '>' : ' ' ), 0 );                
            }

            PrintNumAt( 224,  56, numLives,  1 );
            PrintNumAt( 200,  72, bonusLife, 4 );
               PrintAt( 208,  88, displayCoinage ? " ON" : "OFF" );
#ifdef __SPECTRUM__
               PrintAt( 152, 104, inputTab[ player[ 0 ].input ] );
               PrintAt( 152, 120, inputTab[ player[ 1 ].input ] );
#endif
#ifndef __NOSOUND__
               PrintAt( 128, 136, soundTab[ soundSystem ] );
#endif
        }
    }

    return 0;
}
*/
/* ********************************************* */

//#endif

int8_t help_Screen() {
    ClearRows( 16, 168 );

    currentMenuScreen = 4;

    PrintAtArr( helpScreenTxt, sizeof( helpScreenTxt ) / sizeof( helpScreenTxt[0] ) );

    DelayFrames( 200 ); // 4 seconds

    syskey.keyPressed = 0;

    return 0;
}


#ifdef __SPECTRUM__
#include <z80.h>
#endif

#include "utils.h"
#include "utils_asm.h"
#include "common.h"
#include "input.h"

#include "PutSprite.h"

/* ********************************************* */

int8_t _ExitIfKeyPressed = 0;

/* ********************************************* */

#if 0
int8_t DelayFrames( uint8_t frames ) {
    while ( frames-- ) {
        WaitFrame();
#ifdef __ZX81__
        readSysKeys();
#endif
        if ( _ExitIfKeyPressed && syskey.keyPressed ) return 1;
    }
    return 0;
}
#endif

/* ********************************************* */

char buff[ 16 ];

#if 0
void PrintNumAt( uint8_t x, uint8_t y, int16_t num, uint8_t flags ) {
    unsigned char *p = &buff[ 14 ];
    int8_t d, c = 0, is_negative = 0, leftzero = flags & NUM_LEFTZERO, digits = flags & 7;

    p[ 1 ] = '\0';

    if ( !( flags & NUM_UNSIGNED ) && num < 0 ) {
        is_negative = 1;
        num = -num;
        digits--;
    }

    uint16_t n = ( uint16_t ) num;
    while ( digits-- && p >= buff ) {
        d = n % 10;
        n /= 10;
        if ( !( n | d ) && !leftzero && c ) {
            if ( is_negative ) {
                is_negative = 0;
                *p-- = '-';
                digits++;
            } else {
                *p-- = ' ';
            }
        } else {
            *p-- = '0' + d;
        }
        c = 1;
    }
    if ( is_negative ) *p-- = '-';
    p++;

    PrintAt( x, y, p );
}
#else
void PrintNumAt( uint8_t x, uint8_t y, uint16_t num, uint8_t flags ) {
    unsigned char *p = &buff[ 14 ];
    int8_t d, c = 0, leftzero = flags & NUM_LEFTZERO, digits = flags & 7;

    p[ 1 ] = '\0';

    uint16_t n = ( uint16_t ) num;
    while ( digits-- && p >= buff ) {
        d = n % 10;
        n /= 10;
        if ( !( n | d ) && !leftzero && c ) {
            *p-- = ' ';
        } else {
            *p-- = '0' + d;
        }
        c = 1;
    }
    p++;

    PrintAt( x, y, p );
}
#endif

/* ********************************************* */

void PrintAt( uint8_t x, uint8_t y, unsigned char * msg ) {
    while ( *msg ) {
        PrintChar( x, y, *msg++, 0 );
        x += 8;
    }
}

/* ********************************************* */

int PrintAtDelay( uint8_t x, uint8_t y, unsigned char * msg, uint8_t delay ) {
    while ( *msg ) {
        if ( DelayFrames( delay ) ) return 1;
        PrintChar( x, y, *msg++, 0 );
        x += 8;
    }

    return 0;
}

/* ********************************************* */

void PutChars( uint8_t x, uint8_t y, uint8_t ch, uint8_t cnt, uint8_t method ) {
    while( cnt-- ) {
        PrintChar( x, y, ch, method );
        if ( x >= 256u - 8 ) break;
        x += 8;
    }
}

/* ********************************************* */

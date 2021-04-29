#include <stdint.h>

#include "common.h"
#include "input.h"
#include "screens.h"
#include "utils_asm.h"

#ifdef __SPECTRUM__
#include <z80.h>
#endif

/* ********************************************* */

union _syskey syskey;


/* Input */

union _input input;

#ifdef __ZX81__
static uint8_t zxpandJoyEnabled = 0;
#endif

static uint8_t keyCreditEnable = 1;

/* ********************************************* */

void InputDetect() {
#ifdef __ZX81__
    zxpandJoyEnabled = zxpand_joyenabled();
#endif
}

/* ********************************************* */

/*
Kempston port 0x1f

0x01 - Right
0x02 - Left
0x04 - Down
0x08 - Up
0x10 - Fire
*/

//--------------------------------------------
// IN 65278 (0xFEFE) reads the half row CAPS SHIFT to V
// IN 65022 (0xFDFE) reads the half row A to G
// IN 64510 (0xFBFE) reads the half row Q to T
// IN 63486 (0xF7FE) reads the half row 1 to 5
// IN 61438 (0xEFFE) reads the half row O to 6
// IN 57342 (0xDFFE) reads the half row P to Y
// IN 49150 (0xBFFE) reads the half row ENTER to H
// IN 32766 (0x7FFE) reads the half row SPACE to B
//--------------------------------------------
// |               |                     |
// |               | Buffer number       |
// | KEY           |---------------------|
// |               | DEC     | Hex       |
// |---------------|---------|-----------|
// | CS    ... V   | 65278   | # FEFE    |
// | A     ... G   | 65022   | # FDFE    |
// | Q     ... T   | 64510   | # FBFE    |
// | 1     ... 5   | 63486   | # F7FE    |
// | 0     ... 6   | 61438   | # EFFE    |
// | P     ... Y   | 57342   | # DFFE    |
// | ENTER ... H   | 49150   | # BFFE    |
// | SPACE ... B   | 32766   | # 7FFE    |
// |_______________|_________|___________|

void readInput() {
    uint8_t key;

    switch ( playerPtr->input ) {
        case 0: // Keyboard
            key             = ~inp( 0xDFFE );
            input.moveLeft  = ( key & 0x02 ) >> 1;
            input.moveRight =   key & 0x01;
            input.shot      = ( ~inp( 0xFEFE ) | ~inp( 0xFDFE ) ) & 0x01;

#ifdef __ZX81__
            if ( zxpandJoyEnabled ) {
                key = zxpand_joyread();

                /*
                Bit -- Direction
                7 Up
                6 Down
                5 Left
                4 Right
                3 Fire
                */
                input.moveLeft  |= !( key & 0x20 );
                input.moveRight |= !( key & 0x10 );
                input.shot      |= !( key & 0x08 );
            }
#endif
            break;
//#ifdef __SPECTRUM__
        case 1: // Cursor
            input.moveLeft  = ( ( ~inp( 0xF7FE ) ) & 0x10 ) != 0;
            key             = ~inp( 0xEFFE );
            input.moveRight = ( key & 0x04 ) != 0;
            input.shot      =   key & 0x01;
            break;

        case 2: // Sinclair 1
            key             = ~inp( 0xEFFE );
            input.moveLeft  = ( key & 0x10 ) != 0;
            input.moveRight = ( key & 0x08 ) != 0;
            input.shot      =   key & 0x01;
            break;

        case 3: // Sinclair 2
            key             = ~inp( 0xF7FE );
            input.moveLeft  =   key & 0x01;
            input.moveRight = ( key & 0x02 ) >> 1;
            input.shot      = ( key & 0x10 ) != 0;
            break;

        case 4: // Kempston
            key             = inp( 0x1F );
            input.moveLeft  = ( key & 0x02 ) >> 1;
            input.moveRight =   key & 0x01;
            input.shot      = ( key & 0x10 ) != 0;
            break;

        case 5: // Fuller
            // port 0x7f in the form F---RLDU
            key             = ~inp( 0x7F );
            input.moveLeft  = ( key & 0x04 ) != 0;
            input.moveRight = ( key & 0x08 ) != 0;
            input.shot      = ( key & 0x80 ) != 0;
            break;
//#endif
    }

#ifdef __ZX81__
    readSysKeys();
#endif

}

/* ********************************************* */

void readSysKeys() {
    uint8_t key;

    // CS - V
    key = ~inp( 0xFEFE );
    if ( key & 0x08 ) { // Key Setup (c)
        syskey.showSetup = 1;
    }

    // ENTER - H
    key = ~inp( 0xBFFE );
    if ( key & 0x04 ) { // Key Credits (+/k)
        if ( keyCreditEnable ) {
            keyCreditEnable = 0;
            syskey.keyCredit = 1;
            if ( numCredits < 99 ) {
                numCredits++;
                DrawCredits();
            }
        }
    } else {
        syskey.keyCredit = 0;
        keyCreditEnable = 1;
    }

    if ( key & 0x10 ) { // Key Help (h)
        syskey.showHelp = 1;
    }

    if ( numCredits > 0 ) {
        // A - G
        key = ~inp( 0xF7FE );

        if ( key & 0x01 ) { // One Player (1)
            syskey.keyStart1UP = 1;
        }

        if ( numCredits > 1 ) {
            if ( key & 0x02 ) { // Two Player (2)
                syskey.keyStart2UP = 1;
            }
        }
    }
}

/* ********************************************* */

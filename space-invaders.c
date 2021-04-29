#include <stdint.h>
//#include <string.h>

#ifdef __SPECTRUM__
#include <arch/zx.h>
#include <z80.h>

#include "isr.h"
#endif

#ifdef __ZX81__
#include <malloc.h>

long heap;
#endif

#pragma preproc_asm +

#include "common.h"

#include "utils_asm.h"
#include "utils.h"
#include "screens.h"
#include "round.h"
#include "round_routines.h"
#include "charset.h"
#include "sound.h"

#include "input.h"

/* ********************************************* */

void main() {
    numCredits = 0;
    playersInGame = 0;

    int8_t menu = 0;

#ifdef __ZX81__
    heap = 0L;                      // heap is empty
//    sbrk( (void *) 40960, 4096 );   // add 40960 (HRSCREEN+6144), 4096 to malloc 
    sbrk( (void *) 0x9800, 2048 );

    ClearRows( 0, 192 );

    player = ( _player * ) calloc( 1, sizeof( _player ) * 2 );
    if ( !player ) return;
#endif

#ifdef __SPECTRUM__
    // Define FONTS
//    z80_wpoke( 23606, ( uint16_t ) ( CHARSET - 256 ) );

    __asm
        ei
    __endasm;
#endif

    // *********************************************

    InputDetect();

#ifdef __SPECTRUM__
    zx_border(INK_BLACK);
#endif
#ifndef __NOSOUND__
    SoundDetectCard();
#endif
#ifdef __SPECTRUM__
    DelayFrames( 100 ); // 2 seconds

    zx_cls(PAPER_BLACK|INK_WHITE);
#endif

    DrawScreenColors();

    help_Screen();

#ifdef __SPECTRUM__
    init_frames_isr();
#endif

    // Controls => keyboard
    player[ 0 ].input = player[ 1 ].input = 0;

main_menu:

    resetPlayer( 1, 1 );
    resetPlayer( 0, 1 );

    int8_t ret = 0;

    if ( !numCredits ) {
        do {
            _ExitIfKeyPressed = 1;
#ifdef __ZX81__
            readSysKeys();
#endif
            switch ( menu ) {
                case 0:
                    if ( !( ret = scoreTable_Screen( 0 ) ) ) menu++;
                    break;

                case 1:
                    if ( !( ret = playGame( 1 ) ) ) 
                        menu++;
                    break;

                case 2:
                    if ( !( ret = inserCoin_Screen( 0 ) ) ) menu++;
                    break;

                case 3:
                    if ( !( ret = animateAlienCY() ) ) menu++;
                    break;

                case 4:
                    if ( !( ret = playGame( 1 ) ) ) menu++;
                    break;

                case 5:
                    if ( !( ret = inserCoin_ScreenC() ) ) menu = 0;
                    break;

            }
            
            if ( !ret ) ret = DelayFrames( 100 ); // 2 seconds

            _ExitIfKeyPressed = 0;
            if ( syskey.showSetup ) { ret = setup_Screen(); syskey.keyPressed = 0; }
            if ( syskey.showHelp  ) { ret = help_Screen();  syskey.keyPressed = 0; }
        } while ( !ret && !numCredits );
    }

    syskey.keyPressed = 0;
    pushPlayerButton_Screen();
    do {
#ifdef __ZX81__
        readSysKeys();
#endif
        if ( syskey.showSetup ) { ret = setup_Screen(); syskey.keyPressed = 0; syskey.keyCredit = 1; }
        if ( syskey.showHelp  ) { ret = help_Screen();  syskey.keyPressed = 0; syskey.keyCredit = 1; }
        if ( syskey.keyCredit ) pushPlayerButton_Screen();
    } while ( !syskey.keyStart1UP && !syskey.keyStart2UP );

    playersInGame = syskey.keyStart2UP ? 2 : 1;

    numCredits -= playersInGame;

    currentMenuScreen = 0;

    ret = playGame( 0 );

    syskey.keyPressed = 0;

    if ( menu < 2 ) menu = 2;
    else menu = 5;

    goto main_menu;

}

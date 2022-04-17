#include <stdint.h>

#ifdef __SPECTRUM__
#ifdef __ZXN__
#include <arch/zxn.h>
#else
#include <arch/zx.h>
#endif
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

#ifdef __ZXN__
#include "zxn_sound_engine.h"
#else
#include "sound.h"
#endif

#include "input.h"

#ifdef __ZXN__
#include "background.h"
#endif

/* ********************************************* */

#ifdef __ZXN__
#define REG_LAYER_2_CONTROL  112
#define LAYER_2_320x256x8    0x10

/* ********************************************* */

void intro_screen() {

    // Disable LUA
    IO_NEXTREG_REG = 0x68;
    uint8_t current_ula_status = IO_NEXTREG_DAT;
    IO_NEXTREG_DAT = current_ula_status | 0x80; 

    // Select Background Bank
    IO_NEXTREG_REG = REG_LAYER_2_RAM_BANK;
    IO_NEXTREG_DAT = 14;

    // Setup Palette
    IO_NEXTREG_REG = REG_PALETTE_CONTROL;
    IO_NEXTREG_DAT = 0x10;

    IO_NEXTREG_REG = REG_PALETTE_INDEX;
    IO_NEXTREG_DAT = 0;

    IO_NEXTREG_REG = REG_PALETTE_VALUE_16;
    for (int i = 0; i < 512; i++) IO_NEXTREG_DAT = intro_screen_pal[i];

    // Delay
    DelayFrames( 400 );

    // Restore ULA
    IO_NEXTREG_REG = 0x68;
    IO_NEXTREG_DAT = current_ula_status;

}

/* ********************************************* */

void background_screen() {
    // Select Background Bank
    IO_NEXTREG_REG = REG_LAYER_2_RAM_BANK;
    IO_NEXTREG_DAT = 9;

    // Setup Palette
    IO_NEXTREG_REG = REG_PALETTE_CONTROL;
    IO_NEXTREG_DAT = 0x10;

    IO_NEXTREG_REG = REG_PALETTE_INDEX;
    IO_NEXTREG_DAT = 0;

    IO_NEXTREG_REG = REG_PALETTE_VALUE_16;
    for (int i = 0; i < 512; i++) IO_NEXTREG_DAT = background_pal[i];
}

#endif

/* ********************************************* */

void main() {
    numCredits = 0;
    playersInGame = 0;

    int8_t menu = 0;

#ifdef __ZXN__

    // Make sure the Spectrum ROM is paged in initially.
    IO_7FFD = IO_7FFD_ROM0;

    // Put Z80 in 28 MHz turbo mode.
    IO_NEXTREG_REG = REG_TURBO_MODE;
    IO_NEXTREG_DAT = 0x03;

    IO_NEXTREG_REG = REG_LAYER_2_CONTROL;
    IO_NEXTREG_DAT = LAYER_2_320x256x8;

    // layer2SetClipWindow ( 0, 255, 0, 255); // hide the sprite window
    IO_NEXTREG_REG = REG_CLIP_WINDOW_LAYER_2;
    IO_NEXTREG_DAT = 0;
    IO_NEXTREG_DAT = 255;
    IO_NEXTREG_DAT = 0;
    IO_NEXTREG_DAT = 255;

    // Show layer2
    IO_LAYER_2_CONFIG = IL2C_SHOW_LAYER_2;

    // NextReg 20,$e3                  ; set global transparancy value
    IO_NEXTREG_REG = 20;
    IO_NEXTREG_DAT = 0x00;

    // ;NextReg 64,$88                  ; set "bright+black" ULA colour
    // ;NextReg 65,$e3                  ; set BRIGHT+BLACK to transparent

    IO_NEXTREG_REG = 64;                // set BRIGHT BLACK to transparent
    IO_NEXTREG_DAT = 0x18;
    IO_NEXTREG_REG = 65;
    IO_NEXTREG_DAT = 0x00;
    // NextReg 65,$e3
    

//    IO_NEXTREG_REG = 0x68;
//    IO_NEXTREG_DAT = 64;          // Blending

    IO_NEXTREG_REG = 0x15;
    IO_NEXTREG_DAT = 3|(4<<2);          // U_S_L ( ULA -> Sprites --> Layer2 )

#endif

#ifdef __ZX81__
    heap = 0L;                      // heap is empty
//    sbrk( (void *) 40960, 4096 );   // add 40960 (HRSCREEN+6144), 4096 to malloc 
    sbrk( (void *) 0x9800, 2048 );

    ClearRows( 0, 192 );

    player = ( _player * ) calloc( 1, sizeof( _player ) * 2 );
    if ( !player ) return;
#endif

#ifdef __SPECTRUM__
    __asm
        ei
    __endasm;
#endif

    // *********************************************

    InputDetect();

#ifndef __NOSOUND__
#ifdef __ZXN__
    SoundInit();
#else
    SoundDetectCard();
#endif
#endif
#ifdef __SPECTRUM__
    zx_border(INK_BLACK);

#ifdef __ZXN__
    zx_cls(PAPER_BLACK|INK_WHITE);
    intro_screen();
#endif

    DelayFrames( 100 ); // 2 seconds

    zx_cls(PAPER_BLACK|INK_WHITE);
#endif

#ifdef __ZXN__
    background_screen();
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
#ifdef __ZXN__
            if ( syskey.showIntro ) { intro_screen(); background_screen(); syskey.keyPressed = 0; ret = 0; }
#endif
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
#ifdef __ZXN__
        if ( syskey.showIntro ) { intro_screen(); background_screen(); syskey.keyPressed = 0; syskey.keyCredit = 1; ret = 0; }
#endif
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

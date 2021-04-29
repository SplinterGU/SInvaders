#include <z80.h>
#include <im2.h>
#include <string.h>

#include "common.h"
#include "round.h"
#include "round_routines.h"
#include "input.h"

/* ********************************************* */

IM2_DEFINE_ISR_WITH_BASIC( isr ) {
    readSysKeys();

    if ( gameState == 1 ) gameState = iterGame();

}

/* ********************************************* */

#define TABLE_HIGH_BYTE        (( unsigned int ) 0xfc )
#define JUMP_POINT_HIGH_BYTE   (( unsigned int ) 0xfb )

#define UI_256                 (( unsigned int ) 256 )

#define TABLE_ADDR             (( void * )( TABLE_HIGH_BYTE * UI_256 ))
#define JUMP_POINT             (( unsigned char * )(( unsigned int )( JUMP_POINT_HIGH_BYTE * UI_256 ) + JUMP_POINT_HIGH_BYTE ))

/* ********************************************* */
extern void * isr_table;
void init_frames_isr() {
  /* Set up the interrupt vector table */
  im2_init( TABLE_ADDR );

  memset( TABLE_ADDR, JUMP_POINT_HIGH_BYTE, 257 );

  z80_bpoke( JUMP_POINT    , 195 );
  z80_wpoke( JUMP_POINT + 1, ( unsigned int ) isr );

}

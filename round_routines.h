#ifndef _ROUND_ROUTINES_H
#define _ROUND_ROUTINES_H

#include <stdint.h>

typedef struct {
    // off: 0
    uint8_t active;
    // off: 1
    uint8_t aniFrame;
    // off: 2-3
    int16_t explodingCnt;
    // off: 4-5
    // off: 6-7
    int16_t x, y;
} _alienShotInfo;

extern void handleAlienShot( _alienShotInfo * asi, uint8_t * _sprite ) __z88dk_callee;
extern int16_t getAlienIdx( int16_t x, int16_t y, int8_t skipAdjust ) __z88dk_callee;
extern int8_t getAlienColumn( uint8_t x ) __preserves_regs(b,c) __z88dk_fastcall;
extern void handleAShotCollision( _alienShotInfo * asi, int8_t aShotYH, uint8_t * spr ) __z88dk_callee;
extern void handleNextAlien();
extern void StoreShields( uint8_t op ) __z88dk_fastcall; // 0 - Restore, 1 - Store
extern void resetPlayer( int8_t p, int8_t isFirst ) __z88dk_callee;
extern void resetRoundVars() __preserves_regs(b,c,d,e);
extern int8_t playGame( int8_t demo ) __z88dk_fastcall;
extern int8_t DelayFrames( uint8_t frames ) __z88dk_fastcall;

#endif

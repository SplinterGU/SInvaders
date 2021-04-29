#ifndef _UTILSASM_H
#define _UTILSASM_H

#include <stdint.h>

extern void ClearRows( uint8_t y, uint8_t h ) __preserves_regs(d,e) __z88dk_callee;
extern void * GetScreenAddr( uint8_t x, uint8_t y ) __preserves_regs(d,e) __z88dk_callee;
extern int16_t GetAttrAddr() __preserves_regs(d,e) __z88dk_fastcall;
#ifdef __ZX81__
extern void WaitFrame() __preserves_regs(b,c,d,e) __z88dk_fastcall;
extern unsigned char zxpand_joyread() __preserves_regs(b,c,d,e,h) __z88dk_fastcall;
extern unsigned char zxpand_joyenabled() __preserves_regs(b,c,d,e,h) __z88dk_fastcall;
#endif

extern int8_t getDivideBy11( uint8_t n ) __preserves_regs(b,c,d,e,h) __z88dk_fastcall;
extern int8_t getDivideBy12( uint8_t n ) __preserves_regs(b,c,d,e,h) __z88dk_fastcall;
extern int8_t getDivideBy16( uint8_t n ) __preserves_regs(b,c,d,e,h) __z88dk_fastcall;

extern unsigned char inp( unsigned short port ) __preserves_regs(d,e) __z88dk_callee;
extern void outp( unsigned short port, unsigned char value ) __preserves_regs(d,e) __z88dk_callee;

extern void copymem( void * dst, void * src, int size ) __z88dk_callee;

#ifdef __SPECTRUM__
#define WaitFrame() \
        __asm \
            halt \
        __endasm
#endif

extern int8_t DelayFrames( uint8_t frames ) __z88dk_fastcall;

#endif

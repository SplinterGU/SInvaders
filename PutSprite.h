#ifndef _PUTSPRITE_H
#define _PUTSPRITE_H

#include <stdint.h>

extern void PutSprite1( uint8_t x, uint8_t y, void * sprite ) __z88dk_callee;
extern void PutSprite1Merge( uint8_t x, uint8_t y, void * sprite ) __z88dk_callee;
extern void PutSprite1Delete( uint8_t x, uint8_t y, void * sprite ) __z88dk_callee;
extern void PutSprite2( uint8_t x, uint8_t y, void * sprite ) __z88dk_callee;
extern void PutSprite3( uint8_t x, uint8_t y, void * sprite ) __z88dk_callee;

extern void PrintChar( uint8_t x, uint8_t y, uint8_t ch, uint8_t mode ) __z88dk_callee;

#endif

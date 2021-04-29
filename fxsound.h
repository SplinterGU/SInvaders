#ifndef _FXSOUND_H
#define _FXSOUND_H

#include <inttypes.h>

extern void stopFX() __preserves_regs(b,c,d,e,h,l) __z88dk_fastcall;
extern void playFX(unsigned char id) __z88dk_fastcall;

#endif



#ifndef _ZX81IO_H
#define _ZX81IO_H

extern unsigned char z80_inp( unsigned short port ) __preserves_regs(d,e) __z88dk_callee;
extern void z80_outp( unsigned short port, unsigned char value ) __preserves_regs(d,e) __z88dk_callee;
extern unsigned char zxpand_joyread() __preserves_regs(b,c,d,e,h) __z88dk_fastcall;
extern unsigned char zxpand_joyenabled() __preserves_regs(b,c,d,e,h) __z88dk_fastcall;

#endif



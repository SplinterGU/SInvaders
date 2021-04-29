SECTION code_user

PUBLIC _z80_inp, _z80_outp, _zxpand_joyread, _zxpand_joyenabled

_z80_inp:
	pop hl
	pop bc
	push hl
	in l,(c)
	ret

_z80_outp:
	pop hl
	pop bc
	dec sp
	ex (sp),hl
	out (c),h
	ret

_zxpand_joyenabled:
	ld l,0
	push bc
	ld a,$aa
	ld bc,$e007
	out (c),a
	nop
	nop
	nop
	in a,(c)
	cp $f0
	jnz _zxpand_joyenabled_exit
	ld a,$55
	out (c),a
	nop
	nop
	nop
	in a,(c)
	cp $0f
	jnz _zxpand_joyenabled
	inc l
_zxpand_joyenabled_exit:
	pop bc
	ret

_zxpand_joyread:
	push bc
	ld a,$a0
	ld bc,$e007
	out (c),a
	nop
	nop
	nop
	in a,(c)
	ld l,a
	pop bc
	ret

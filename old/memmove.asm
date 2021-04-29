SECTION code_user

PUBLIC _memmove

_memmove:
   pop af ; return
   pop de ; dest
   pop hl ; source
   pop bc ; size
   push af
   
   ld a,b
   or c
   ret z
      
   ; use ldir or lddr
   ld a,d
   cp h
   jr c, use_ldir ; src > dst use ldir
   jr nz, use_lddr ; src < dst use lddr
   
   ld a,e
   cp l
   jr c, use_ldir ; src > dst use ldir
   
   ret z       ; if dst == src, do nothing

use_lddr:
   dec bc
   
   add hl,bc
   ex de,hl
   add hl,bc
   ex de,hl
   
   inc bc
   lddr   
   ret

use_ldir:
   ldir
   ret

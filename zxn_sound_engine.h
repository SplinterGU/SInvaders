#ifndef __ZXN_SOUND_H
#define __ZXN_SOUND_H

extern void SoundInit( void );
extern void SoundExecute( void );
extern int8_t SoundPlay( int8_t id ) __z88dk_fastcall;
extern void SoundStop( int8_t id ) __z88dk_fastcall;
extern int8_t SoundIsPlaying( int8_t id ) __z88dk_fastcall;

#endif

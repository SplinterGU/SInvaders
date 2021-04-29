#ifndef __SOUND_H
#define __SOUND_H

#include "common.inc"

/*
enum {
    SOUND_UFO = 1,
    SOUND_PLAYER_SHOT,
    SOUND_PLAYER_EXPLOSION,
    SOUND_ALIEN_EXPLOSION,
    SOUND_ALIEN_STEP1,
    SOUND_ALIEN_STEP2,
    SOUND_ALIEN_STEP3,
    SOUND_ALIEN_STEP4,
    SOUND_UFO_EXPLOSION,
    SOUND_EXTRA_LIFE
};

enum {
    SOUND_SYS_OFF = 0,
    SOUND_SYS_BEEPER,
    SOUND_SYS_SINCLAIR128K,
    SOUND_SYS_FULLERBOX
};
*/

extern int8_t soundSystem;
extern int8_t playingSound;

extern void SoundSetCard( int8_t id ) __z88dk_fastcall;
extern void SoundDetectCard();
extern void SoundPlay( int8_t id ) __z88dk_fastcall;
extern void SoundStop();
extern void SoundStopAll();
extern void SoundExecute();

#endif

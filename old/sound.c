#include <stdint.h>

#ifdef __SPECTRUM__
#include <z80.h>
#include "fxsound.h"
#endif

#include "utils_asm.h"
#include "sound.h"

int8_t soundSystem = 0;

uint16_t soundPIORegister = 0;
uint16_t soundPIOData = 0;

#ifdef __SPECTRUM__
int8_t playingSound = 0;
int8_t soundStopped = 0;

int8_t soundPriority[11] = {
     0, // NO SOUND
    20, // SOUND_UFO                A
    10, // SOUND_PLAYER_SHOT        B
    50, // SOUND_PLAYER_EXPLOSION   C
    30, // SOUND_ALIEN_EXPLOSION    B
     0, // SOUND_ALIEN_STEP1        A
     0, // SOUND_ALIEN_STEP2        A
     0, // SOUND_ALIEN_STEP3        A
     0, // SOUND_ALIEN_STEP4        A
    40, // SOUND_UFO_EXPLOSION      C
    60  // SOUND_EXTRA_LIFE         A
};
#endif

unsigned char ufo_sound[] = {
    228,252,0,27,
    228,245,0,0,
    228,238,0,28,
    228,231,0,0,
    228,224,0,29,
    228,217,0,0,
    228,224,0,30,
    228,231,0,0,
    228,238,0,31,
    228,245,0,0
};

unsigned char player_shot_sound[] = {
    109,51,0,8,108,52,0,9,107,53,0,10,106,54,0,11,105,55,0,12,104,56,0,13,103,57,0,14,102,58,0,15,101,59,0,16,228,60,0,17,227,61,0,18,226,62,0,19,226,63,0,20,226,0,0,0,130,130,208,32
};

unsigned char player_explosion_sound[] = {
    109,128,0,20,109,0,2,8,123,0,0,0,91,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,90,0,90,30,89,0,89,30,87,0,23,87,30,87,0,22,22,86,30,86,0,21,21,85,30,85,0,168,1,0,208,32
};

unsigned char alien_explosion_sound[] = {
    170,171,0,170,129,0,170,97,0,170,73,0,170,55,0,170,42,0,170,32,0,208,32
};

unsigned char alien_step_sound[] = {
    229,79,3,31,165,50,2,165,63,3,165,58,2,165,34,2,165,219,1,165,172,7,165,27,5,165,60,1,165,248,2,165,34,2,165,84,1,165,58,2,176,255,15,208,32
};

unsigned char ufo_explosion_sound[] = {
    238,96,0,30,238,128,0,0,174,96,0,174,128,0,174,192,0,174,0,1,174,64,1,174,128,1,174,64,1,174,0,1,174,192,0,174,128,0,174,96,0,172,128,0,172,192,0,172,0,1,172,64,1,172,128,1,172,64,1,172,0,1,172,192,0,172,128,0,172,96,0,208,32
};

unsigned char extra_life_sound[] = {
    174,106,1,173,181,0,174,106,1,173,181,0,174,106,1,160,0,0,128,128,128,128,174,106,1,173,181,0,174,106,1,173,181,0,174,106,1,160,0,0,128,128,128,128,174,106,1,173,181,0,174,106,1,173,181,0,174,106,1,160,0,0,128,128,128,128,208,32
};

unsigned char * ay_sounds[] = {
    0,
    ufo_sound,
    player_shot_sound,
    player_explosion_sound,
    alien_explosion_sound,
    alien_step_sound,
    alien_step_sound,
    alien_step_sound,
    alien_step_sound,
    ufo_explosion_sound,
    extra_life_sound
};

int16_t ay_sounds_sz[] = {
    0,
    sizeof( ufo_sound ),
    sizeof( player_shot_sound ),
    sizeof( player_explosion_sound ),
    sizeof( alien_explosion_sound ),
    sizeof( alien_step_sound ),
    sizeof( alien_step_sound ),
    sizeof( alien_step_sound ),
    sizeof( alien_step_sound ),
    sizeof( ufo_explosion_sound ),
    sizeof( extra_life_sound )
};

int8_t ay_used_channels_id[] = {
    0,
    0,
    0
};

int16_t ay_play_remains[] = {
    0,
    0,
    0
};

unsigned char * ay_play_ptr[] = {
    0,
    0,
    0
};

#if 0
void SoundDetect() {
#ifdef __SPECTRUM__
    // Sinclair 128k
    soundPIORegister = 0xfffd; // 65533
    soundPIOData = 0xbffd; // 49149

    outp( soundPIORegister, 8 ); outp( soundPIOData, 0   ); // Channel A - Volume 0
    outp( soundPIORegister, 0 ); outp( soundPIOData, 170 ); // Channel A - Tone Fine 170
    outp( soundPIORegister, 0 );
    if ( inp( soundPIORegister ) == 170 ) {
        soundSystem = SOUND_SYS_SINCLAIR128K;
        return;
    }

    // Fuller Box
    soundPIORegister = 0x3f; // 63
    soundPIOData = 0x5f; // 95

    outp( soundPIORegister, 8 ); outp( soundPIOData, 0   ); // Channel A - Volume 0
    outp( soundPIORegister, 0 ); outp( soundPIOData, 170 ); // Channel A - Tone Fine 170
    outp( soundPIORegister, 0 );
    if ( inp( soundPIORegister ) == 170 ) {
        soundSystem = SOUND_SYS_FULLERBOX;
        return;
    }

    soundSystem = SOUND_SYS_BEEPER;
#endif
#ifdef __ZX81__
    // Zon X
    soundPIORegister = 0xcf; // 207 // cf
    soundPIOData = 0x0f; // 15
    soundSystem = SOUND_SYS_ZONX;
//    soundSystem = SOUND_SYS_OFF;
#endif
}

void SoundStop() {
#ifdef __SPECTRUM__
    if ( soundSystem == SOUND_SYS_BEEPER ) {
        stopFX();
        playingSound = 0;
        soundStopped = 1;
    }
#endif
}

void SoundStopAll() {
#ifdef __SPECTRUM__
    if ( soundSystem == SOUND_SYS_BEEPER ) {
        // BeepFX
        SoundStop();
        
    } else 
#endif
    if ( soundSystem != SOUND_SYS_OFF ) {
        int8_t i;
        for ( i = 0; i < 3; i++ ) {
            if ( ay_used_channels_id[ i ] ) {
                ay_used_channels_id[ i ] = 0;
                outp( soundPIORegister, 8 + i ); outp( soundPIOData, 0 );
            }
        }
    }
}

void SoundPlay( int8_t id ) {
#ifdef __SPECTRUM__
    if ( soundSystem == SOUND_SYS_BEEPER ) {
        // BeepFX
        if ( playingSound ) {
            if ( soundPriority[ playingSound ] >= soundPriority[ id ] ) return;
            SoundStop();
        }
        playingSound = id;
        
    } else 
#endif
    if ( soundSystem != SOUND_SYS_OFF ) {
        int8_t i, available = -1;

        if ( !ay_sounds[ id ] ) return;
#if 0
        switch ( id ) {
            case SOUND_ALIEN_STEP1      :
            case SOUND_ALIEN_STEP2      :
            case SOUND_ALIEN_STEP3      :
            case SOUND_ALIEN_STEP4      :
                id = SOUND_ALIEN_STEP1;
                break;
        }
#endif
        for ( i = 0; i < 3; i++ ) {
            if ( !ay_used_channels_id[ i ] ) available = i;
            if ( ay_used_channels_id[ i ] == id ) return;
        }

        if ( available != -1 ) {
            ay_used_channels_id[ available ] = id;
            ay_play_ptr[ available ] = ay_sounds[ id ];
            ay_play_remains[ available ] = ay_sounds_sz[ id ];
        }
    }
}

//cmd+vol byte:  [NntTvvvv]            T(one)/N(oise) -> 1=off;  v=0 silence
//tone (word):   [dddddddd][xxxxdddd]  (only if t=1)  d=tone value
//noise (byte):  [EEEnnnnn]            (only if n=1) E=EndOfSfx n=noise value
//;
//end marker:
//cmd_vol byte   [11010000] 0xD0        ; T and N are off, volume is 0
//noise (byte)   [00100000] 0x20        ; noise is 0

void SoundExecute() {
#ifdef __SPECTRUM__
    if ( soundSystem == SOUND_SYS_BEEPER ) {
        if ( playingSound ) {
            playFX( playingSound );
            if ( !soundStopped ) {
                playingSound = 0;
            } else {
                soundStopped = 0;
            }
        }

    } else
#endif
    if ( soundSystem != SOUND_SYS_OFF ) {
        unsigned char mix = 0xff;
        int8_t i;
#ifdef __SPECTRUM__
        __asm
            di
        __endasm;
#endif
        for ( i = 0; i < 3; i++ ) {
            if ( ay_used_channels_id[ i ] ) {
                if ( ay_play_remains[ i ] > 0 ) {
                    unsigned char cmd = *(ay_play_ptr[i]++); ay_play_remains[ i ]--;
                    mix ^= ( ( cmd & 0x80 ) ? 0 : 0x08 << i ) | ( ( cmd & 0x10 ) ? 0 : 0x01 << i );
                    outp( soundPIORegister, 8 + i ); outp( soundPIOData, cmd & 0x0f );
                    if ( cmd & 0x20 ) {
                        outp( soundPIORegister, 0 + ( i << 1 ) ); outp( soundPIOData, *(ay_play_ptr[ i ]++) ); ay_play_remains[ i ]--;
                        outp( soundPIORegister, 1 + ( i << 1 ) ); outp( soundPIOData, *(ay_play_ptr[ i ]++) & 0x0f ); ay_play_remains[ i ]--;
                    }
                    if ( cmd & 0x40 ) {
                        outp( soundPIORegister, 6 ); outp( soundPIOData, *(ay_play_ptr[ i ]++) & 0x1f ); ay_play_remains[ i ]--;
                    }
                } else {
                    ay_used_channels_id[ i ] = 0;
                    outp( soundPIORegister, 8 + i ); outp( soundPIOData, 0 );
                }
            }
        }
        outp( soundPIORegister, 7 ); outp( soundPIOData, mix );
#ifdef __SPECTRUM__
        __asm
            ei
            halt
        __endasm;
#endif
    }

}
#endif

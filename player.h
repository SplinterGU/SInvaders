#ifndef __PLAYER_H
#define __PLAYER_H

/* ********************************************* */
/* WARNING: this struct is shared with ASM.      */
/* See: input.asm, round_routines.asm            */
/* ********************************************* */

typedef struct {
    /* Aliens */

    // use in round_routines.asm
    int8_t numAliens;                   // off: 0

    int8_t leftLimitCol,                // off: 1
           rightLimitCol;               // off: 2

    int16_t leftLimit,                  // off: 3-4
            rightLimit;                 // off: 5-6

    uint16_t aliensColMask;             // off: 7-8

    uint8_t aliens[55];                 // off: 9-63

    // use in round_routines.asm
    int16_t fleetTopBase;               // off: 64-65

    // use in round_routines.asm
    int16_t aliensX,                    // off: 66-67
            aliensY,                    // off: 68-69
            aliensDeltaX;               // off: 70-71

    // use in round_routines.asm
    int8_t alienIdx;                    // off: 72

    int16_t tillSaucer;                 // off: 73-74
                                        // = SAUCERTIMER; // Original Arcade 0x0600
    
    int8_t sauScore;                    // off: 75

    uint8_t alienShotMask;              // off: 76

    /* Player */

    int16_t shotsCounter;               // off: 77-78

    uint16_t score;                     // off: 79-80

    /* Alien Shot */

    int16_t reloadRate;                 // off: 81-82

    int8_t pluShotColIdx;               // off: 83    
    int8_t squShotColIdx;               // off: 84

    /* Others */

    int8_t numShips;                    // off: 85

    uint8_t round;                      // off: 86

    /* Input Control */

    // used in input.asm
    uint8_t input;                      // off: 87

    /* Shield */

    // use in round_routines.asm
    uint8_t currentShieldTopY;          // off: 88
                                        // = SHIELDTOPY;

    uint8_t shieldBackupSaved;          // off: 89

    uint8_t shieldBackup[32*24];        // off: 90-857

    // struct is 858 bytes
} _player;

#endif

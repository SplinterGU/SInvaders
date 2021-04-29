#ifndef __COMMON_H
#define __COMMON_H

#include <stdint.h>

#include "player.h"

/* ********************************************* */
/*
#define SHIELDTOPY      144u
#define PLAYERY         168u

#define SAUCERSPEED     3
#define SHOTSPEED       5
#define PLAYERSPEED     0 // 0

#define SAUCERTIMER     0x500 // 0x600
#define SAUCERROW       16

#define ALIENSPEED      1 // 80
#define ALIENSHOTSPEED  2

#define FLEETDELTAY     4
//#define FLEETDELTAY     8
#define FLEETPOSSTART   88

#define DEMOSPEED       50 // 320 // 256
*/

#include "common.inc"

/* ********************************************* */

extern int8_t numLives;
extern int16_t bonusLife;
extern int8_t displayCoinage;
extern uint8_t numCredits;
extern uint16_t hiScore;
extern int8_t playersInGame;
extern _player * playerPtr;

/* ********************************************* */

#ifdef __ZX81__
extern _player *player;
#endif

#ifdef __SPECTRUM__
extern _player player[2];
#endif

/* ********************************************* */

#endif

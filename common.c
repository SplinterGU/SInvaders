#include "common.h"

/* Others */

int8_t numLives = 3;
int16_t bonusLife = 1500;
int8_t displayCoinage = 1;
uint8_t numCredits = 0;
uint16_t hiScore = 0;
int8_t playersInGame = 0;

#ifdef __ZX81__
_player *player;
#endif

#ifdef __SPECTRUM__
_player player[2];
#endif

_player * playerPtr = 0;

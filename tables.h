#ifndef __TABLES_H
#define __TABLES_H

#include "common.h"

/* ********************************************* */
/* Tables                                        */
/* ********************************************* */

// Score table for hitting alien type
extern uint8_t AlienScores[];

// Aliens Y for aliens. Used for rounds 2nd to 9th, 10th reapeat from start. First round use FLEETTOPSTART.
extern uint8_t AlienStartTable[];

extern uint8_t * AlienSprites[5];

//extern uint16_t alienDelay[];

/*
1A11: 32 2B 24 1C 16 11 0D 0A 08 07 06 05 04 03 02 01
1A21: 34 2E 27 22 1C 18 15 13 10 0E 0D 0C 0B 09 07 05
*/

// The tables at 1CB8 and 1AA1 control how fast shots are created. The speed is based
// on the upper byte of the player's score. For a score of less than or equal 0200 then
// the fire speed is 30. For a score less than or equal 1000 the shot speed is 10. Less
// than or equal 2000 the speed is 0B. Less than or equal 3000 is 08. And anything
// above 3000 is 07.
//
extern uint16_t AReloadScoreTab[5];

// The tables at 1CB8 and 1AA1 control how fast shots are created. The speed is based
// on the upper byte of the player's score. For a score of less than or equal 0200 then 
// the fire speed is 30. For a score less than or equal 1000 the shot speed is 10. Less 
// than or equal 2000 the speed is 0B. Less than or equal 3000 is 08. And anything 
// above 3000 is 07.
//

extern uint8_t ShotReloadRate[5];

/* Saucer */

// points here to the score given when the saucer is shot. It advances
// every time the player-shot is removed. The code wraps after 15, but there
// are 16 values in this table. This is a bug in the code at 044E (thanks to
// Colin Dooley for finding this).
//
// Thus the one and only 300 comes up every 15 shots (after an initial 8).
extern uint16_t SaucerScrTab[15];

// This table decides which column a shot will fall from. The column number is read from the
// table (1-11) and the pointer increases for the shot type. For instance, the "squiggly" shot
// will fall from columns in this order: 11, 1, 6, 3. If you play the game you'll see that order.
//
// The "plunger" shot uses index 00-15 (inclusive)
// The "squiggly" shot uses index 06-20 (inclusive)
// The "rolling" shot targets the player

extern uint8_t ColFireTable[];

extern uint8_t DemoCommands[12];

#endif

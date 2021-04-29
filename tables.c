#include "common.h"
#include "sprites.h"

/* ********************************************* */
/* Tables                                        */
/* ********************************************* */

// Score table for hitting alien type
uint8_t AlienScores[] = {
    10, // Bottom rows
    10,
    20, // Highest row
    20, 
    30  // Highest row
};

// Aliens Y for aliens. Used for rounds 2nd to 9th, 10th reapeat from start. First round use FLEETTOPSTART.
uint8_t AlienStartTable[] = {
    FLEETPOSSTART + FLEETDELTAY * 3,
    FLEETPOSSTART + FLEETDELTAY * 5,
    FLEETPOSSTART + FLEETDELTAY * 6,
    FLEETPOSSTART + FLEETDELTAY * 6,
    FLEETPOSSTART + FLEETDELTAY * 6,
    FLEETPOSSTART + FLEETDELTAY * 7,
    FLEETPOSSTART + FLEETDELTAY * 7,
    FLEETPOSSTART + FLEETDELTAY * 7
};

uint8_t * AlienSprites[5] = { AlienSprA, AlienSprA, AlienSprB, AlienSprB, AlienSprC };
/*
uint16_t alienDelay[] = {
     5,
     7,
     9,
    11,
    12,
    13,
    14,
    16,
    16,
    19,
    19,
    19,
    21,
    21,
    21,
    21,
    24,
    24,
    24,
    24,
    24,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    28,
    34,
    39,
    39,
    39,
    39,
    39,
    39,
    46,
    46,
    46,
    46,
    46,
    46,
    46,
    52,
    52,
    52,
    52,
    52,
    52
};
*/
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
uint16_t AReloadScoreTab[5] = {
    0,
    200,
    1000,
    2000,
    3000
} ;

// The tables at 1CB8 and 1AA1 control how fast shots are created. The speed is based
// on the upper byte of the player's score. For a score of less than or equal 0200 then 
// the fire speed is 30. For a score less than or equal 1000 the shot speed is 10. Less 
// than or equal 2000 the speed is 0B. Less than or equal 3000 is 08. And anything 
// above 3000 is 07.
//

uint8_t ShotReloadRate[5] = {
    0x30,
    0x10,
    0x0B,
    0x08,
    0x07
} ; // Fastest shot firing speed

/* Saucer */

// points here to the score given when the saucer is shot. It advances
// every time the player-shot is removed. The code wraps after 15, but there
// are 16 values in this table. This is a bug in the code at 044E (thanks to
// Colin Dooley for finding this).
//
// Thus the one and only 300 comes up every 15 shots (after an initial 8).
uint16_t SaucerScrTab[15] = {
    100,
     50,
     50,
    100,
    150,
    100,
    100,
     50,
    300,
    100,
    100,
    100,
     50,
    150,
    100 //, 
//     50
};

// This table decides which column a shot will fall from. The column number is read from the
// table (1-11) and the pointer increases for the shot type. For instance, the "squiggly" shot
// will fall from columns in this order: 11, 1, 6, 3. If you play the game you'll see that order.
//
// The "plunger" shot uses index 00-15 (inclusive)
// The "squiggly" shot uses index 06-20 (inclusive)
// The "rolling" shot targets the player

uint8_t ColFireTable[] = { 
     1 - 1,
     7 - 1,
     1 - 1,
     1 - 1,
     1 - 1,
     4 - 1,
    11 - 1,
     1 - 1,
     6 - 1,
     3 - 1,
     1 - 1,
     1 - 1,
    11 - 1,
     9 - 1,
     2 - 1,
     8 - 1,
     2 - 1,
    11 - 1,
     4 - 1,
     7 - 1,
    10 - 1,
};

uint8_t DemoCommands[12] = {
    // (1=Right, 2=Left)
    01, 01, 00, 00, 01, 00, 02, 01, 00, 02, 01, 00
};

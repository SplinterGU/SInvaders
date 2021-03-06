#include "sprites.h"

uint8_t ShieldImage[] = {
    0b00001111, 0b11111111,
    0b00011111, 0b11111111,
    0b00111111, 0b11111111,
    0b01111111, 0b11111111,
    0b11111111, 0b11111111,
    0b11111111, 0b11111111,
    0b11111111, 0b11111111,
    0b11111111, 0b11111111,

    0b11110000,
    0b11111000,
    0b11111100,
    0b11111110,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,


    0b11111111,  0b11111111,
    0b11111111,  0b11111111,
    0b11111111,  0b11111111,
    0b11111111,  0b11111111,
    0b11111111,  0b11111111,
    0b11111110,  0b00000000,
    0b11111100,  0b00000000,
    0b11111000,  0b00000000,

    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b01111111,
    0b00111111,
    0b00011111

} ;

uint8_t PlayerSprite[] = {
    0b00000000, 0b10000000,
    0b00000001, 0b11000000,
    0b00000001, 0b11000000,
    0b00011111, 0b11111100,
    0b00111111, 0b11111110,
    0b00111111, 0b11111110,
    0b00111111, 0b11111110,
    0b00111111, 0b11111110

} ;


uint8_t PlrBlowupSprites[] = {
    0b00000010, 0b00000000,
    0b00000000, 0b00010000,
    0b00000010, 0b10100000,
    0b00010010, 0b00000000,
    0b00000001, 0b10110000,
    0b01000101, 0b10101000,
    0b00011111, 0b11100100,
    0b00111111, 0b11110101,

    0b00010000, 0b00000100,
    0b10000010, 0b00011001,
    0b00010000, 0b11000000,
    0b00000010, 0b00000010,
    0b01001011, 0b00110001,
    0b00100001, 0b11000100,
    0b00011111, 0b11110000,
    0b00110111, 0b11110010

};

uint8_t PlayerShotSpr[] = {
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b10000000,
    0b10000000,
    0b10000000,
    0b10000000
    
} ;

uint8_t SpriteSaucer[] = {
    0b00000000, 0b00000000,
    0b00000000, 0b01111110,
    0b00000001, 0b11111111,
    0b00000011, 0b11111111,
    0b00000110, 0b11011011,
    0b00001111, 0b11111111,
    0b00000011, 0b10011001,
    0b00000001, 0b00000000,

    0b00000000,
    0b00000000,
    0b10000000,
    0b11000000,
    0b01100000,
    0b11110000,
    0b11000000,
    0b10000000
} ;

uint8_t SpriteSaucerExp[] = {
    0b00010010, 0b10000001,
    0b00001000, 0b00000110,
    0b01010001, 0b11100011,
    0b00000011, 0b11111001,
    0b00000111, 0b01010100,
    0b00010001, 0b11110001,
    0b01000000, 0b10100011,
    0b00010001, 0b00010000,

    0b01001000,
    0b00010000,
    0b00000000,
    0b11001000,
    0b11100100,
    0b10000000,
    0b00010000,
    0b10000000

} ;

uint8_t ShotExploding[] = {
    0b10001001,
    0b00100010,
    0b01111110,
    0b11111111,
    0b11111111,
    0b01111110,
    0b00100100,
    0b10010001 
} ;

uint8_t AlienExplode[] = {
    0b00000100, 0b01000000,
    0b00100010, 0b10001000,
    0b00010000, 0b00010000,
    0b00001000, 0b00100000,
    0b01100000, 0b00001100,
    0b00001000, 0b00100000,
    0b00010010, 0b10010000,
    0b00100100, 0b01001000

} ;

uint8_t SquiglyShot[] = {
    0b01000000,
    0b10000000,
    0b01000000,
    0b00100000,
    0b01000000,
    0b10000000,
    0b01000000,
    0b00000000,
    
    0b10000000,
    0b01000000,
    0b00100000,
    0b01000000,
    0b10000000,
    0b01000000,
    0b00100000,
    0b00000000,
    
    0b01000000,
    0b00100000,
    0b01000000,
    0b10000000,
    0b01000000,
    0b00100000,
    0b01000000,
    0b00000000,
    
    0b00100000,
    0b01000000,
    0b10000000,
    0b01000000,
    0b00100000,
    0b01000000,
    0b10000000,
    0b00000000

} ;

uint8_t AShotExplo[] = {
    0b00100000,
    0b10001000,
    0b00110100,
    0b01111000,
    0b10111000,
    0b01111100,
    0b10111000,
    0b01010100

} ;

uint8_t PlungerShot[] = {
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b11100000,
    0b00000000,
    0b00000000,

    0b01000000,
    0b01000000,
    0b01000000,
    0b11100000,
    0b01000000,
    0b01000000,
    0b00000000,
    0b00000000,

    0b01000000,
    0b01000000,
    0b11100000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b00000000,
    0b00000000,

    0b11100000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b00000000,
    0b00000000

} ;

uint8_t RollShot[] = {
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b00000000,

    0b01000000,
    0b01000000,
    0b11000000,
    0b01100000,
    0b01000000,
    0b11000000,
    0b01100000,
    0b00000000,

    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b01000000,
    0b00000000,

    0b01100000,
    0b11000000,
    0b01000000,
    0b01100000,
    0b11000000,
    0b01000000,
    0b01000000,
    0b00000000

} ;
 
uint8_t AlienSprA[] = {
    0b00000011, 0b11000000,
    0b00011111, 0b11111000,
    0b00111111, 0b11111100,
    0b00111001, 0b10011100,
    0b00111111, 0b11111100,
    0b00000110, 0b01100000,
    0b00001101, 0b10110000,
    0b00110000, 0b00001100,

    0b00000011, 0b11000000,
    0b00011111, 0b11111000,
    0b00111111, 0b11111100,
    0b00111001, 0b10011100,
    0b00111111, 0b11111100,
    0b00001110, 0b01110000,
    0b00011001, 0b10011000,
    0b00001100, 0b00110000

} ;

uint8_t AlienSprB[] = {
    0b00000100, 0b00010000,
    0b00010010, 0b00100100,
    0b00010111, 0b11110100,
    0b00011101, 0b11011100,
    0b00011111, 0b11111100,
    0b00001111, 0b11111000,
    0b00000100, 0b00010000,
    0b00001000, 0b00001000,

    0b00000100, 0b00010000,
    0b00000010, 0b00100000,
    0b00000111, 0b11110000,
    0b00001101, 0b11011000,
    0b00011111, 0b11111100,
    0b00010111, 0b11110100,
    0b00010100, 0b00010100,
    0b00000011, 0b01100000

} ;

uint8_t AlienSprC[] = { 
    0b00000001, 0b10000000,
    0b00000011, 0b11000000,
    0b00000111, 0b11100000,
    0b00001101, 0b10110000,
    0b00001111, 0b11110000,
    0b00000010, 0b01000000,
    0b00000101, 0b10100000,
    0b00001010, 0b01010000,

    0b00000001, 0b10000000,
    0b00000011, 0b11000000,
    0b00000111, 0b11100000,
    0b00001101, 0b10110000,
    0b00001111, 0b11110000,
    0b00000101, 0b10100000,
    0b00001000, 0b00010000,
    0b00000100, 0b00100000

} ;

uint8_t AlienSprCYA[] = {
    0b00000000, 0b00110000,
    0b00010000, 0b01111000,
    0b00010000, 0b11111100,
    0b00011101, 0b10110110,
    0b00010011, 0b11111110,
    0b00101000, 0b10110100,
    0b01000101, 0b00000010,
    0b01000100, 0b10000100

};

uint8_t AlienSprCYB[] = {
    0b00000000, 0b00110000,
    0b00001000, 0b01111000,
    0b00001000, 0b11111100,
    0b00001101, 0b10110110,
    0b00001011, 0b11111110,
    0b00010100, 0b01001000,
    0b00100010, 0b10110100,
    0b00100011, 0b01001010

};

uint8_t AlienSprCA[] = {
    0b00000000, 0b00110000,
    0b10001000, 0b01111000,
    0b10001100, 0b11111100,
    0b01010111, 0b10110110,
    0b00100011, 0b11111110,
    0b00100000, 0b10110100,
    0b00100001, 0b00000010,
    0b00100000, 0b10000100

};

uint8_t AlienSprCB[] = {
    0b00000000, 0b00110000,
    0b01000100, 0b01111000,
    0b01000110, 0b11111100,
    0b00101011, 0b10110110,
    0b00010011, 0b11111110,
    0b00010000, 0b01001000,
    0b00010000, 0b10110100,
    0b00010001, 0b01001010

};

uint8_t DeleteTopAlien[] = {
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000    
} ;

uint8_t DeleteSprite16[] = {
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,

    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000,
    0b00000000    
} ;

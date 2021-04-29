#ifndef __SCREENS_H
#define __SCREENS_H

extern int8_t currentMenuScreen;

extern void DrawScreenColors();
extern void DrawCredits();
extern void DrawScoreHeaderAndCredits();
//extern int8_t animateSpriteX( int y, int from_x, int to_x, int8_t deltax, uint8_t * sprite1, uint8_t * sprite2 );
//extern int8_t animateAlienShot( int x, int from_y, int to_y, uint8_t * sprite );
extern int8_t animateAlienCY();
extern int8_t scoreTable_Screen( int8_t invertY );
extern int8_t inserCoin_Screen( int8_t extraC );
extern int8_t inserCoin_ScreenC();
extern void pushPlayerButton_Screen();
extern int8_t setup_Screen();
extern int8_t help_Screen();

#endif

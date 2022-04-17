#ifndef __INPUT_H
#define __INPUT_H

/* ********************************************* */
/* Input */

union _input {
    uint8_t pulsed;
    struct {
        uint8_t moveLeft:1;
        uint8_t moveRight:1;
        uint8_t shot:1;
    };
};

extern union _input input;

/* ********************************************* */

union _syskey {
    uint8_t keyPressed;
    struct {
        uint8_t keyCredit           :1;
        uint8_t keyStart1UP         :1;
        uint8_t keyStart2UP         :1;
        uint8_t showSetup           :1;
        uint8_t showHelp            :1;
#ifdef __ZXN__
        uint8_t showIntro           :1;
#endif
    };
};

extern union _syskey syskey;

/* ********************************************* */

extern void InputDetect();

extern void readInput();
extern void readSysKeys();

/* ********************************************* */

#endif

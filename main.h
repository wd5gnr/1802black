#ifndef __MAIN_H
#define __MAIN_H



int freeRam(void);
void interpretkeys(void);
void setupUno(void);
uint8_t xkeyPressed(void);
void scanKeys(void);
void driveLEDs(void);
void setaddress(uint16_t a);
void setdata(uint8_t d);
void setdp(int pos, int state);
int Serialread(int echo = 1);  // read and echo
void serputc(int c);  // put a character out the serial port

#define KEY_RS 'R'
#define KEY_AD '='
#define KEY_DA 'L'
#define KEY_GO 'G'
#define KEY_PC 'P'
#define KEY_ST 'S'
#define KEY_SST '/'

extern char threeHex[3][2];

// There is a problem with the CDC code that requires a short
// delay after sending or you will eventually get random drops 
// when transmittting a lot of data (10 is too low, 50 seems to work)
  #define SERIAL_DELAY delayMicroseconds(50);


#endif

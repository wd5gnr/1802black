// This is mostly Oscar's original KIM UNO code
// Modified by Al Williams for use as an 1802
// For the most part I just hacked away the parts specific to the KIM
// I did add code to the display part to take care of the decimal points
// in the hex out code, and added a few defines and a header.
// But for the most part, all of this code is straight out of the KIM Uno.

// Original version:
// version date: 20160907
#include <stdint.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>  // need atoi

#include "main.h"
#include "1802.h"

#define VERSION "1802PCv1"

#define SERIAL_ESCAPE '|' // turn terminal input into real terminal input

uint8_t curkey = 0;

int autostart = 1;

void serputc(int c)
{
  putchar(c); 
}

// get and clear a key (from original code)
uint8_t getAkey(void)
{
  return (curkey);
}
void clearkey(void)
{
  curkey = 0;
}



// tick counter for display updates
uint8_t tick = 0;

int romsel = 0;


// Set up everything

void setup()
{
  fprintf(stderr,"Wait\r\n");
  set_conio_terminal_mode();
  // read switches
  initRom(romsel);

  setupUno();
 // RTCStart();  // start real time clock
  reset();     // 1802 reset
  fprintf(stderr,"%s\r\n",VERSION);

  if (autostart)
  {
      fprintf(stderr,"%s\r\n", "Autostart");
      exec1802(KEY_GO);
      noserial = 1;
  }
}

// read serial with or without echo
int Serialread(int echo)
{
  int curkey;
  curkey = getch();
  if (curkey > 0 && echo)
    putchar(curkey);
  return curkey;
}

#include <sys/ioctl.h>
int serial_avail()
{
  return kbhit();
}

// main loop
void loop()
{
  if (noserial == 0 && serial_avail()) // if serial input, process that
  {
    curkey = getchar();
    if (curkey == SERIAL_ESCAPE)
       noserial = 1; // one way ticket
    else
      exec1802(curkey);
    curkey = 0;
  }
  exec1802(0);
  tick++;
}


// =================================================================================================
// KIM Uno Board functions are bolted on from here
// =================================================================================================

void setupUno()
{

}

#include <getopt.h>

int main(int argc, char *argv[])
{
  int c;
  while ((c = getopt(argc,argv,"ar:?"))!=-1)
  {
    switch(c)
    {
      case 'a':
        autostart = 0;
        break;
      case 'r':
        romsel = atoi(optarg);
        break;
      case '?':
        printf("Help goes here\r\n");
        break;
      }
  }
    setup();
  while (1)
    loop();
}
void setaddress(unsigned short) {}
void setdata(unsigned char) {}
void setdp(int, int) {}

#include "pceeprom.h"

void NVM_PutChecksum(uint16_t csum)
{
    EEPROM.write(112, csum &0xFF);
    EEPROM.write(113, csum >> 8);
    EEPROM.commit(); // we always change checksum, so...
}

uint16_t NVM_GetChecksum(void)
{
    uint16_t v;
    v=EEPROM.read(112);
    v |= EEPROM.read(113) << 8;
    return v;
}

uint16_t NVM_Checksum()
{
    int i;
    unsigned csum = 0;
    for (i = 0; i < 114-2;i++) 
        {
            unsigned b = EEPROM.read(i);
            csum += b;
            if (csum>0xFFFF)
                csum++;
            csum <<= 1;
            csum &= 0xFFFF;
        }
        return csum;
}


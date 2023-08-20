 
#include <Arduino.h>
#include "USBSerial.h"

// This works for the 1802 part but for some reason all the Print functions do not use the single character write
// adding a write(buffer, size) override brings everything to a halt
// So we have to convert the buffered writes into different kind of buffered write :( )

/*
So this is a huge hack. The CDC port occasionally chokes on send when sending/receiving fast and just checking to see if it is ready is not sufficient.

If the USB stack were right you shouldn't need this but it looks like you get some race where you enter the API before it
reports not ready or it is still cleaning up from the last call.

Touching anything in here is likely to break it in an hard to find way. I have been testing with a 6K hex file loaded into the monitor.
That's 6K in an Intel Hex file so the file >> 6K itself.

Also anything that writes up the stack is likely to cause failures too.

1/500 seems to work well. 1/1 does not work well.

The problem was exacerbated by a bad cable, but even with a good cable there are random failures with the default setup.


*/

#define DELAY1  1     // uS between characters
#define DELAY2  500   // uS between lines

#define SERIAL_DELAY delayMicroseconds(DELAY1) 

class CDCSerial : public USBSerial
{
protected:
  void waitReady(void);
  size_t writeBuffer(const uint8_t *buffer, size_t size);
public:
  size_t write(char c) { return write((uint8_t) c); }  // do not remove
  size_t write(uint8_t c) { return write(&c,1); }
  size_t write(const uint8_t *buffer, size_t size);
};



#ifndef DEF_CDCSERIAL
extern
#endif
   CDCSerial Serial;


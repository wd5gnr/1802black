
  #include "cdcserial.h"
  
  
  void CDCSerial::waitReady(void)
  {
   while (!availableForWrite()) SERIAL_DELAY;  // do not remove delay
  }


  size_t CDCSerial::writeBuffer(const uint8_t *buffer, size_t size)
  {
     waitReady();    // do not remove
      SERIAL_DELAY;  // appears to be necessary
      size_t rv=USBSerial::write(buffer,size);
    //  SERIAL_DELAY;  // seems unnecessary
    //  waitReady();  // seems unnecessary
      return rv;
  }

 

 // This is seriously broken. Calling write(uint8_t) from write(uint8_t *) breaks everything so...
 // The issue turns out be the availability of the serial port. Apparently writing a buffer just blows
 // out everything and if the port isn't ready in the middle, tough.



  size_t CDCSerial::write(const uint8_t *buffer, size_t size)
  {
    size_t rvt=0;
    while (size)
    {
      size_t rv=writeBuffer(buffer,1);
      if (!rv) return rvt;
     // flush();    // not sure if it is better to flush lines or characters but probably doesn't help either way
      if (*buffer=='\r'||*buffer=='\n') { /* flush(); */ delayMicroseconds(DELAY2); }  
      rvt++;
      size--;
      buffer++;
    }
    return rvt;
  }

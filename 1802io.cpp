#include <Arduino.h>
#include "1802.h"
#include "main.h"  // need Serialread



volatile int brkflag = 0;
 


uint8_t inp_serial(void)
{
  int rv=Serialread();
  return rv==-1?0:rv;
}

uint8_t inp_data(void)
{
  return idata;
}

uint8_t inp_temp(void)
{
  float f = analogReadTemp();
  return (unsigned int)f;
}

void out_serial(uint8_t v)
{
  serputc(v);
}

void out_data(uint8_t v)
{
  data=v;
}

void out_a0(uint8_t v)
{
  adlow=v;
}

void out_a1(uint8_t v)
{
  adhigh=v;
}

void out_ctl(uint8_t v)
{
  noserial=v&1;      // set 1 to use serial port as I/O instead of front panel
  addisp=(v&2)==2;  // set bit 1 to use address displays
}

uint8_t (*inputfn[])(void) =
    {
        inp_serial,
        inp_data,
        inp_temp
    };

void (*outputfn[])(uint8_t) =
    {
      out_serial,
      out_data,
      out_a0,
      out_a1,
      out_ctl
    };

uint8_t io_read_key(uint8_t key)
{
  switch (key)
  {
    case 0:
      return brkflag;
    case 1:
      {
        uint8_t v = brkflag;
        brkflag = 0;
        return v;
      }
    default:
      return 0;
    }
}



uint8_t (*inputmap[])(void) =
{
  inp_serial,
  inp_data,
  inp_data,
  inp_data,
  inp_data,
  inp_data,
  inp_temp
};

void (*outputmap[])(uint8_t ) =
{
  out_serial,
  out_a0,
  out_a1,
  out_data,
  out_data,
  out_data,
  out_ctl
};

void io_write_key(uint8_t key, uint8_t val)
{
  unsigned p, idx;
  switch (key) {
  case 0:
    p = val >> 5; // 0-7 were 0 is port 1
    idx = val & 0x1F; // index
    inputmap[p] = inputfn[idx];

    break;

case 1:
    p = val >> 5; // 0-7 were 0 is port 1
    idx = val & 0x1F; // index
    outputmap[p] = outputfn[idx];
    break;
  }

}


// Input from any port gives you the data register
// except port 1 is serial input
uint8_t input(uint8_t port) {
  return inputmap[port-1]();
}

// Output to any port writes to the data display
void output(uint8_t port, uint8_t val) {
   outputmap[port-1](val);
}

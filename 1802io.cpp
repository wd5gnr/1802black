#include <Arduino.h>
#include "1802.h"
#include "main.h"  // need Serialread


uint8_t inp_serial(void)
{
  int rv=Serialread();
  return rv==-1?0:rv;
}

uint8_t inp_data(void)
{
  return idata;
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


uint8_t io_read_key(uint8_t key)
{
  return 0;
}

void io_write_key(uint8_t key, uint8_t val)
{
  // nothing yet
}


uint8_t (*inputmap[])(void) =
{
  inp_serial,
  inp_data,
  inp_data,
  inp_data,
  inp_data,
  inp_data,
  inp_data
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

// Input from any port gives you the data register
// except port 1 is serial input
uint8_t input(uint8_t port) {
  return inputmap[port-1]();
}

// Output to any port writes to the data display
void output(uint8_t port, uint8_t val) {
   outputmap[port-1](val);
}

#include <Arduino.h>
#include "vt100.h"

void VT100::cls(void)
{
    Serial.print("\e[2J");
}

void VT100::save(void)
{
    Serial.print("\e[s");
}

void VT100::unsave(void)
{
    Serial.print("\e[u");
}

void VT100::gotorc(unsigned r, unsigned c)
{
    Serial.printf("\e[%d;%df", r, c);
}

void VT100::clreol(void)
{
    Serial.print("\e[K");
}

void VT100::clreos(void)
{
    Serial.print("\e[J");
}


#include "pceeprom.h"

_EEPROM EEPROM;

_EEPROM::_EEPROM(const char *eename)
{
    fp = fopen(eename, "r+");
    if (!fp)
    {
        fp=fopen(eename, "w+");
        for (int i = 0; i < 512;i++)
            putc(0xFF, fp);
    }
    if (!fp)
        printf("ERROR: EEPROM File can't open\n");
}

uint8_t _EEPROM::read(uint16_t address)
{
    if (!fp)
        return 0xFF;
    fseek(fp, address, SEEK_SET);
    return fgetc(fp);
}

void _EEPROM::write(uint16_t address, uint8_t byte)
{
    if (fp)
    {
        fseek(fp, address, SEEK_SET);
        fputc(byte, fp);
    }
}

void _EEPROM::commit(void)
{
    if (fp)
    {
        fflush(fp);
    }
}
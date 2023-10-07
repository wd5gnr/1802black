#include <Arduino.h>
#include "1802.h"
#include "main.h"

void printreg(uint8_t code)
{
    code &= 0xF;
    Serial.print("\tR");
    if (code <= 9)
        code += '0';
    else
        code += 'A' - 10;
    Serial.print((char)(code));
}

// Table for Branch opcodes (0x3x)
char brtable[] = {'R', 'Q', 'Z', 'F', '1', '2', '3', '4'};

void ophex(uint8_t opcode, unsigned a)
{
    int ct = 0, extra;
    if (((opcode&0xF0)==0x30)&&opcode!=38)
        ct = 1;
    if (opcode==0x7C||opcode==0x7D||opcode==0x7F)
        ct = 1;
    if (opcode>=0xC0&&opcode<=0xC3)
        ct = 2;
    if (opcode>=0xc9&&opcode<=0xCB)
        ct = 2;
    if (opcode>=0xF8 && opcode!=0xFE)
        ct = 1;
    if (opcode==0xD4)
        ct = 2;  // fake CALL SEP        
    print2hex(opcode, 0);
    Serial.print(' ');
    extra = ct;
    while (extra--)
    {
        a++;
        print2hex(memread(a));
        if (extra)
            Serial.print(' ');
    }
    if (ct!=2)
        Serial.print('\t');
    Serial.print('\t');
}

unsigned opcode(uint8_t opcode, unsigned a)
{
    unsigned skip = 0;
    ophex(opcode, a);
    switch (opcode & 0xF0)
    {
    case 0:
        if (opcode == 0)
        {
            Serial.print("IDL");
            return 0;
        }
        Serial.print("LDN");
        printreg(opcode);
        return 0;

    case 0x10:
        Serial.print("INC");
        printreg(opcode);
        return 0;

    case 0x20:
        Serial.print("DEC");
        printreg(opcode);
        return 0;

    case 0x30:
        if (opcode == 0x38)
        {
            Serial.print("SKP");
            return 0;
        }
        Serial.print("B");
        if (opcode > 0x38)
            Serial.print("N");
        if (opcode == 0x33)
            Serial.print("D");
        Serial.print(brtable[opcode & 0x7]);
        //Serial.printf("\t%02X", memread(a + 1));
        print2hex(memread(a + 1), 1);
        return 1;
    case 0x40:
        Serial.print("LDA");
        printreg(opcode);
        return 0;

    case 0x50:
        Serial.print("STR");
        printreg(opcode);
        return 0;

    case 0x60:
        if (opcode == 0x68)
        {
            Serial.print("ILL");
            return 0;
        }
        if (opcode > 0x68)
            Serial.print("INP");
        else
            Serial.print("OUT");
        Serial.print((char)((opcode & 0x7) + '0'));
        return 0;
    case 0x70:
        switch (opcode)
        {
        case 0x70:
            Serial.print("RET");
            return 0;
        case 0x71:
            Serial.print("DIS");
            return 0;
        case 0x72:
            Serial.print("LDXA");
            return 0;
        case 0x73:
            Serial.print("STXD");
            return 0;
        case 0x74:
            Serial.print("ADC");
            return 0;
        case 0x75:
            Serial.print("SDB");
            return 0;
        case 0x76:
            Serial.print("SHRC");
            return 0;
        case 0x77:
            Serial.print("SMB");
            return 0;
        case 0x78:
            Serial.print("SAV");
            return 0;
        case 0x79:
            Serial.print("MARK");
            return 0;
        case 0x7A:
            Serial.print("REQ");
            return 0;
        case 0x7B:
            Serial.print("SEQ");
            return 0;
        case 0x7C:
            Serial.print("ADCI");
            print2hex(memread(a + 1), 1);
            return 1;
        case 0x7D:
            Serial.print("SDBI");
            print2hex(memread(a + 1), 1);
            return 1;
        case 0x7E:
            Serial.print("SHLC");
            return 0;
        case 0x7F:
            Serial.print("SMBI");
            print2hex(memread(a + 1), 1);
            return 1;
        }
        break;
    case 0x80:
        Serial.print("GLO");
        printreg(opcode);
        return 0;

    case 0x90:
        Serial.print("GHI");
        printreg(opcode);
        return 0;

    case 0xA0:
        Serial.print("PLO");
        printreg(opcode);
        return 0;

    case 0xB0:
        Serial.print("PHI");
        printreg(opcode);
        return 0;
    case 0xC0:
        if ((opcode < 0xC4 || opcode > 0xC8) && opcode < 0xCC)
        {
            if (opcode == 0xC0)
                Serial.print("LBR");
            if ((opcode & 0x3) == 1)
                Serial.print((opcode & 8) ? "LBNQ" : "LBQ");
            if ((opcode & 0x3) == 2)
                Serial.print((opcode & 8) ? "LBNZ" : "LBZ");
            if ((opcode & 0x3) == 3)
                Serial.print((opcode & 8) ? "LBNF" : "LBDF");
            print4hex((memread(a + 1) << 8) | memread(a + 2),1);
            return 2;
        }
        if (opcode == 0xC4)
        {
            Serial.print("NOP");
            return 0;
        }
        if (opcode == 0xCC)
        {
            Serial.print("LSIE");
            return 0;
        }
        if ((opcode & 0x7) == 5)
        {
            Serial.print((opcode & 8) ? "LSQ" : "LSNQ");
            return 0;
        }
        if ((opcode & 0x7) == 6)
        {
            Serial.print((opcode & 8) ? "LSZ" : "LSNZ");
            return 0;
        }
        if ((opcode & 0x7) == 7)
        {
            Serial.print((opcode & 8) ? "LSDF" : "LSNF");
            return 0;
        }

        break;
    case 0xD0:
        if (opcode==0xD4)
        {
            // fake opcode for call
            Serial.print("CALL");
            print4hex((memread(a + 1) << 8) | memread(a + 2),1);
            return 2;
        }
        if (opcode==0xD5)
        {
            // fake opcode for return
            Serial.print("RTN");
            return 0;
        }
        Serial.print("SEP");
        printreg(opcode);
        return 0;
    case 0xE0:
        Serial.print("SEX");
        printreg(opcode);
        return 0;

    case 0xF0:
    {
        int off = 0;
        const char *cs;

        switch (opcode)
        {

        case 0xF0:
            cs = "LDX";
            break;

        case 0xF1:
            cs = "OR";
            break;

        case 0xF2:
            cs = "AND";
            break;

        case 0xF3:
            cs = "XOR";
            break;

        case 0xF4:
            cs = "ADD";
            break;
        case 0xF5:
            cs = "SD";
            break;
        case 0xF6:
            cs = "SHR";
            break;
        case 0xF7:
            cs = "SM";
            break;
        case 0xF8:
            cs = "LDI";
            off = 1;
            break;
        case 0xF9:
            cs = "ORI";
            off = 1;
            break;
        case 0xFA:
            cs = "ANI";
            off = 1;
            break;
        case 0xFB:
            cs = "XRI";
            off = 1;
            break;
        case 0xFC:
            cs = "ADI";
            off = 1;
            break;
        case 0xFD:
            cs = "SDI";
            off = 1;
            break;
        case 0xFE:
            cs = "SHL";
            break;
        case 0xFF:
            cs = "SMI";
            off = 1;
            break;
        }  // end switch
        Serial.print(cs);
        if (off)
            print2hex(memread(a + 1), 1);
        return off;
    }  // end outer switch
    }
    return 0;
}

unsigned disasmline(unsigned mp, int nl)
{
    unsigned rv;
    print4hex(mp);
    Serial.print('\t');
    rv = opcode(memread(mp), mp);
    if (nl) Serial.println();
    return rv;
}

unsigned disasm1802(unsigned start, unsigned stop)
{
    unsigned mp;
    for (mp = start; mp <= stop; mp++)
    {
        if (mp < start)
            return 0; // strange wrap around
        mp+=disasmline(mp,1);
    }
    return mp;
}
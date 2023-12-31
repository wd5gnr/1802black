#include <Arduino.h>
#include "1802.h"
#include "main.h"
#if MONITOR == 1
#include <EEPROM.h>
#include <LittleFS.h>
#include <cstdio>
#include <cstring>
#include "vt100.h"

/*
Commands:

R - Display all registers
R2 - Display register 2
R2=AA - Set register 2 to AA

Note: X=10, P=11, D=12, DF=13, Q=14, and T=15 -- display all registers to see that list

M 400 - Display 100 hex bytes at 400
M 400 10 - Display 10 hex bytes at 400
M 400=20 30 40; - Set data starting at 400 (end with semicolon)

Note that you can use the first line with full backspace:
M 400=20 30 40;

But if you start a new line (you get a colon prompt), you will not be able to backspace past the current byte:

M 400=
: 20 30 40
: 50 60 70;

Backing up while entering 30 can only delete the 30 and not the 20. Also, instead of backing up you can just keep going
as in:

:M 400=
: 200 300 400;

All 3 bytes will then be zero.

G 400 - Goto 400
G 400 3 - Goto 400 with P=3

B - List all enabled breakpoints
B0 - - Disable Breakpoint 0 (that is a dash as in B0 -)
BF @200 - Set breakpoint F to address 200
BF P3 - Set breakpoint when P=3
BF I7A - Set breakpoint when instruction 7A executes

Note would be possible to do data write (or even read) breakpoints
Would also be possible to do ranges of addresses, if desired

N - Execute next instruction


I 2 - Show input from N=2
O 2 10 - Write 10 to output N=2

Note: The keypad and display are dead while the monitor is in control

X - Exit to front panel mode (not running)

C - Exit and continue running (if already running)
Q - Same as C

.+ - Send next character(s) to the front panel interpreter (no spaces)

*/

// one problem: The Blackpill serial port is terrible at dropping characters at high throughput
// But we can't use the same delay trick here without rewriting every Serial.xxx call
// So you will occasionally lose characters when flooding data from an M or R command, for example

static char cmdbuf[33];
static int cb;

static int cmd;       // command
static uint16_t arg;  // one argument
static int terminate; // termination character
static int noread;

#ifdef METAMON_VISUAL_NODEF
int visualmode = 0;
#else
int visualmode = 1;
#endif

// generic sector buffer
uint8_t sbuf[512];

int monactive = 0;

int getch(void)
{
  int c;
  int ctr = 0;
  do
  {
    c = Serialread();
    if (c == -1)
    {
      if (++ctr % DISPLAY_DIVISOR == 0)
      {
        updateLEDdata();
        driveLEDs();
        scanKeys();
        ctr = 0;
      }
    }

  } while (c == -1);
  return c;
}

// This skips leading blanks, makes all internal whitespace one space, and trims trailing blanks
// This is very important since some of the parsing assumes there will be 0 or 1 space but no more
// and no tabs etc.

uint8_t readline(int *terminate)
{
  int c;
  cb = 0;
  cmdbuf[0] = '\0';
  while (1)
  {
    c = getch();
    if (c == '\r')
    {
      if (terminate)
        *terminate = '\r';
      while (cb && cmdbuf[cb - 1] == ' ')
        cb--;
      cmdbuf[cb] = '\0';
      if (cb)
        cb = 1;
      return *cmdbuf;
    }
    if (c == 0x1b)
    {
      cmdbuf[0] = '\0';
      cb = 0;
      if (terminate)
        *terminate = 0x1b;
      return '\0';
    }
    if (c == 0x7F || c == 0xFF)
      c = 8;
    if (c == 8 && cb != 0)
    {
      cb--;
      continue;
    }
    if (cb > sizeof(cmdbuf) - 2)
    {
      Serial.print('\x7'); // sound bell
      continue;
    }

    if (isspace(c) && cb == 0)
      continue;
    if (cb && isspace(c) && cmdbuf[cb - 1] == ' ')
      continue;
    else if (isspace(c))
      c = ' ';
    cmdbuf[cb++] = toupper(c);
  }
}

uint16_t readhexX(int (*getcfp)(void), int *term, uint16_t def = 0xFFFF)
{
  uint16_t val = def;
  int first = 1;
  int c;

  while (1)
  {
    c = getcfp();
    if (!isxdigit(c) && c != 8)
    {
      if (first && c != '\r' && c != ';' && c != 0x1b)
        continue;
      if (term)
        *term = c;
      noread = first;
      return val;
    }
    if (c == 8)
    {
      val >>= 4; // in case of serial input
      continue;
    }
    c = toupper(c);
    if (first)
      val = 0;
    else
      val <<= 4;
    first = 0;
    if (c >= 'A')
      c = c - 'A' + 10;
    else
      c -= '0';
    val += c;
  }
}

uint16_t readhex(int *term, uint16_t def = 0xFFFF)
{
  return readhexX(getch, term, def);
}

int getbufc(void)
{
  if (cmdbuf[cb] == '\0')
    return '\r';
  return cmdbuf[cb++];
}

uint16_t readhexbuf(int *term, uint16_t def = 0xFFFF)
{
  return readhexX(getbufc, term, def);
}

int diskcfm(void)
{
  Serial.println("\r\nY to proceed, N to abort? ");
  int n = getch();
  return (n == 'y' || n == 'Y');
}

// Super crummy disk monitor to troubleshoot/format/set disk stuff
void diskmon(void)
{
  char diskcmd[128];
  if (diskinit)
    LittleFS.end();
  Serial.printf("Init %d\r\n", LittleFS.begin());
  diskinit = 1;
  while (1)
  {
    Serial.println(F("Host disk menu (arguments in hex)"));
    Serial.println(F("S - set max 'track' count: S [max#]\r\n"
                     "D - Directory\r\n"
                     "F - Format (will ask for confirmation)\r\n"
                     "R - read sectors from 1st 'track': R [sector] [count]\r\n"
                     "> - Write disk out in exchange format\r\n"
                     "< - Read disk in from exchange format\r\n"
                     "X - eXit"));
    int n = readline(NULL);
    n = toupper(n);
    switch (n)
    {
    case 'X':
      diskinit = false;
      LittleFS.end();
      diskinit = 0;
      return;
    case 'R':
    {
      int n1, n2;
      n1 = readhexbuf(NULL, 0);
      n1 *= 512;
      n2 = readhexbuf(NULL, 1);
      File f = LittleFS.open("/ide00A.dsk", "r");
      if (!f)
      {
        Serial.println("Faled open\r\n");
        break;
      }
      Serial.printf("Opened /ide0.dsk\r\n");
      Serial.printf("Seeking %d %d\r\n", n1, f.seek(n1, SeekSet));
      uint8_t sector[512];
      int i;
      for (i = 0; i < n2; i++)
      {
        Serial.printf("\r\nRead: %d\r\n", f.read(sector, sizeof(sector)));
        for (int j = 0; j < 512; j++)
        {
          Serial.printf("%02x ", sector[j]);
        }
        Serial.println();
      }
      f.close();
    }
    break;
    case 'F':
      if (diskcfm())
        Serial.println(LittleFS.format());
      break;

    case '>':
    {
      unsigned i;
      int rv;
      uint16_t c = 0;
      uint8_t s = 0;
      if (reset_ide())
      {
        Serial.println("Can't reset disk");
        break;
      }
      Serial.printf("!DISK1:%04X:", MAXCYL);
      do
      {
        rv = read_mide(sbuf, 0, c, s);
        if (!rv)
        {
          for (i = 0; i < sizeof(sbuf); i++)
          {
            Serial.printf("%02X", sbuf[i]);
            if (((i + 1) % 16) == 0)
              Serial.println();
          }
          s++;
          if (!s)
            c++;
        }
      } while (rv == 0);
      Serial.println("EOF");
    }
    break;
    case '<':
    {
      uint16_t c = 0;
      uint8_t s = 0;
      unsigned i;
      int rv;
      char inbuf[3];
      File f;
      if (!diskcfm())
        break;
      // read header or error
      while (getch() != '!')
        ;
      if (getch() != 'D' || getch() != 'I' || getch() != 'S' || getch() != 'K')
      {
        Serial.println("Invalid file format");
        break;
      }
      if (getch() != '1' || getch() != ':')
      {
        Serial.printf("Bad file version\r\n");
        break;
      }
      // set MAXCYL
      sbuf[0] = getch();
      sbuf[1] = getch();
      sbuf[2] = getch();
      sbuf[3] = getch();
      ;
      sbuf[4] = '\0';
      if (sscanf((char *)sbuf, "%04X", &rv) != 1)
      {
        Serial.println("Misformed file");
        break;
      }
      MAXCYL = rv;
      getch(); // better be a colon but not checked
      reset_ide();
      i = 0;
      while (1)
      {
        if (i == sizeof(sbuf))
        {
          i = 0;
          rv = write_mide(sbuf, 0, c, s);
          s++;
          if (s == 0)
            c++;
        }
        // read bytes
        inbuf[0] = getch();
        // on CRLF issue Prompt ]
        if (inbuf[0] == '\r' || inbuf[0] == '\n')
        {
          Serial.write(']');
          continue;
        }
        inbuf[1] = getch();
        if (inbuf[0] == 'E' && inbuf[1] == 'O')
        {
          // end of file
          // we assume the sender did not send
          // an odd number of bytes so...
          Serial.println("Complete");
          break;
        }
        inbuf[2] = '\0';
        sscanf(inbuf, "%X", &rv);
        sbuf[i++] = rv;
      }
      reset_ide();
    }
    break;
    case 'D':
    {
      Dir dir = LittleFS.openDir("/");
      while (dir.next())
        Serial.println(dir.fileName());
    }
    break;
    case 'S':
    {
      int n;
      EEPROM.write(MAXCYLEE, EEPROMSIG);
      EEPROM.write(MAXCYLEE + 1, n = readhexbuf(NULL, 0x10));
      Serial.printf("Set max cylinder to %d (0x%x)\r\n", n, n);
      break;
    }

    default:
      Serial.println("?");
    }
  }
}

BP bp[16];

void dispbp(int bpn, int nl = 1)
{
  if (nl)
    Serial.print("\r\n");
  Serial.print(F("BP"));
  Serial.print(bpn, HEX);
  Serial.print(F(": "));
  if (bp[bpn].type == 1)
    Serial.print(F("@"));
  if (bp[bpn].type == 2)
    Serial.print(F("P"));
  if (bp[bpn].type == 3)
    Serial.print(F("I"));
  if (bp[bpn].type == 0)
    Serial.print(F(" DISABLED"));
  else
    print4hex(bp[bpn].target);
}

int nobreak;

char viscmd = ' ';
char vishlp;
uint16_t visadd = 0;
uint16_t visnext = 0;

uint16_t watch[4];
uint8_t watchon[4] = {0, 0, 0, 0};

void reg_dump(void)
{
  int i, j;
  for (i = 0; i <= 15; i += 4)
  {
    Serial.print(F("R"));
    Serial.print(i, HEX);
    Serial.print(':');
    print4hex(reg[i]);
    Serial.print(F("\tR"));
    Serial.print(i + 1, HEX);
    Serial.print(':');
    print4hex(reg[i + 1]);
    Serial.print(F("\tR"));
    Serial.print(i + 2, HEX);
    Serial.print(':');
    print4hex(reg[i + 2]);
    Serial.print(F("\tR"));
    Serial.print(i + 3, HEX);
    Serial.print(':');
    print4hex(reg[i + 3]);
    if (watchon[i / 4])
    {
      Serial.print("\t\tW@");
      print4hex(watch[i / 4]);
      Serial.print('=');
      for (j = 0; j < 8; j++)
        print2hex(memread(watch[i / 4] + j));
    }
    Serial.println();
  }
  Serial.print(F("(10) X:"));
  Serial.print(x, HEX);
  Serial.print(F("\t(11) P:"));
  Serial.println(p, HEX);
  Serial.print(F("(12) D:"));
  print2hex(d);
  Serial.print(F("\t(13) DF:"));
  Serial.println(df, HEX);
  Serial.print(F("(14) Q:"));
  Serial.print(q, HEX);
  Serial.print(F("\t(15) T:"));
  Serial.println(t, HEX);
}

// dump printable characters
static void adump(unsigned a)
{
  int z;
  Serial.print(F("  "));
  for (z = 0; z < 16; z++)
  {
    char b = memread(a + z);
    if (b >= ' ')
      Serial.print(b);
    else
      Serial.print('.');
  }
}

void mem_dump(uint16_t arg, uint16_t limit)
{
  uint16_t i;
  unsigned ct = 16;
  Serial.print(F("       0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F"));
  for (i = arg; i <= limit; i++)
  {
    if (ct % 16 == 0)
    {
      if (ct != 16)
        adump(i - 16);
      Serial.println();
      print4hex(i);
      Serial.print(F(": "));
    }
    else if (ct % 8 == 0)
      Serial.print(' ');
    ct++;

    print2hex(memread(i));
    Serial.print(' ');
    if (i == 0xFFFF)
      break; // hit limit
    if (Serialread() == 0x1b)
      break;
  }
  adump(i - 16);
}

void bp_dump()
{
  int i;
  for (i = 0; i < sizeof(bp) / sizeof(bp[0]); i += 2)
  {
    dispbp(i, i != 0);
    Serial.print('\t');
    dispbp(i + 1, 0);
  }
  Serial.println();
}

void do_line(int nl = 0)
{
  for (int i = 0; i < 70; i++)
    Serial.print('-');
  if (nl)
    Serial.println();
}

#include "metahelp.h"

void visual_mon_status()
{
  uint16_t a;
  VT100::cls();
  VT100::gotorc(1, 1);
  reg_dump();
  do_line(1);
  if (viscmd == '?')
  {
    do_help(vishlp);
  }
  if (viscmd == 'B')
  {
    bp_dump();
  }
  if (viscmd == 'D')
  {
    a = visadd;
    for (int i = 0; i < 9; i++)
    {
      a = a + disasmline(a, 1) + 1;
    }
    visnext = a;
  }
  if (viscmd == 'M')
  {
    uint16_t a = visadd & 0xFFF0;
    mem_dump(a, a + 0x7F);
  }
  VT100::gotorc(18, 1);
  do_line(1);
  a = reg[p];
  for (int j = 0; j < 3; j++)
  {
    a += disasmline(a, j != 0) + 1;
    if (j == 0)
      Serial.printf("\tD=%02X <===\r\n", d);
  }
  do_line(1);
}

void mon_status(void)
{
  if (visualmode)
    visual_mon_status();
  else
  {
    disasmline(reg[p], 0);
    Serial.printf("\tD=%02X <==\r\n", d);
  }
}

bool enterMonitor(void)
{
  static int throttle = 0; // the BOOT button is slow so we throttle and only check every 256 instructions
  if (monactive)
    return true;
#if MONITORPIN >= 0
  return digitalRead(MONITORPIN) == 0;
#else
  if (++throttle < 256)
    return false;
  throttle = 0;
  return get_bootsel_button();
#endif
}

int mon_checkbp(void)
{
  int i;
  int mon = enterMonitor();
  if (nobreak && !mon)
    return 1;
  if (!nobreak)
    for (i = 0; i < sizeof(bp) / sizeof(bp[0]); i++)
    {
      if (bp[i].type == 0)
        continue;
      else if (bp[i].type == 1 && bp[i].target == reg[p])
        mon = 1;
      else if (bp[i].type == 2 && bp[i].target == p)
        mon = 1;
      else if (bp[i].type == 3 && bp[i].target == memread(reg[p]))
        mon = 1;
    }
  if (mon)
  {
    Serial.println(F("\nBreak"));
    mon_status();
    return monitor();
  }
  return 1;
}

int monitor(void)
{
  int noarg;
  if (monactive == 0 && visualmode)
    visual_mon_status();
  monactive = 1;
  while (1)
  {
    if (visualmode)
    {
      VT100::gotorc(24, 1);
      VT100::clreol();
      Serial.print(F("(? help; v toggle fullscreen)>"));
    }
    else
      Serial.print(F("\r\n>"));
    cmd = readline(&terminate);
    if (visualmode)
    {
      visual_mon_status();
      VT100::gotorc(23, 1);
      VT100::clreos();
      Serial.print("Result: ");
    }
    if (terminate == 0x1b)
      continue;
    if (!strchr("DRMGBIOXQCN&VSW?.`", cmd))
    {
      Serial.print('?');
      continue;
    }
    noarg = 0;
    if (cmdbuf[cb] && cmd!='?')
      arg = readhexbuf(&terminate);
    else
      noarg = 1;
    switch (cmd)
    {
    case 'S':
      VT100::cls();
      VT100::gotorc(1, 1);
      mon_status();
      break;

    case 'W':
      if (noarg || arg >= 4)
      {
        Serial.print("Usage: W 0|1|2|3 @addr | W 0|1|2|3 -");
      }
      else
      {
        if (terminate != '\r')
        {
          int cc;
          cc = terminate;
          if (cc == ' ')
            cc = getbufc();
          if (cc == '-')
          {
            watchon[arg] = 0;
          }
          if (cc == '@')
          {
            cc = readhexbuf(&terminate);
            watch[arg] = cc;
            watchon[arg] = 1;
          }
        }
        if (visualmode)
          visual_mon_status();
      }
      break;

    case 'V':
      visualmode = !visualmode;
      if (!visualmode)
        VT100::cls();
      else
        visual_mon_status();
      break;

    case '.':
      for (char *cp = cmdbuf + 1; *cp; cp++)
        exec1802(*cp);
      break;

    case '&':
    {
      int y, m, d, h, n, s;
      RTCGetAll(y, m, d, h, n, s);

      if (noarg)
      {
        // display time
        Serial.printf("%4d-%02d-%02d  %02d:%02d:%02d\r\n", y, m, d, h, n, s);
      }
      else
      {
        if (sscanf(cmdbuf + 1, "%d-%d-%d %d:%d:%d", &y, &m, &d, &h, &n, &s) > 0)
          RTCSet(y, m, d, h, n, s);
        else
          Serial.printf("Did not set %s\r\n", cmdbuf + cb);
      }
    }
    break;
    case '?':
    {
      uint8_t cc;
      cc = 0;
      cc = getbufc();
      if (cc == ' ')
        cc = getbufc();
      if (visualmode)
      {
        viscmd = '?';
        vishlp = cc; // help uses this as the command
        visual_mon_status();
      }
      else
        do_help(cc);
    }
    break;

    case '`':
      diskmon();
      break;

    case 'D':
    {
      unsigned arg2 = 0;
      unsigned limit;
      if (noarg)
      {
        if (visualmode && viscmd == 'D')
        {
          visadd = visnext;
          visual_mon_status();
          break;
        }
        else if (visualmode)
        {
          viscmd = 'D'; // take last address
          visual_mon_status();
          break;
        }
        Serial.println(F("Usage: D address [length]"));
        break;
      }
      Serial.println();
      if (terminate != '\r')
        arg2 = readhexbuf(&terminate, 0);
      if (arg2 == 0)
        arg2 = 0x100;
      limit = (arg + arg2) - 1;
      if (limit < arg)
        limit = 0xFFFF; // wrapped around!
      if (visualmode)
      {
        viscmd = 'D';
        visadd = arg;
        visual_mon_status();
      }
      else
        disasm1802(arg, limit);
    }
    break;

    case 'N':
      nobreak = 1;
      if (!visualmode)
        mon_status();
      run();
      if (visualmode)
        visual_mon_status();
      nobreak = 0;
      break;

    case 'B':
      if (noarg || arg >= 0x10)
      {
        if (visualmode)
        {
          viscmd = 'B';
          visual_mon_status();
          break;
        }
        int i;
        for (i = 0; i < sizeof(bp) / sizeof(bp[0]); i++)
          dispbp(i);
        break;
      }
      if (terminate != '\r')
      {
        int cc;
        cc = terminate;
        if (cc == ' ')
          cc = getbufc();
        if (cc == '-')
        {
          bp[arg].type = 0;
          break;
        }
        if (cc == '@')
        {
          cc = readhexbuf(&terminate);
          bp[arg].target = cc;
          bp[arg].type = 1;
        }
        if (cc == 'p' || cc == 'P')
        {
          cc = readhexbuf(&terminate);
          bp[arg].target = cc & 0xF;
          bp[arg].type = 2;
        }
        if (cc == 'i' || cc == 'I')
        {
          cc = readhexbuf(&terminate);
          bp[arg].target = cc & 0xFF;
          bp[arg].type = 3;
        }
        if (visualmode)
          visual_mon_status();
      }
      else
      {
        dispbp(arg);
      }
      break;

    case 'R':
      if (noarg)
      {
        if (!visualmode)
          reg_dump();
        else
          visual_mon_status();
      }
      else
      {
        if (terminate != '=')
          Serial.print(F("R"));
        if (arg <= 0xF)
        {
          if (terminate == '=')
          {
            uint16_t v = readhexbuf(&terminate);
            reg[arg] = v;
            visual_mon_status();
          }
          else
          {
            Serial.print(arg, HEX);
            Serial.print(':');
            print4hex(reg[arg]);
          }
        }
        else
        {
          switch (arg)
          {
          case 0x10:
            if (terminate == '=')
            {
              uint16_t v = readhexbuf(&terminate);
              x = v;
            }
            else
            {
              Serial.print(F("X:"));
              Serial.print(x, HEX);
            }

            break;

          case 0x11:
            if (terminate == '=')
            {
              uint16_t v = readhexbuf(&terminate);
              p = v;
            }
            else
            {
              Serial.print(F("P:"));
              Serial.print(p, HEX);
            }

            break;

          case 0x12:
            if (terminate == '=')
            {
              uint16_t v = readhexbuf(&terminate);
              d = v;
            }
            else
            {
              Serial.print(F("D:"));
              Serial.print(d, HEX);
            }

            break;

          case 0x13:
            if (terminate == '=')
            {
              uint16_t v = readhexbuf(&terminate);
              df = v;
            }
            else
            {
              Serial.print(F("DF:"));
              Serial.print(df, HEX);
            }

            break;

          case 0x14:
            if (terminate == '=')
            {
              uint16_t v = readhexbuf(&terminate);
              q = v;
            }
            else
            {
              Serial.print(F("Q:"));
              Serial.print(q, HEX);
            }

          case 0x15:
            if (terminate == '=')
            {
              uint16_t v = readhexbuf(&terminate);
              t = v;
            }
            else
            {
              Serial.print(F("T:"));
              Serial.print(t, HEX);
            }

            break;
          }
          visual_mon_status();
        }
      }

      break;

    case 'Q':
    {
      runstate = 0;
      monactive = 0;
      return 0;
    }
    case 'C':
    case 'X':
      monactive = 0;
      return 1;
    case 'I':
      print2hex(input(arg));
      break;

    case 'O':
    {
      uint8_t v = readhexbuf(&terminate);
      output(arg, v);
      break;
    }

    case 'G':
    {
      if (terminate != '\r')
        p = readhexbuf(&terminate);
      reg[p] = arg;
      runstate = 1;
      monactive = 0;
      return 0;
    }

    case 'M':
    {
      uint16_t arg2 = 0;
      if (terminate == '=')
      {
        uint8_t d;
        while (cmdbuf[cb] != 0)
        {
          d = readhexbuf(&terminate, 0);
          if (noread == 0)
            memwrite(arg++, d);
          if (terminate == ';')
            break;
        }
        if (terminate == ';')
          break;
        do
        {
          if (terminate == '\r' || terminate == '=')
          {
            Serial.print("\r\n");
            print4hex(arg);
            Serial.print(F(": "));
          }
          d = readhex(&terminate, 0);
          if (terminate != ';' || noread == 0)
            memwrite(arg++, d);
        } while (terminate != ';');
      }
      else
      {
        uint16_t i, limit;
        unsigned ct = 16;
        if (terminate != '\r')
          arg2 = readhexbuf(&terminate, 0);
        if (arg2 == 0)
          arg2 = 0x100;

        // normalize
        i = arg & 0xF; // how much off are we?
        arg &= 0xFFF0;
        arg2 += i;
        if (arg2 & 0xF)
        {
          arg2 &= 0xFFF0;
          arg2 += 0x10; // make sure we have a multiple of 16
        }

        limit = (arg + arg2) - 1;
        if (limit < arg)
          limit = 0xFFFF; // wrapped around!
        if (visualmode)
        {
          if (noarg)
          {
            if (viscmd == 'M')
              visadd += 0x80;
          }
          else
            visadd = arg;
          viscmd = 'M';
          visual_mon_status();
        }
        else
          mem_dump(arg, limit);
      }
      break;
    }

    default:
      Serial.print((char)cmd);
      Serial.println(F("?"));
    }
  }
}

#endif

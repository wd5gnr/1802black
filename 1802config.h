/* Configuration stuff for 1802UNO */
// Configuration

#define KEY_LED 0   // only set to 1 if connected to hardware (warning: hardware not defined yet)s

// Define to 1 for simulation monitor built-in
#define MONITOR 1
#define BIOS 1  // partial BIOS implementation (experimental)

#if BIOS == 1
#if MONITOR == 0
#error Must enable MONITOR when BIOS enabled
#endif
#endif



// Note: MAXMEM is a mask, so don't make it something like 0x500
// Since the Arduino Pro Mini has 2K of RAM--and we use a good bit of that
// this will probably never be more than 0x3FF and certainly could not be
// more than 0x7FF (which would mean on RAM for the rest of the program!)
// So in reality, probably 0x3FF or less unless you port to a CPU
// with more RAM
#define MAXMEM 0x7FFF  // maximum memory address; important: only 1K of EEPROM but this version had 32K RAM so... TODO: take out save/load to EEPROM or document they only save first 1k
#define LED_PORT 4     // port for DATA LED display
#define SW_PORT 4      // Front panel switch port
#define SER_INP 1      // UART input port
#define SER_OUT 1      // UART output port
#define CTL_PORT 7     // Control port
#define A0_PORT 2      // LSD address display output port
#define A1_PORT 3      // MSD address display output port

// How many cycles between display refreshes?
// Higher makes the simulation faster, but the screen more blinky
#define DISPLAY_DIVISOR 32  // number of ticks between display refresh
#define NICE_VALUE 40       // number of times to execute instructions while lighting LEDs (0 to disable)

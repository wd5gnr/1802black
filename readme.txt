Notes:

1) Platform I/O has difficulties getting the USB serial to work on the blackpill, so this uses the Arduino IDE
2) You must enable the USB serial port in your "sketch"
3) The Blackpill I use has 3 DIP switches. The first one grounds a pin and if that switch is thrown, the ROM boots automatically and serial mode is enabled
4) SHOW CPU will bring you to the Uno monitor. You can use . to send front panel commands (e.g., .!)
5) Terminal is 9600-8-n-1 no local echo
6) The ROM contains BIOS code, but most BIOS calls are intercepted and done behind the scenes

CHARCALC

CHARCALC is a simple 8x8 custom character data calculator. It reads the eight leftmost
columns of the top eight rows of the screen and displays the values that would be
used in a DATA statement to load that character pattern into memory.

Installation
------------

LOAD "CHARCALC-INSTALL",8,1
RUN
INSTALL [6000]?

Enter the memory address into which you'd like to install CHARCALC. If you just press RETURN,
CHARCALC will be installed at 6000.

Usage
-----

Clear the screen with SHIFT/CLR HOME, and draw your custom character. CHARCALC reads anything
but a space as foreground for the character.

Once you're done, do

SYS6000 (or whatever address you chose during installation)

Example
-------

SHIFT/CLR HOME
  *  *
  *  *
 ******
** ** **
********
********
* *  * *
  *  *

SYS6000
36,36,126,219,255,255,165,36
READY

Then you can, for example, cursor up to the line of numbers and insert something like

100 DATA 36,36,126,219,255,255,165,36

Further Information
-------------------

See the VIC-20 Programmer's Reference Guide for information about using custom character data
in your programs.

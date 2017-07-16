Several people have asked me for my examples of true recursion in 4GL.  One
even suggested posting it to the list so it gets auto-archived at Emory.

Anyway, I'm not into giving out proprietary code so this past weekend I
whipped up this little demo.  If you don't already have the "stores" database
on your system, create it.  Build the "equipment" table by typing the
following:
  dbaccess stores equipment.sql

After the table is built and loaded, compile the program by typing:
  make

That's all there is to it.  RDS only people, you'll have to build a custom
runner for this sucker.  Grab my "db4glgen" program for help in making it.

The i_equip.4ge program is fully functional.  It can do Queries, Adds,
Updates, Removes, Lookups, and a whole bunch of other stuff.  The program
relies on the constraints attached to the equipment table for data validation.
The only data validation the program does itself is for recursive loops.
(Someone want to help me write a trigger :-)

The o_equip.4ge program is a simple report program.  Provide an id along with
the direction you want to go and it dumps the explosion (or implosion?) to a
file called "report.out".

I've documented the ESQL/C recursion routines somewhat.  It may look messy
but there's nothing really complicated going on (remember I'm NOT a regular C
programmer).  I've documented the recursive loop routine extensively.  If it
sounds complicated, that's because it is!

If you have any questions, send me email.  If you have some suggestions,
please let me know about them.  Enjoy!

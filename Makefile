# Makefile - makefile for executable i_equip (i_equip.4ge)
# Copyright (C) 1995  David A. Snyder  All Rights Reserved


CFLAGS=-c -O
LDFLAGS=-s


################################################################################
# Dependencies for creating the complete working screen.                       #
################################################################################

all: i_equip.4ge i_equip.frm i_equipb.frm i_equip.msg o_equip.4ge o_equip.frm \
     o_equip.msg lu_equip.frm


################################################################################
# Dependencies for creating individual executable, form, and help files.       #
################################################################################

i_equip.4ge: i_equip.o lu_equip.o recursive.o usr_funcs.o
	c4gl i_equip.o lu_equip.o recursive.o usr_funcs.o \
	  $(LDFLAGS) -o i_equip.4ge

i_equip.frm: i_equip.per
	form4gl -s i_equip.per

i_equipb.frm: i_equipb.per
	form4gl -s i_equipb.per

i_equip.msg: i_equip.hlp
	mkmessage i_equip.hlp i_equip.msg

o_equip.4ge: o_equip.o lu_equip.o recursive.o usr_funcs.o
	c4gl o_equip.o lu_equip.o recursive.o usr_funcs.o \
	  $(LDFLAGS) -o o_equip.4ge

o_equip.frm: o_equip.per
	form4gl -s o_equip.per

o_equip.msg: o_equip.hlp
	mkmessage o_equip.hlp o_equip.msg

lu_equip.frm: lu_equip.per
	form4gl -s lu_equip.per


################################################################################
# Dependencies for creating executable's modules.                              #
################################################################################

i_equip.o: i_equip.4gl
	c4gl $(CFLAGS) i_equip.4gl
	@rm -f i_equip.c i_equip.ec

o_equip.o: o_equip.4gl
	c4gl $(CFLAGS) o_equip.4gl
	@rm -f o_equip.c o_equip.ec

lu_equip.o: lu_equip.4gl
	c4gl $(CFLAGS) lu_equip.4gl
	@rm -f lu_equip.c lu_equip.ec

recursive.o: recursive.ec
	c4gl $(CFLAGS) recursive.ec
	@rm -f recursive.c


################################################################################
# Dependency for cleaning up when all done.                                    #
################################################################################

clean:
	rm -f i_equip.4ge i_equip.o i_equip.frm i_equipb.frm i_equip.msg \
	  o_equip.4ge o_equip.o o_equip.frm lu_equip.o lu_equip.frm \
	  o_equip.msg recursive.o usr_funcs.o report.out

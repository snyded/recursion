# o_equip.4gl - 4GL source for executable o_equip (o_equip.4ge)
# Copyright (C) 1995  David A. Snyder  All Rights Reserved


DATABASE stores


DEFINE  w_record, s_record RECORD                           # work/save record
            eq_id LIKE equipment.eq_id,
            eqp_name LIKE equipment.eqp_name,
            level SMALLINT
        END RECORD

DEFINE  direction CHAR(1)


{*******************************************************************************
* This program drives the equipment screen.
*******************************************************************************}

MAIN
    DEFER INTERRUPT
    CALL menu_equipment()
END MAIN


{*******************************************************************************
* This function handles the main ring menu.                                    *
*******************************************************************************}

FUNCTION menu_equipment()
    CALL init_equipment()

    OPEN FORM o_equip FROM "o_equip"
    DISPLAY FORM o_equip

    CALL qry_equipment()
    IF NOT int_flag THEN
        CALL out_equipment()
    END IF

    CLOSE FORM o_equip
END FUNCTION


{*******************************************************************************
* This function initializes options and variables.                             *
*******************************************************************************}

FUNCTION init_equipment()
    OPTIONS HELP FILE "o_equip.msg"
    OPTIONS INPUT WRAP
    OPTIONS MESSAGE LINE LAST

    CREATE TEMP TABLE eqpweb
      (seq SERIAL, id INTEGER NOT NULL, direction CHAR(1), level SMALLINT)
     WITH NO LOG
END FUNCTION


{*******************************************************************************
* This function will query the database table.                                 *
*******************************************************************************}

FUNCTION qry_equipment()
    DISPLAY "OUTPUT:  ESCAPE outputs.  DELETE discards output.  ARROW keys move cursor.", "" AT 1,1
    DISPLAY "Output select rows in report format.", "" AT 2,1
    MESSAGE ""

    LET int_flag = FALSE
    INPUT BY NAME s_record.eq_id, direction HELP 1 ATTRIBUTE(BOLD)
        AFTER FIELD eq_id
            LET s_record.eqp_name = NULL
            SELECT eqp_name INTO s_record.eqp_name
              FROM equipment WHERE eq_id = s_record.eq_id
            DISPLAY BY NAME s_record.eqp_name ATTRIBUTE(BOLD)
        ON KEY (CONTROL-B)
            NEXT FIELD PREVIOUS
        ON KEY (CONTROL-E)
            CASE
                WHEN INFIELD(eq_id)
                    CALL lu_equip(s_record.eq_id, s_record.eqp_name)
                      RETURNING s_record.eq_id, s_record.eqp_name
                    DISPLAY BY NAME s_record.eq_id, s_record.eqp_name
                      ATTRIBUTE(BOLD)
                    NEXT FIELD NEXT
                OTHERWISE
                    ERROR ""
            END CASE
        ON KEY (CONTROL-F)
            NEXT FIELD NEXT
        ON KEY (CONTROL-G)
            CALL fgl_prtscr()
    END INPUT

    RETURN
END FUNCTION


{*******************************************************************************
* This function outputs the current list to the printer.
*******************************************************************************}

FUNCTION out_equipment()
    DEFINE  retval INTEGER

    MESSAGE "Outputting ..."

    LET retval = build_web(s_record.eq_id, direction)
    IF retval THEN
        CALL err_print(retval)
        RETURN
    END IF

    DECLARE out_curs CURSOR FOR
      SELECT id, eqp_name, level, seq FROM eqpweb, equipment
        WHERE equipment.eq_id = eqpweb.id
          AND eqpweb.id = equipment.eq_id
        ORDER BY seq

    START REPORT rpt_equipment TO "report.out"
    FOREACH out_curs INTO w_record.*
        OUTPUT TO REPORT rpt_equipment(w_record.*)
    END FOREACH
    FINISH REPORT rpt_equipment
END FUNCTION


{*******************************************************************************
* This function does the actual formating and printing.                        *
*******************************************************************************}

REPORT rpt_equipment(o_record)
DEFINE  o_record RECORD
            eq_id LIKE equipment.eq_id,
            eqp_name LIKE equipment.eqp_name,
            level SMALLINT
        END RECORD

    OUTPUT LEFT MARGIN 0

    FORMAT
        FIRST PAGE HEADER
            PRINT COLUMN 32, "EQUIPMENT EXPLOSION"
            PRINT COLUMN 32, "-------------------"
            SKIP 2 LINES
            PRINT s_record.eqp_name CLIPPED, "(", s_record.eq_id USING "<<<<<<<<<<", ")"

        ON EVERY ROW 
            PRINT COLUMN o_record.level+1,
              o_record.eqp_name CLIPPED, "(", o_record.eq_id USING "<<<<<<<<<<", ")"

        ON LAST ROW
            SKIP 1 LINE
            PRINT  "Total number of items in explosion: ", COUNT(*)+1 USING "<<<"

END REPORT



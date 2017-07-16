# lu_equip.4gl - 4GL source for equipment lookups
# Copyright (C) 1995  David A. Snyder  All Rights Reserved


DATABASE stores


DEFINE  lu_arrcount SMALLINT
DEFINE  lu_arrcurr SMALLINT
DEFINE  lu_scrline SMALLINT
DEFINE  p_record ARRAY[64] OF RECORD
            eq_id LIKE equipment.eq_id,
            eqp_name LIKE equipment.eqp_name
        END RECORD


{*******************************************************************************
* This function searches through the equipment table.                          *
*******************************************************************************}

FUNCTION lu_equip(eq_id, eqp_name)
DEFINE  eq_id LIKE equipment.eq_id
DEFINE  eqp_name LIKE equipment.eqp_name

    DEFINE  keyhit INTEGER
    DEFINE  scratch CHAR(512)

    OPEN WINDOW ringout_equipment AT 1,1 WITH 2 ROWS, 79 COLUMNS
    DISPLAY "LU-QUERY:  ESCAPE queries.  INTERRUPT aborts.  ARROW keys move cursor.", "" AT 1,1 ATTRIBUTE(WHITE)
    DISPLAY "Searches through the equipment table.", "" AT 2,1 ATTRIBUTE(WHITE)
    OPEN WINDOW lu_equip AT 6, 30 WITH FORM "lu_equip"
      ATTRIBUTE(BORDER, WHITE, FORM LINE FIRST + 1)

LABEL retry:
    LET int_flag = FALSE
    CONSTRUCT BY NAME scratch ON eq_id, eqp_name ATTRIBUTE(BOLD)
    IF int_flag THEN
        CLOSE WINDOW lu_equip
        CLOSE WINDOW ringout_equipment
        RETURN eq_id, eqp_name
    END IF

    LET scratch = "SELECT eq_id, eqp_name FROM equipment WHERE ", scratch CLIPPED, " ORDER BY eq_id"
    PREPARE lu_stmt FROM scratch
    DECLARE lu_curs CURSOR FOR lu_stmt

    LET lu_arrcount = 1
    FOREACH lu_curs INTO p_record[lu_arrcount].*
        LET lu_arrcount = lu_arrcount + 1
    END FOREACH
    LET lu_arrcount = lu_arrcount - 1
    IF lu_arrcount = 0 THEN
        ERROR " There are no rows satisfying the conditions  "
        GOTO retry
    END IF
    LET lu_arrcurr = 1
    LET lu_scrline = 1

    CURRENT WINDOW IS ringout_equipment
    DISPLAY "LOOKUP:  ESCAPE selects.  INTERRUPT aborts.  ARROW keys move cursor.", "" AT 1,1 ATTRIBUTE(WHITE)
    CURRENT WINDOW IS lu_equip

    CALL lu_dsppage_equipment()

    WHILE (TRUE)
        LET keyhit = fgl_getkey()
        CASE
            WHEN keyhit = fgl_keyval("ACCEPT") OR keyhit = fgl_keyval("INTERRUPT")
                EXIT WHILE
            WHEN keyhit = fgl_keyval("DOWN") OR keyhit = fgl_keyval("RIGHT")
                CALL lu_down_equipment()
            WHEN keyhit = fgl_keyval("UP") OR keyhit = fgl_keyval("LEFT")
                CALL lu_up_equipment()
            WHEN keyhit = fgl_keyval("CONTROL-F")     # NEXT KEY
                CALL lu_nextpage_equipment()
            WHEN keyhit = fgl_keyval("CONTROL-B")     # PREVIOUS KEY
                CALL lu_prevpage_equipment()
            WHEN keyhit = fgl_keyval("CONTROL-G")
                CALL fgl_prtscr()
            OTHERWISE
                ERROR ""
        END CASE
    END WHILE

    IF int_flag THEN
        LET p_record[lu_arrcurr].eq_id = eq_id
        LET p_record[lu_arrcurr].eqp_name = eqp_name
        LET int_flag = FALSE
    END IF

    CLOSE WINDOW lu_equip
    CLOSE WINDOW ringout_equipment
    RETURN p_record[lu_arrcurr].*
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the lookup window down one line.           *
*******************************************************************************}

FUNCTION lu_down_equipment()
    IF lu_arrcurr + 1 > lu_arrcount THEN
        ERROR " There are no more rows in the direction you are going  "
        RETURN
    END IF

    CALL lu_dspline_equipment("NORMAL")
    LET lu_arrcurr = lu_arrcurr + 1

    IF lu_scrline + 1 > 5 THEN
        SCROLL s_record.* UP
    ELSE
        LET lu_scrline = lu_scrline + 1
    END IF
    CALL lu_dspline_equipment("REVERSE")
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the lookup window up one line.             *
*******************************************************************************}

FUNCTION lu_up_equipment()
    IF lu_arrcurr - 1 < 1 THEN
        ERROR " There are no more rows in the direction you are going  "
        RETURN
    END IF

    CALL lu_dspline_equipment("NORMAL")
    LET lu_arrcurr = lu_arrcurr - 1

    IF lu_scrline - 1 < 1 THEN
        SCROLL s_record.* DOWN
    ELSE
        LET lu_scrline = lu_scrline - 1
    END IF
    CALL lu_dspline_equipment("REVERSE")
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the lookup window down one page.           *
*******************************************************************************}

FUNCTION lu_nextpage_equipment()
    IF (lu_arrcurr - lu_scrline + 1) + 5 > lu_arrcount THEN
        ERROR " There are no more rows in the direction you are going  "
        RETURN
    ELSE
        LET lu_arrcurr = (lu_arrcurr - lu_scrline + 1) + 5
    END IF

    CALL lu_dsppage_equipment()
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the lookup window up one page.             *
*******************************************************************************}

FUNCTION lu_prevpage_equipment()
    DEFINE  retval SMALLINT

    IF lu_arrcurr = 1 THEN
        ERROR " There are no more rows in the direction you are going  "
        RETURN
    ELSE
        IF (lu_arrcurr - lu_scrline + 1) - 5 < 1 THEN
            LET lu_arrcurr = 1
        ELSE
            LET lu_arrcurr = (lu_arrcurr - lu_scrline + 1) - 5
        END IF
    END IF

    CALL lu_dsppage_equipment()
END FUNCTION


{*******************************************************************************
* This function displays a page of data in the lookup window.                  *
*******************************************************************************}

FUNCTION lu_dsppage_equipment()
    FOR lu_scrline = 1 TO 5
        IF lu_arrcurr <= lu_arrcount THEN
            CALL lu_dspline_equipment("NORMAL")
        ELSE
            CALL lu_dspline_equipment("")
        END IF
        LET lu_arrcurr = lu_arrcurr + 1
    END FOR
    LET lu_arrcurr = lu_arrcurr - 5
    LET lu_scrline = 1
    CALL lu_dspline_equipment("REVERSE")
END FUNCTION


{*******************************************************************************
* This function displays a line of data in the lookup window.                  *
*******************************************************************************}

FUNCTION lu_dspline_equipment(style)
DEFINE  style CHAR(7)

    DEFINE  lu_offset SMALLINT

    CASE
        WHEN style IS NULL
            DISPLAY "", ""
              TO s_record[lu_scrline].eq_id, s_record[lu_scrline].eqp_name
        WHEN style = "NORMAL"
            DISPLAY p_record[lu_arrcurr].eq_id, p_record[lu_arrcurr].eqp_name
              TO s_record[lu_scrline].eq_id, s_record[lu_scrline].eqp_name
        WHEN style = "REVERSE"
            DISPLAY p_record[lu_arrcurr].eq_id, p_record[lu_arrcurr].eqp_name
              TO s_record[lu_scrline].eq_id, s_record[lu_scrline].eqp_name
                ATTRIBUTE(REVERSE)
    END CASE

    LET lu_offset = lu_scrline + 3
    DISPLAY " " AT lu_offset,1
END FUNCTION



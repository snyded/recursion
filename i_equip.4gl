# i_equip.4gl - 4GL source for executable i_equip (i_equip.4ge)
# Copyright (C) 1995  David A. Snyder  All Rights Reserved

# Created by: db4glgen, v4.00 95/05/16 09:04:17


DATABASE stores


DEFINE  w_record RECORD LIKE equipment.*          # working record
DEFINE  s_record RECORD LIKE equipment.*          # saving record
DEFINE  n_record RECORD LIKE equipment.*          # null record
DEFINE  q_cnt INTEGER                            # current size of list
DEFINE  q_cur INTEGER                            # index position in list
DEFINE  q_off CHAR(10)                           # offset to jump 'n' rows
DEFINE  brw_scrline SMALLINT                         # line number in browse

DEFINE  parent_eqp_name LIKE equipment.eqp_name


{*******************************************************************************
* This program drives the equipment screen.
*******************************************************************************}

MAIN
    DEFER INTERRUPT
    CALL menu_equipment()
    CLEAR SCREEN
END MAIN


{*******************************************************************************
* This function handles the main ring menu.                                    *
*******************************************************************************}

FUNCTION menu_equipment()
    CALL init_equipment()

    OPEN FORM i_equip FROM "i_equip"
    DISPLAY FORM i_equip

    MENU "OPTIONS"
        COMMAND "Query" "Searches the active database table." HELP 1
            CALL qry_equipment()
            CALL disp_equipment()
        COMMAND "Browse" "Browse through rows in the Current List." HELP 1
            IF repo_equipment("C", "B") THEN
                CALL brw_equipment()
                CALL disp_equipment()
            END IF
        COMMAND "Next" "Shows the next row in the Current List." HELP 1
            IF repo_equipment("N", "S") THEN
                CALL disp_equipment()
            END IF
        COMMAND "Previous" "Shows the previous row in the Current List." HELP 1
            IF repo_equipment("P", "S") THEN
                CALL disp_equipment()
            END IF
        COMMAND "First" "Shows the first row in the Current List." HELP 1
            IF repo_equipment("F", "S") THEN
                CALL disp_equipment()
            END IF
        COMMAND "Last" "Shows the last row in the Current List." HELP 1
            IF repo_equipment("L", "S") THEN
                CALL disp_equipment()
            END IF
        COMMAND "Add" "Adds a row to the active database table." HELP 1
            CALL add_equipment()
            CALL disp_equipment()
        COMMAND "Update" "Changes a row in the active database table." HELP 1
            IF repo_equipment("C", "U") THEN
                CALL upd_equipment()
            END IF
            CALL disp_equipment()
        COMMAND "Remove" "Deletes a row in the active database table." HELP 1
            IF repo_equipment("C", "U") THEN
                CALL del_equipment()
            END IF
            CALL disp_equipment()
        COMMAND "Current" "Displays the current row of the current table." HELP 1
            IF repo_equipment("C", "S") THEN
                CALL disp_equipment()
            END IF
        COMMAND "Exit" "Returns to the INFORMIX-SQL menu." HELP 1
            EXIT MENU
        COMMAND KEY (CONTROL-G)
            CALL fgl_prtscr()
        COMMAND KEY ("0")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "0"
            WHENEVER ERROR STOP
        COMMAND KEY ("1")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "1"
            WHENEVER ERROR STOP
        COMMAND KEY ("2")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "2"
            WHENEVER ERROR STOP
        COMMAND KEY ("3")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "3"
            WHENEVER ERROR STOP
        COMMAND KEY ("4")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "4"
            WHENEVER ERROR STOP
        COMMAND KEY ("5")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "5"
            WHENEVER ERROR STOP
        COMMAND KEY ("6")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "6"
            WHENEVER ERROR STOP
        COMMAND KEY ("7")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "7"
            WHENEVER ERROR STOP
        COMMAND KEY ("8")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "8"
            WHENEVER ERROR STOP
        COMMAND KEY ("9")
            WHENEVER ERROR CONTINUE
            LET q_off = q_off CLIPPED, "9"
            WHENEVER ERROR STOP
        COMMAND KEY ("!")
            CALL bang()
    END MENU
    CLOSE FORM i_equip
END FUNCTION


{*******************************************************************************
* This function initializes options and variables.                             *
*******************************************************************************}

FUNCTION init_equipment()
    OPTIONS HELP FILE "i_equip.msg"
    OPTIONS INPUT WRAP
    OPTIONS MESSAGE LINE LAST
    OPTIONS PROMPT LINE LAST

    INITIALIZE n_record.* TO NULL
    LET w_record.* = n_record.*   # Faster than INITIALIZE

    IF i_rowid_s() THEN
        ERROR " Memory allocation error, out of memory  "
        EXIT PROGRAM
    END IF

    LET q_cnt = 0
    LET q_cur = 0
    LET q_off = "0"

    PREPARE brw_stmt FROM
      "SELECT eq_id, eqp_name FROM equipment WHERE ROWID = ?"
    DECLARE brw_curs CURSOR FOR brw_stmt

    PREPARE std_stmt FROM
      "SELECT * FROM equipment WHERE ROWID = ?"
    DECLARE std_curs CURSOR FOR std_stmt

    PREPARE upd_stmt FROM
      "SELECT * FROM equipment WHERE ROWID = ? FOR UPDATE"
    DECLARE upd_curs CURSOR FOR upd_stmt

    CREATE TEMP TABLE eqpweb
      (seq SERIAL, id INTEGER NOT NULL, direction CHAR(1), level SMALLINT)
     WITH NO LOG
END FUNCTION


{*******************************************************************************
* This function will query the database table.                                 *
*******************************************************************************}

FUNCTION qry_equipment()
    DEFINE  q_txt CHAR(512)
    DEFINE  the_rowid INTEGER
    DEFINE  retval SMALLINT

    DISPLAY "QUERY:  ESCAPE queries.  INTERRUPT discards query.  ARROW keys move cursor.", "" AT 1,1
    DISPLAY "Searches the active database table.", "" AT 2,1
    MESSAGE ""

    LET s_record.* = w_record.*

    CLEAR FORM
    LET int_flag = FALSE
    CONSTRUCT BY NAME q_txt ON
      equipment.eq_id,
      equipment.eqp_name,
      equipment.parent_eq_id
     HELP 2 ATTRIBUTE(BOLD)
        ON KEY (CONTROL-B)
            NEXT FIELD PREVIOUS
        ON KEY (CONTROL-E)
            CALL ctrl_e_equipment()
            NEXT FIELD NEXT
        ON KEY (CONTROL-F)
            NEXT FIELD NEXT
        ON KEY (CONTROL-G)
            CALL fgl_prtscr()
        ON KEY (CONTROL-P)
            CALL ctrl_p_equipment()
            NEXT FIELD NEXT
    END CONSTRUCT

    IF int_flag THEN
        RETURN
    END IF

    LET q_txt = "SELECT rowid, eq_id FROM equipment WHERE ", q_txt CLIPPED, " ORDER BY eq_id"

    WHENEVER ERROR CONTINUE
    OPTIONS SQL INTERRUPT ON
    MESSAGE "Searching ..."

    PREPARE q_sid FROM q_txt
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        OPTIONS SQL INTERRUPT OFF
        WHENEVER ERROR STOP
        RETURN
    END IF

    DECLARE q_curs CURSOR FOR q_sid
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        OPTIONS SQL INTERRUPT OFF
        WHENEVER ERROR STOP
        RETURN
    END IF

    LET q_cnt = 0
    FOREACH q_curs INTO the_rowid
        IF s_rowid_s(q_cnt + 1) THEN
            ERROR " Memory allocation error, out of memory  "
            OPTIONS SQL INTERRUPT OFF
            WHENEVER ERROR STOP
            RETURN
        END IF
        LET q_cnt = q_cnt + 1
        CALL w_rowid_s(q_cnt, the_rowid)

        IF int_flag THEN
            EXIT FOREACH
        END IF
    END FOREACH

    OPTIONS SQL INTERRUPT OFF
    WHENEVER ERROR STOP

    MESSAGE ""
    IF int_flag THEN
        ERROR " Statement interrupted by user  "
        SLEEP 1
    END IF

    IF q_cnt > 0 THEN
        LET q_cur = 1
        LET retval = repo_equipment("C", "S")
    ELSE
        LET q_cur = 0
        LET w_record.* = n_record.*   # Faster than INITIALIZE
        ERROR " There are no rows satisfying the conditions  "
    END IF
END FUNCTION


{*******************************************************************************
* This function browses through the current list.                              *
*******************************************************************************}

FUNCTION brw_equipment()
    DEFINE  s_cur INTEGER                            # saving index position
    DEFINE  keyhit INTEGER
    DEFINE  retval SMALLINT

    DISPLAY "BROWSE:  ESCAPE selects data.  INTERRUPT aborts.  ARROW keys move cursor.", "" AT 1,1
    DISPLAY "Browse through rows in the Current List.", "" AT 2,1

    OPEN WINDOW browse AT 4,10 WITH FORM "i_equipb"
      ATTRIBUTES(BORDER, FORM LINE FIRST + 1)

    LET s_cur = q_cur
    CALL brw_dsppage_equipment()

    OPTIONS HELP KEY CONTROL-Q
    WHILE (TRUE)
        LET keyhit = fgl_getkey()
        CASE
            WHEN keyhit = fgl_keyval("ACCEPT")
                EXIT WHILE
            WHEN keyhit = fgl_keyval("INTERRUPT")
                LET q_cur = s_cur
                EXIT WHILE
            WHEN keyhit = fgl_keyval("DOWN") OR keyhit = fgl_keyval("RIGHT")
                CALL brw_down_equipment()
            WHEN keyhit = fgl_keyval("UP") OR keyhit = fgl_keyval("LEFT")
                CALL brw_up_equipment()
            WHEN keyhit = fgl_keyval("F3")     # NEXT KEY
                CALL brw_nextpage_equipment()
            WHEN keyhit = fgl_keyval("F4")     # PREVIOUS KEY
                CALL brw_prevpage_equipment()
            WHEN keyhit = fgl_keyval("CONTROL-G")
                CALL fgl_prtscr()
            WHEN keyhit = fgl_keyval("0") OR
                 keyhit = fgl_keyval("1") OR
                 keyhit = fgl_keyval("2") OR
                 keyhit = fgl_keyval("3") OR
                 keyhit = fgl_keyval("4") OR
                 keyhit = fgl_keyval("5") OR
                 keyhit = fgl_keyval("6") OR
                 keyhit = fgl_keyval("7") OR
                 keyhit = fgl_keyval("8") OR
                 keyhit = fgl_keyval("9")
                WHENEVER ERROR CONTINUE
                LET q_off = q_off CLIPPED, ASCII keyhit
                WHENEVER ERROR STOP
            OTHERWISE
                ERROR ""
                LET q_off = "0"
        END CASE
    END WHILE
    OPTIONS HELP KEY CONTROL-W

    LET retval = repo_equipment("C", "S")

    CLOSE WINDOW browse
END FUNCTION


{*******************************************************************************
* This function adds a row to the database table.                              *
*******************************************************************************}

FUNCTION add_equipment()
    DEFINE  the_rowid INTEGER

    DISPLAY "ADD:  ESCAPE adds new data.  INTERRUPT discards it.  ARROW keys move cursor.", "" AT 1,1
    DISPLAY "Adds new data to the active database table.", "" AT 2,1
    MESSAGE ""

    LET s_record.* = w_record.*
    LET w_record.* = n_record.*   # Faster than INITIALIZE

    CLEAR parent_eqp_name

    LET int_flag = FALSE
    OPTIONS HELP KEY CONTROL-Q
    INPUT BY NAME
      w_record.eq_id,
      w_record.eqp_name,
      w_record.parent_eq_id
     HELP 2 ATTRIBUTE(BOLD)
        BEFORE FIELD eq_id
            CALL reverse_on_equipment()
        AFTER FIELD eq_id
            CALL reverse_off_equipment()
        BEFORE FIELD eqp_name
            CALL reverse_on_equipment()
        AFTER FIELD eqp_name
            CALL reverse_off_equipment()
        BEFORE FIELD parent_eq_id
            CALL reverse_on_equipment()
        AFTER FIELD parent_eq_id
            CALL reverse_off_equipment()
            LET parent_eqp_name = NULL
            SELECT eqp_name INTO parent_eqp_name
              FROM equipment WHERE eq_id = w_record.parent_eq_id
            DISPLAY BY NAME parent_eqp_name ATTRIBUTE(BOLD)
        ON KEY (CONTROL-B)
            CALL reverse_off_equipment()
            NEXT FIELD PREVIOUS
        ON KEY (CONTROL-E)
            CALL reverse_off_equipment()
            CALL ctrl_e_equipment()
            NEXT FIELD NEXT
        ON KEY (CONTROL-F)
            CALL reverse_off_equipment()
            NEXT FIELD NEXT
        ON KEY (CONTROL-G)
            CALL fgl_prtscr()
        ON KEY (CONTROL-P)
            CALL reverse_off_equipment()
            CALL ctrl_p_equipment()
            NEXT FIELD NEXT
        ON KEY (CONTROL-W)
            CALL help_equipment()
        ON KEY (INTERRUPT)
            EXIT INPUT
    END INPUT
    OPTIONS HELP KEY CONTROL-W

    IF int_flag THEN
        LET w_record.* = s_record.*
        RETURN
    END IF

    WHENEVER ERROR CONTINUE

    LET w_record.eq_id = 0
    INSERT INTO equipment VALUES (w_record.*)
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        LET w_record.* = s_record.*
        WHENEVER ERROR STOP
        RETURN
    END IF
    LET w_record.eq_id = sqlca.sqlerrd[2]
    LET the_rowid = sqlca.sqlerrd[6]

    DISPLAY BY NAME w_record.eq_id ATTRIBUTE(BOLD)

    IF s_rowid_s(q_cnt + 1) THEN
        ERROR " Memory allocation error, out of memory  "
        LET w_record.* = s_record.*
        WHENEVER ERROR STOP
        RETURN
    END IF
    LET q_cnt = q_cnt + 1

    WHENEVER ERROR STOP

    LET q_cur = q_cnt
    CALL w_rowid_s(q_cur, the_rowid)

    MESSAGE "Row added"
END FUNCTION


{*******************************************************************************
* This function will update the current row.                                   *
*******************************************************************************}

FUNCTION upd_equipment()
    DISPLAY "UPDATE:  ESCAPE changes data.  INTERRUPT discards changes.  ARROW keys move.", "" AT 1,1
    DISPLAY "Changes this row in the active database table.", "" AT 2,1
    MESSAGE ""

    LET s_record.* = w_record.*

    LET int_flag = FALSE
    OPTIONS HELP KEY CONTROL-Q
    INPUT BY NAME
      w_record.eq_id,
      w_record.eqp_name,
      w_record.parent_eq_id
     WITHOUT DEFAULTS HELP 2 ATTRIBUTE(BOLD)
        BEFORE FIELD eq_id
            CALL reverse_on_equipment()
        AFTER FIELD eq_id
            CALL reverse_off_equipment()
        BEFORE FIELD eqp_name
            CALL reverse_on_equipment()
        AFTER FIELD eqp_name
            CALL reverse_off_equipment()
        BEFORE FIELD parent_eq_id
            CALL reverse_on_equipment()
        AFTER FIELD parent_eq_id
            CALL reverse_off_equipment()
            LET parent_eqp_name = NULL
            SELECT eqp_name INTO parent_eqp_name
              FROM equipment WHERE eq_id = w_record.parent_eq_id
            DISPLAY BY NAME parent_eqp_name ATTRIBUTE(BOLD)
            IF recursive_loop() THEN
                NEXT FIELD parent_eq_id
            END IF
        ON KEY (CONTROL-B)
            CALL reverse_off_equipment()
            NEXT FIELD PREVIOUS
        ON KEY (CONTROL-E)
            CALL reverse_off_equipment()
            CALL ctrl_e_equipment()
            NEXT FIELD NEXT
        ON KEY (CONTROL-F)
            CALL reverse_off_equipment()
            NEXT FIELD NEXT
        ON KEY (CONTROL-G)
            CALL fgl_prtscr()
        ON KEY (CONTROL-P)
            CALL reverse_off_equipment()
            CALL ctrl_p_equipment()
            NEXT FIELD NEXT
        ON KEY (CONTROL-W)
            CALL help_equipment()
        ON KEY (INTERRUPT)
            EXIT INPUT
    END INPUT
    OPTIONS HELP KEY CONTROL-W

    IF int_flag THEN
        CLOSE upd_curs
        IF sqlca.sqlcode THEN
            CALL err_print(sqlca.sqlcode)
        END IF
        LET w_record.* = s_record.*
        RETURN
    END IF

    WHENEVER ERROR CONTINUE

    UPDATE equipment SET equipment.* = w_record.* WHERE CURRENT OF upd_curs
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        CLOSE upd_curs
        IF sqlca.sqlcode THEN
            CALL err_print(sqlca.sqlcode)
        END IF
        LET w_record.* = s_record.*
        WHENEVER ERROR STOP
        RETURN
    END IF

    CLOSE upd_curs
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        WHENEVER ERROR STOP
        RETURN
    END IF

    WHENEVER ERROR STOP

    MESSAGE "This row has been changed"
END FUNCTION


{*******************************************************************************
* This function will delete the current row.                                   *
*******************************************************************************}

FUNCTION del_equipment()
    MENU "REMOVE"
        COMMAND "No" "Does NOT remove this row from the active table." HELP 3
            CLOSE upd_curs
            IF sqlca.sqlcode THEN
                CALL err_print(sqlca.sqlcode)
            END IF
            RETURN
        COMMAND "Yes" "Removes this row from the active table." HELP 3
            EXIT MENU
        COMMAND KEY (CONTROL-G)
            CALL fgl_prtscr()
    END MENU

    WHENEVER ERROR CONTINUE

    DELETE FROM equipment WHERE CURRENT OF upd_curs
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        CLOSE upd_curs
        IF sqlca.sqlcode THEN
            CALL err_print(sqlca.sqlcode)
        END IF
        WHENEVER ERROR STOP
        RETURN
    END IF

    CLOSE upd_curs
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        WHENEVER ERROR STOP
        RETURN
    END IF

    WHENEVER ERROR STOP

    CALL shuffle_equipment()              # I deleted this record

    MESSAGE "Row deleted"
END FUNCTION


{*******************************************************************************
* This function executes a shell command.                                      *
*******************************************************************************}

FUNCTION bang()
    DEFINE  cmd CHAR(80)
    DEFINE  x CHAR(1)

    MESSAGE ""

    LET x = "!"
    WHILE x = "!"
        PROMPT "!" FOR cmd
            ON KEY (CONTROL-G)
                CALL fgl_prtscr()
        END PROMPT
        RUN cmd
        PROMPT "Press return to continue" FOR CHAR x
            ON KEY (CONTROL-G)
                CALL fgl_prtscr()
        END PROMPT
    END WHILE
END FUNCTION


{*******************************************************************************
* This function gets the current, next, or previous row.                       *
*******************************************************************************}

FUNCTION repo_equipment(direction, cursor_type)
DEFINE  direction CHAR(1)
DEFINE  cursor_type CHAR(1)

    DEFINE  the_rowid INTEGER
    DEFINE  q_jmp INTEGER

    IF q_cnt = 0 THEN
        ERROR " There are no rows in the current list  "
        RETURN FALSE
    ELSE
        MESSAGE ""
    END IF

    LET q_jmp = q_off
    IF q_jmp = 0 THEN
        LET q_jmp = 1
    END IF
    LET q_off = "0"

    CASE direction
        WHEN "N"
            LET q_cur = q_cur + q_jmp
            IF  q_cur > q_cnt THEN
                LET q_cur = q_cnt
                ERROR " There are no more rows in the direction you are going  "
            END IF
        WHEN "P"
            LET q_cur = q_cur - q_jmp
            IF  q_cur < 1 THEN
                LET q_cur = 1
                ERROR " There are no more rows in the direction you are going  "
            END IF
        WHEN "F"
            LET q_cur = 1
        WHEN "L"
            LET q_cur = q_cnt
        WHEN "C"
            #  Do Nothing !!!
    END CASE

    WHENEVER ERROR CONTINUE

    LET the_rowid = r_rowid_s(q_cur)
    CASE
        WHEN cursor_type = "U"
            OPEN upd_curs USING the_rowid
        WHEN cursor_type = "B"
            OPEN brw_curs USING the_rowid
        OTHERWISE
            OPEN std_curs USING the_rowid
    END CASE
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        WHENEVER ERROR STOP
        RETURN FALSE
    END IF

    CASE
        WHEN cursor_type = "U"
            FETCH upd_curs INTO w_record.*
        WHEN cursor_type = "B"
            FETCH brw_curs INTO w_record.eq_id, w_record.eqp_name
        OTHERWISE
            FETCH std_curs INTO w_record.*
    END CASE
    IF sqlca.sqlcode THEN
        IF sqlca.sqlcode = NOTFOUND THEN
            ERROR " Someone else has deleted a row which is in your list  "
            CALL shuffle_equipment()              # Other deleted this record
            IF cursor_type = "S" THEN
                WHENEVER ERROR STOP
                RETURN TRUE
            END IF
        ELSE
            CALL err_print(sqlca.sqlcode)
        END IF
        WHENEVER ERROR STOP
        RETURN FALSE
    END IF

    WHENEVER ERROR STOP

    RETURN TRUE
END FUNCTION


{*******************************************************************************
* This function displays data for the current row.                             *
*******************************************************************************}

FUNCTION disp_equipment()
    LET parent_eqp_name = NULL
    SELECT eqp_name INTO parent_eqp_name
      FROM equipment WHERE eq_id = w_record.parent_eq_id

    DISPLAY BY NAME
      w_record.eq_id,
      w_record.eqp_name,
      w_record.parent_eq_id,
      parent_eqp_name,
      q_cur,
      q_cnt
     ATTRIBUTE(BOLD)
END FUNCTION


{*******************************************************************************
* This function brings in the most recent column value of the row.             *
*******************************************************************************}

FUNCTION ctrl_p_equipment()
    CASE
        WHEN INFIELD(eq_id)
            LET w_record.eq_id = s_record.eq_id
            DISPLAY BY NAME w_record.eq_id ATTRIBUTE(BOLD)
        WHEN INFIELD(eqp_name)
            LET w_record.eqp_name = s_record.eqp_name
            DISPLAY BY NAME w_record.eqp_name ATTRIBUTE(BOLD)
        WHEN INFIELD(parent_eq_id)
            LET w_record.parent_eq_id = s_record.parent_eq_id
            DISPLAY BY NAME w_record.parent_eq_id ATTRIBUTE(BOLD)
    END CASE
END FUNCTION


{*******************************************************************************
* This function displays the contents of the working record in reverse video.  *
*******************************************************************************}

FUNCTION reverse_on_equipment()
    CASE
        WHEN INFIELD(eq_id)
            DISPLAY BY NAME w_record.eq_id ATTRIBUTE(REVERSE)
        WHEN INFIELD(eqp_name)
            DISPLAY BY NAME w_record.eqp_name ATTRIBUTE(REVERSE)
        WHEN INFIELD(parent_eq_id)
            DISPLAY BY NAME w_record.parent_eq_id ATTRIBUTE(REVERSE)
    END CASE
END FUNCTION


{*******************************************************************************
* This function displays the contents of the working record normally.          *
*******************************************************************************}

FUNCTION reverse_off_equipment()
    CASE
        WHEN INFIELD(eq_id)
            DISPLAY BY NAME w_record.eq_id ATTRIBUTE(BOLD)
        WHEN INFIELD(eqp_name)
            DISPLAY BY NAME w_record.eqp_name ATTRIBUTE(BOLD)
        WHEN INFIELD(parent_eq_id)
            DISPLAY BY NAME w_record.parent_eq_id ATTRIBUTE(BOLD)
    END CASE
END FUNCTION


{*******************************************************************************
* This function shuffles the rowid array down one element (after a delete).    *
*******************************************************************************}

FUNCTION shuffle_equipment()
    DEFINE  retval SMALLINT

    CALL m_rowid_s(q_cur, q_cnt)

    LET q_cnt = q_cnt - 1
    IF q_cur > q_cnt THEN
        LET q_cur = q_cnt
    END IF

    IF q_cur = 0 THEN
        LET w_record.* = n_record.*   # Faster than INITIALIZE
    ELSE
        LET retval = repo_equipment("C", "S")
    END IF
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the browse window down one line.           *
*******************************************************************************}

FUNCTION brw_down_equipment()
    DEFINE  retval SMALLINT

    IF q_off = "0" THEN
        IF q_cur + 1 > q_cnt THEN
            ERROR " There are no more rows in the direction you are going  "
            RETURN
        ELSE
            LET q_cur = q_cur + 1
        END IF

        CALL brw_dspline_equipment("NORMAL")
        IF brw_scrline + 1 > 10 THEN
            SCROLL b_record.* UP
        ELSE
            LET brw_scrline = brw_scrline + 1
        END IF
        IF repo_equipment("C", "B") THEN
            CALL brw_dspline_equipment("REVERSE")
        END IF
    ELSE
        LET retval = repo_equipment("N", "B")
        CALL brw_dsppage_equipment()
    END IF
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the browse window up one line.             *
*******************************************************************************}

FUNCTION brw_up_equipment()
    DEFINE  retval SMALLINT

    IF q_off = "0" THEN
        IF q_cur - 1 < 1 THEN
            ERROR " There are no more rows in the direction you are going  "
            RETURN
        ELSE
            LET q_cur = q_cur - 1
        END IF

        CALL brw_dspline_equipment("NORMAL")
        IF brw_scrline - 1 < 1 THEN
            SCROLL b_record.* DOWN
        ELSE
            LET brw_scrline = brw_scrline - 1
        END IF
        IF repo_equipment("C", "B") THEN
            CALL brw_dspline_equipment("REVERSE")
        END IF
    ELSE
        LET retval = repo_equipment("P", "B")
        CALL brw_dsppage_equipment()
    END IF
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the browse window down one page.           *
*******************************************************************************}

FUNCTION brw_nextpage_equipment()
    DEFINE  retval SMALLINT

    IF q_off = "0" THEN
        IF (q_cur - brw_scrline + 1) + 10 > q_cnt THEN
            ERROR " There are no more rows in the direction you are going  "
            RETURN
        ELSE
            LET q_cur = (q_cur - brw_scrline + 1) + 10
        END IF
    ELSE
        WHENEVER ERROR CONTINUE
        LET q_off = q_off * 10
        WHENEVER ERROR STOP
        LET retval = repo_equipment("N", "B")
    END IF

    CALL brw_dsppage_equipment()
END FUNCTION


{*******************************************************************************
* This function moves the cursor in the browse window up one page.             *
*******************************************************************************}

FUNCTION brw_prevpage_equipment()
    DEFINE  retval SMALLINT

    IF q_cur = 1 THEN
        ERROR " There are no more rows in the direction you are going  "
        RETURN
    ELSE
        IF q_off = "0" THEN
            IF (q_cur - brw_scrline + 1) - 10 < 1 THEN
                LET q_cur = 1
            ELSE
                LET q_cur = (q_cur - brw_scrline + 1) - 10
            END IF
        ELSE
            WHENEVER ERROR CONTINUE
            LET q_off = q_off * 10
            WHENEVER ERROR STOP
            LET retval = repo_equipment("P", "B")
        END IF
    END IF

    CALL brw_dsppage_equipment()
END FUNCTION


{*******************************************************************************
* This function displays a page of data in the browse window.                  *
*******************************************************************************}

FUNCTION brw_dsppage_equipment()
    FOR brw_scrline = 1 TO 10
        IF q_cur <= q_cnt THEN
            IF repo_equipment("C", "B") THEN
                CALL brw_dspline_equipment("NORMAL")
            END IF
        ELSE
            CALL brw_dspline_equipment("")
        END IF
        LET q_cur = q_cur + 1
    END FOR
    LET q_cur = q_cur - 10
    LET brw_scrline = 1
    IF repo_equipment("C", "B") THEN
        CALL brw_dspline_equipment("REVERSE")
    END IF
END FUNCTION


{*******************************************************************************
* This function displays a line of data in the browse window.                  *
*******************************************************************************}

FUNCTION brw_dspline_equipment(style)
DEFINE  style CHAR(7)

    DEFINE  brw_offset SMALLINT

    CASE
        WHEN style IS NULL
            DISPLAY "", ""
              TO b_record[brw_scrline].eq_id, b_record[brw_scrline].eqp_name
        WHEN style = "NORMAL"
            DISPLAY w_record.eq_id, w_record.eqp_name
              TO b_record[brw_scrline].eq_id, b_record[brw_scrline].eqp_name
        WHEN style = "REVERSE"
            DISPLAY w_record.eq_id, w_record.eqp_name
              TO b_record[brw_scrline].eq_id, b_record[brw_scrline].eqp_name
                ATTRIBUTE(REVERSE)
    END CASE

    LET brw_offset = brw_scrline + 3
    DISPLAY " " AT brw_offset,1
END FUNCTION


{*******************************************************************************
* This function displays help for individual fields.                           *
*******************************************************************************}

FUNCTION help_equipment()
    CASE
        WHEN INFIELD(eq_id)
            CALL SHOWHELP(1000)
        WHEN INFIELD(eqp_name)
            CALL SHOWHELP(1001)
        WHEN INFIELD(parent_eq_id)
            CALL SHOWHELP(1002)
    END CASE
END FUNCTION


FUNCTION ctrl_e_equipment()
    CASE
        WHEN INFIELD(parent_eq_id)
            CALL lu_equip(w_record.parent_eq_id, parent_eqp_name)
              RETURNING w_record.parent_eq_id, parent_eqp_name
            DISPLAY BY NAME w_record.parent_eq_id, parent_eqp_name
              ATTRIBUTE(BOLD)
        OTHERWISE
            ERROR ""
    END CASE
END FUNCTION


FUNCTION recursive_loop()
    DEFINE  retval INTEGER
    DEFINE  dups INTEGER

    # The following mess checks for recursive loops.
    # Here's how it's done:
    #

    # First, we clean out the temp table (eqpweb) to start with
    # a clean slate.
    #
    DELETE FROM eqpweb

    # Next, while walking UP the web, we stuff the id's
    # of all parents, grand-parents, great-grand-parents, etc.
    # for the proposed "parent_eq_id" into the temp table.
    #
    LET retval = build_web(w_record.parent_eq_id, "U")
    IF retval THEN
        CALL err_print(retval)
        RETURN TRUE
    END IF

    # Then, while walking DOWN the web, we stuff the id's
    # of all children, grand-children, great-grand-children,
    # etc. for the current "eq_id" into the temp table.
    #
    LET retval = build_web(w_record.eq_id, "D")
    IF retval THEN
        CALL err_print(retval)
        RETURN TRUE
    END IF

    # Now, we stuff the current "eq_id" into the temp table as a DOWN
    # link with a level of '0'.  We need to stuff the current "eq_id"
    # because the recursion routine only provides ancestors or
    # decendents, not the id itself.  We choose DOWN because we
    # walked down the tree with the "eq_id".  We walked up the tree with
    # "parent_eq_id" so the "parent_eq_id" wasn't written to the temp
    # table (but we don't care about that).  What we do care about is
    # that maybe while walking up the tree, we wrote the current "eq_id"
    # to the temp table there too.  Read the comments below to see why
    # we care.
    WHENEVER ERROR CONTINUE
    INSERT INTO eqpweb VALUES (NULL, w_record.eq_id, "D", 0)
    IF sqlca.sqlcode THEN
        CALL err_print(sqlca.sqlcode)
        WHENEVER ERROR STOP
        RETURN TRUE
    END IF
    WHENEVER ERROR STOP

    # Lastly, by doing a self-join on the temp table, we know who
    # are ancesters and who are decendents of the relationship
    # about to be created.  If there is one or more id's in the
    # temp table that's both an ancester AND a descendent,
    # you've got a recursive loop.
    SELECT COUNT(*) INTO dups
      FROM eqpweb u, eqpweb d
      WHERE u.direction = "U" AND d.direction = "D"
        AND u.id = d.id
    IF dups > 0 THEN
        ERROR " This entry would create a recursive loop  "
        RETURN TRUE
    END IF

    RETURN FALSE
END FUNCTION



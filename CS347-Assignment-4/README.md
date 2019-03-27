stmt_list := stmt NEWLINE stmt_list
            | stmt
stmt := SELECT LA condition RA LP table_name RP
        | PROJECT LA attr_list RA LP table_name RP
        | LP table_name RP CARTESIAN_PRODUCT LP table_name RP
        | LP table_name RP EQUI_JOIN LA condition LP table_name RP

attr_list := attr COMMA attr_list
            | attr

condition := cond2 OR condition 
            | cond2

cond2 := expr AND cond2
        | expr

expr := col op col
        | col op INT
        | INT op col
        | col op QUOTED_STRING
        | QUOTED_STRING op col
        | LP condition RP
        | NOT LP condition RP

col := ID DOT ID
        | ID    

op := LA
    | RA
    | LE
    | GE
    | EQUAL
    | NOT_EQUAL

table_name := ID
column_name := ID  
attr := ID


equi join:
check table names exist or not
cases:
case 1: both column has table name in its struct
        check for each column if it exist in its own table
        remember to store in datatype
case 2: only one of the column has table name in its struct
        check for that column if it exist in its prescribed table
        check the other column if it exist in the table not belonging to the first column
        remember to store in datatype
case 3: none of the column has table name
        check if the first column exist in the first table if does not check if it exist in the second table
        if it does not error else check for the other column in the left table
        remember to store in datatype

on all the cases at last check if datatype matches or not
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(char* s);
char list[100][100];
int vals;

char *ccondition;
%}

%code requires{
    #include "list.c"
}

%union {
    int intval;
    char text[100];
    struct {
        char *name;
    } name;


    struct and_entry and_ent;
    struct or_list list_of_exe;
    struct {
        char* table;
        char* col;
    } colattr;

    struct {
        int type;
    } op;
}

/* declare tokens */
%token SELECT PROJECT CARTESIAN_PRODUCT EQUI_JOIN
%token LP RP LA RA EQUAL NOT_EQUAL LE GE DOT COMMA AND OR NOT RE
%token INT QUOTED_STRING ID
%token NEWLINE


%type <list_of_exe> cond2
%type <and_ent> expr
%type <name> attr
%type <op> op
%type <colattr> col
%type <intval> INT;
%type <text> ID;
%type <text> QUOTED_STRING;


%%
stmt_list: stmt NEWLINE stmt_list
    | stmt
    | error NEWLINE {printf("error: syntax error in line number %d\n\n",yylineno-1);} stmt_list    
;

stmt: SELECT LA condition RA LP ID RP
    | PROJECT LA attr_list RA LP ID RP
    {
        printf("no of cols = %d\n", vals);    
    }
    | LP ID RP CARTESIAN_PRODUCT LP ID RP       {}
    | LP ID RP EQUI_JOIN LA condition RA LP ID RP       {}
    | %empty
;

attr_list: attr COMMA attr_list
    {
        sprintf(list[vals], "%s", $1.name);
        printf("added column name 2 - : %s\n", list[vals]);
        vals++;
    }
    | attr
    {
        memset(list, 0, 10000);
        vals = 0;
        sprintf(list[0], "%s", $1.name);
        printf("added column name 1 - : %s\n", list[0]);
        vals++;
    }
;


condition: cond2 OR condition
    {
        
    } 
    | cond2  
    {

    }
;

cond2: expr AND cond2
    {
    }
    | expr
    {
        $$.end = &($1);
        $$.head = &($1);
    }
;

expr: col op col 
    {
        $$.table1 = $1.table;
        $$.table2 = $3.table;
        $$.col1 = $1.col;
        $$.col2 = $3.col;
        $$.operation = $2.type;
        $$.int1_fnd = 0;
        $$.int2_fnd = 0;
        $$.str1 = NULL;
        $$.str2 = NULL;
    }
    | col op INT 
    {
        printf("int val : %d\n", $3);
        $$.table1 = $1.table;
        $$.table2 = NULL;
        $$.col1 = $1.col;
        $$.col2 = NULL;
        $$.operation = $2.type;
        $$.int1_fnd = 0;
        $$.int2_fnd = 1;
        $$.val2 = $3;
        $$.str1 = NULL;
        $$.str2 = NULL;
    }
    | INT op col
    {
        $$.table1 = NULL;
        $$.table2 = $3.table;
        $$.col1 = NULL;
        $$.col2 = $3.col;
        $$.operation = $2.type;
        $$.int1_fnd = 1;
        $$.int2_fnd = 0;
        $$.val1 = $1;
        $$.str1 = NULL;
        $$.str2 = NULL;
    }
    | col op QUOTED_STRING
    {
        $$.table1 = $1.table;
        $$.table2 = NULL;
        $$.col1 = $1.col;
        $$.col2 = NULL;
        $$.operation = $2.type;
        $$.int1_fnd = 0;
        $$.int2_fnd = 0;
        $$.str1 = NULL;
        $$.str2 = $3;
    }
    | QUOTED_STRING op col
    {
        $$.table1 = NULL;
        $$.table2 = $3.table;
        $$.col1 = NULL;
        $$.col2 = $3.col;
        $$.operation = $2.type;
        $$.int1_fnd = 0;
        $$.int2_fnd = 0;
        $$.str1 = $1;
        $$.str2 = NULL;
    }
;

col: ID DOT ID {
        $$.table = malloc(100);
        $$.col = malloc(100);
        memset($$.col, 0, 100);
        memset($$.table, 0, 100);
        sprintf($$.table, "%s", $1);
        sprintf($$.col, "%s", $3);
    }
    | ID  {
        printf("col name ---- : %s\n", $1);
        $$.table = NULL;
        $$.col = malloc(100);
        memset($$.col, 0, 100);
        sprintf($$.col, "%s", $1);
    }
;

op: LA {$$.type = 1;}
    | RA {$$.type = 2;}
    | LE {$$.type = 3;}
    | GE {$$.type = 4;}
    | EQUAL {$$.type = 5;}
    | NOT_EQUAL {$$.type = 6;}
;


attr: ID   {
    $$.name = malloc(100);
    memset($$.name, 0, 100);
    sprintf($$.name, "%s", yytext);
    printf("column name : %s\n", $$.name);
};

%%


int main(int argc, char **argv)
{
  yyparse();
}

void yyerror(char *s)
{      
    // printf( "error!!: %s at line %d\n", s, yylineno);
    // fflush(stdout);
}
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "csvread.c"

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
    
    #include "comparator.h"
}

%union {
    int intval;
    char text[100];
    struct {
        char *name;
    } name;


    struct and_entry and_ent;
    struct and_list list_of_and;
    struct or_list list_of_or;
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

%type <list_of_or> condition
%type <list_of_and> cond2
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
    {
        // print_list($3);
        populate($6);
        char fname[200];
        memset(fname,0,200);
        sprintf(fname,"%s.csv",$6);
        FILE* file = fopen(fname,"r");
        char str[1000];
        fgets(str, 1000, file);
        printf("%s", str);
        fgets(str, 1000, file);
        printf("%s", str);
        while (fgets(str, 1000, file)) {
            if (compute_condition($3, str))  {
                printf("%s", str);
            }
        }
        fclose(file);        
    }
    | PROJECT LA attr_list RA LP ID RP
    {
        // printf("no of cols = %d\n", vals);
        int flag=checkTableName($6);
        if (flag==0) {
            printf("Error: no table found\n");
        }
        else {
            printColumns(list, vals, $6);
        }
    

    }
    | LP ID RP CARTESIAN_PRODUCT LP ID RP       
    {
        // printf("hello %s %s\n", $2, $6);
        printCartesianProducts($2, $6);
    }
    | LP ID RP EQUI_JOIN LA condition RA LP ID RP       
    {

    }
    | %empty
;

attr_list: attr COMMA attr_list
    {
        sprintf(list[vals], "%s", $1.name);
        // printf("added column name 2 - : %s\n", list[vals]);
        vals++;
    }
    | attr
    {
        memset(list, 0, 10000);
        vals = 0;
        sprintf(list[0], "%s", $1.name);
        // printf("added column name 1 - : %s\n", list[0]);
        vals++;
    }
;


condition: cond2 OR condition
    {
        $$ = join_or_list($3, $1); 
    } 
    | cond2  
    {
        $$.end = malloc(sizeof(and_list));
        $$.head = $$.end;
        memcpy($$.head, &$1, sizeof (and_list));
        // printf("col name ---- 2 --- : %s\n", $1.head->col1);
        // printf("col name ---- 2 --- : %s\n", $1.head->col2);
    }
;

cond2: expr AND cond2
    {
        $$ = join_and_list($3, $1); 
    }
    | expr
    {
        // printf("paji special %s\n", $1.col1);
        // printf("paji special %s\n", $1.col2);
        $$.end = malloc(sizeof(and_entry));
        $$.head = $$.end;
        $$.next_ptr = NULL;
        memcpy($$.head, &$1, sizeof (and_entry));
        // printf("col name ---- 1 --- : %s\n", $$.head->col1);
        // printf("col name ---- 1 --- : %s\n", $$.head->col2);
    }
;

expr: col op col 
    {
        
        $$.table1 = $1.table;
        $$.table2 = $3.table;
        $$.col1 = malloc(100);  memset($$.col1, 0, 100);
        $$.col2 = malloc(100);  memset($$.col2, 0, 100); 
        sprintf($$.col1, "%s", $1.col);
        sprintf($$.col2, "%s", $3.col);
        $$.operation = $2.type;
        $$.int1_fnd = 0;
        $$.int2_fnd = 0;
        $$.str1 = NULL;
        $$.str2 = NULL;
        $$.next_ptr = NULL;
    }
    | col op INT 
    {
        // printf("int val : %d\n", $3);
        if($1.table==NULL){ $$.table1 = $1.table; }
        else { $$.table1 = malloc(100); memset($$.table1, 0, 100); sprintf($$.table1, "%s", $1.table);}
        $$.table2 = NULL;
        $$.col1 = malloc(100);
        $$.col2 = NULL;
        sprintf($$.col1, "%s", $1.col);
        $$.operation = $2.type;
        $$.int1_fnd = 0;
        $$.int2_fnd = 1;
        $$.val2 = $3;
        $$.str1 = NULL;
        $$.str2 = NULL;
        $$.next_ptr = NULL;
    }
    | INT op col
    {
        $$.table1 = NULL;
        $$.table2 = $3.table;
        $$.col1 = NULL;
        $$.col2 = malloc(100);
        sprintf($$.col2, "%s", $3.col);
        $$.operation = $2.type;
        $$.int1_fnd = 1;
        $$.int2_fnd = 0;
        $$.val1 = $1;
        $$.str1 = NULL;
        $$.str2 = NULL;
        $$.next_ptr = NULL;
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
        $$.next_ptr = NULL;
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
        $$.next_ptr = NULL;
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
        // printf("col name ---- : %s\n", $1);
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
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
char* tableName;
char *ccondition;
%}

%union {
    struct {
        char *name;
    } name;

    struct {
        char* table;
        char* col;
        int op;
    } colattr;
}

/* declare tokens */
%token SELECT PROJECT CARTESIAN_PRODUCT EQUI_JOIN
%token LP RP LA RA EQUAL NOT_EQUAL LE GE DOT COMMA AND OR NOT RE
%token INT QUOTED_STRING ID
%token NEWLINE

%type <name> attr
%type <name> table_name 
%type <name> column_name

%%
stmt_list: stmt NEWLINE stmt_list
    | stmt
    | error NEWLINE {printf("error: syntax error in line number %d\n\n",yylineno-1);} stmt_list    
;

stmt: SELECT LA condition RA LP table_name RP
    {
        
    }
    | PROJECT LA attr_list RA LP table_name 
    {
        int flag=checkTableName(yytext);
        if(flag==0){
            printf("Error: no table found\n");
        }
        else{
            printColumns(list,vals,yytext);
        }
    }
    RP
    {
        printf("no of cols = %d\n", vals);    
    }
    | LP table_name RP CARTESIAN_PRODUCT LP table_name RP       
    {
        printf("hello %s %s\n", $2.name, $6.name);
        printCartesianProducts($2.name,$6.name);
    }
    | LP table_name RP EQUI_JOIN LA condition RA LP table_name RP       {}
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
;

cond2: expr AND cond2
    {
    }
    | expr
;

expr: col op col
    | col op INT
    {
    }
    | INT op col
    | col op QUOTED_STRING
    | QUOTED_STRING op col
;

col: table_name DOT column_name
    | column_name  
;

op: LA 
    | RA 
    | LE 
    | GE 
    | EQUAL 
    | NOT_EQUAL 
;

table_name: ID   {
    $$.name = malloc(100);
    memset($$.name, 0, 100);
    sprintf($$.name, "%s", yytext);
    printf("table name : %s\n", $$.name);
};

column_name: ID {
    $$.name = malloc(100);
    memset($$.name, 0, 100);
    sprintf($$.name, "%s", yytext);
    printf("column name : %s\n", $$.name);
};

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
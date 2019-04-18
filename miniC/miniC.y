%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(char* s);

int scope;
%} 

%code requires {
    #include "functab.h"
}

%union {
    int intval;
    float floatval;
    char *text;
    /* Each linkedList node conatins a struct of type (void *) */
    linkedList *dimlist;
    linkedList *typerecList;
    typerec* varRec;
    funcEntry* funcEntryRec;
}

%token INT FLOAT VOID NUMFLOAT NUMINT ID NEWLINE
%token COLON QUESTION DOT LCB RCB LSB RSB LP RP SEMI COMMA ASSIGN
%token IF ELSE CASE BREAK DEFAULT CONTINUE WHILE FOR RETURN SWITCH MAIN
%token NOT AND OR LT GT LE GE EQUAL NOTEQUAL LSHIFT RSHIFT PLUSASG MINASG MULASG MODASG DIVASG INCREMENT DECREMENT XOR BITAND BITOR PLUS MINUS DIV MUL MOD

%type <floatval> NUMFLOAT
%type <intval> NUMINT T
%type <text> ID
%type <typerecList> L
%type <varRec> ID_ARR DEC_ID_ARR 
%type <dimlist> BR_DIMLIST
%type <funcEntryRec> FUN

%%

MAIN_PROG: PROG MAINFUNCTION
    | MAINFUNCTION
;

PROG: PROG FUNC_DEF
    | FUNC_DEF
;

MAINFUNCTION: INT MAIN LP RP LCB BODY RCB
;

FUNC_DEF: FUNC_HEAD LCB BODY RCB
        {
            $$ = (func_name_table*)malloc(sizeof(func_name_table));
            $$->name = $1->name;
            $$->parameter_ptr = $1->parameter_ptr;
        }
;

FUNC_HEAD: RES_ID LP DECL_PLIST RP
;

RES_ID: RESULT ID   
;

RESULT: INT
    | FLOAT
    | VOID
;

DECL_PLIST: DECL_PL
    | %empty
;

DECL_PL: DECL_PL COMMA DECL_PARAM
    | DECL_PARAM
;

DECL_PARAM: T ID
;

BODY: STMT_LIST
    | %empty
;

STMT_LIST: STMT_LIST STMT 
    | STMT 
;

STMT: VAR_DECL
    | FUNC_CALL SEMI
    | ASG SEMI
    | FORLOOP
    | IFSTMT
    | WHILESTMT
    | SWITCHCASE
    | LCB BODY RCB
    | BREAK SEMI
    | CONTINUE SEMI
    | RETURN ASG SEMI
;

VAR_DECL: D SEMI 
;

D: T L  { 
            // patchDataType($1, $2, scope); 
            // insertSymTab($2);
            // $2.clear();
        }
;

T:  INT         { $$ = INTEGER; }
    | FLOAT     { $$ = FLOATING; }
;    

L: DEC_ID_ARR
    {  
        $$ = createList();
        push_back($$, $1, sizeof(typerec));
    }
    | L COMMA DEC_ID_ARR    
    { 
        push_back($$, $3, sizeof(typerec) ) ;
        $$ = $1;
    }
;

DEC_ID_ARR: ID
    {   
        // search_var($1, active_func_ptr, scope, found, vn);
        $$ = createTyperec();
        $$->name = $1;
        $$->type = SIMPLE;
        // $$->eletype to be patched
        $$->tag = VARIABLE;
        $$->scope = scope;
    }
    | ID ASSIGN CONDITION1
    {
        
        // $$.name = $1;
        // $$.type = SIMPLE;
        // $$.eletype to be patched
        // $$.tag = VARIABLE;
        // $$.scope = scope;
    }
    | ID BR_DIMLIST
    {
        $$ = createTyperec();
        $$->name = $1;
        $$->type = ARRAY;
        $$->tag = VARIABLE;
        $$->scope = scope;
        $$->dimlist = $2;
    }
;

ID_ARR: ID
    {   
        $$ = (typerec*)malloc(sizeof(typerec));
        $$->name = $1;
        $$->type = SIMPLE;
        // $$->eletype to be patched
        $$->tag = VARIABLE;
        $$->scope = scope;
    }
    | ID BR_DIMLIST
    {
        $$ = (typerec*)malloc(sizeof(typerec));
        $$->name = $1;
        $$->type = ARRAY;
        // $$->eletype to be patched
        $$->tag = VARIABLE;
        $$->scope = scope;
    }
;

BR_DIMLIST: LSB NUMINT RSB
    {
        $$ = createList();
        push_back($$, &$2, sizeof(int));
    }
    | BR_DIMLIST LSB NUMINT RSB 
    {
        $$ = $1; // preserve order
        push_back($$, &$3, sizeof(int));
        // $1.clear();
    }
;

FUNC_CALL: ID LP PARAMLIST RP SEMI
        {
            
        }
;

PARAMLIST: PLIST 
    | %empty 
;

PLIST: PLIST COMMA CONDITION1
    | CONDITION1
;

ASG: CONDITION1
    | LHS ASSIGN ASG
    | LHS PLUSASG ASG
    | LHS MINASG ASG
    | LHS MULASG ASG
    | LHS DIVASG ASG
    | LHS MODASG ASG
;

LHS: ID_ARR   
;

SWITCHCASE: SWITCH LP ASG RP LCB CASELIST RCB
;

CASELIST:   CASE CONDITION1 COLON BODY CASELIST
    | CASE CONDITION1 COLON BODY
    | DEFAULT COLON BODY
;

FORLOOP: FOREXP LCB BODY RCB
;

FOREXP: FOR LP ASG1 SEMI ASG1 SEMI ASG1 RP
;

ASG1: ASG
    | %empty
;

IFSTMT: IFEXP LCB BODY RCB
    | IFEXP LCB BODY RCB ELSE LCB BODY RCB
;

IFEXP: IF LP ASG RP 
;

WHILESTMT:  WHILEEXP LCB BODY RCB 
;

WHILEEXP: WHILE LP ASG RP
;

CONDITION1: CONDITION2 OR CONDITION1
    | CONDITION2
;  

CONDITION2: EXPR1 AND CONDITION2
    | EXPR1
;

EXPR1: NOT EXPR21
    | EXPR21
;

EXPR21: EXPR2 EQUAL EXPR2
    | EXPR2 NOTEQUAL EXPR2
    | EXPR2 LT EXPR2 
    | EXPR2 GT EXPR2
    | EXPR2 LE EXPR2
    | EXPR2 GE EXPR2
    | ID_ARR INCREMENT 
    | ID_ARR DECREMENT
    | INCREMENT ID_ARR
    | DECREMENT ID_ARR
    | EXPR2
;

EXPR2:  EXPR2 PLUS TERM
    | EXPR2 MINUS TERM
    | TERM
;

TERM: TERM MUL FACTOR
    | TERM DIV FACTOR   
    | FACTOR
;

FACTOR: ID_ARR
    | NUMINT
    | NUMFLOAT
    | LP ASG RP
;

%%

void yyerror(char *s)
{      
    printf( "error!!: %s at line %d\n", s, yylineno);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    scope=0;
    yyparse();
}
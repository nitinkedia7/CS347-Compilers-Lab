%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
#include <bits/stdc++.h>
#include "funcTab.h"
using namespace std;

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(char* s);

string text;
eletype resultType;
vector<typeRecord*> typeRecordList;
typeRecord* varRecord;
vector<int> dimlist;

vector<funcEntry*> funcEntryRecord;
funcEntry* activeFuncPtr;
funcEntry* callFuncPtr;
int scope;
int found;
%} 

%union {
    int intval;
    float floatval;
    char *idName;
}

%token INT FLOAT VOID NUMFLOAT NUMINT ID NEWLINE
%token COLON QUESTION DOT LCB RCB LSB RSB LP RP SEMI COMMA ASSIGN
%token IF ELSE CASE BREAK DEFAULT CONTINUE WHILE FOR RETURN SWITCH MAIN
%token LSHIFT RSHIFT PLUSASG MINASG MULASG MODASG DIVASG INCREMENT DECREMENT XOR BITAND BITOR PLUS MINUS DIV MUL MOD
%token NOT AND OR LT GT LE GE EQUAL NOTEQUAL

%type <floatval> NUMFLOAT
%type <intval> NUMINT
%type <idName> ID

%%

MAIN_PROG: PROG MAINFUNCTION
    | MAINFUNCTION
;

PROG: PROG FUNC_DEF
    | FUNC_DEF
;

MAINFUNCTION: MAIN_HEAD LCB BODY RCB
    {
        printFunction(activeFuncPtr);
        deleteVarList(activeFuncPtr, scope);
        activeFuncPtr=NULL;
        scope=0;
    }
;

MAIN_HEAD: INT MAIN LP RP
    {
        scope=1;
        activeFuncPtr = new funcEntry;
        activeFuncPtr->name = string("main");
        activeFuncPtr->returnType = INTEGER;
        activeFuncPtr->numOfParam = 0;
        activeFuncPtr->parameterList.clear();
        activeFuncPtr->variableList.clear();        ;
        typeRecordList.clear();
        searchFunc(activeFuncPtr, funcEntryRecord, found);
        if (found) {
            cout << "Function already declared: " << activeFuncPtr->name << endl;
            delete activeFuncPtr;
            activeFuncPtr = NULL;
        }   
        else {
            addFunction(activeFuncPtr, funcEntryRecord);
            scope = 2; 
        }
    }
;

FUNC_DEF: FUNC_HEAD LCB BODY RCB
    {
        printFunction(activeFuncPtr);
        deleteVarList(activeFuncPtr, scope);
        activeFuncPtr=NULL;
        scope=0;
    }
;

FUNC_HEAD: RES_ID LP DECL_PLIST RP
    {
        activeFuncPtr->numOfParam = typeRecordList.size();
        activeFuncPtr->parameterList = typeRecordList;
        typeRecordList.clear();
        searchFunc(activeFuncPtr, funcEntryRecord, found);
        if(found){
            cout << "Function already declared: " <<activeFuncPtr->name << endl;
            delete activeFuncPtr;
            activeFuncPtr=NULL;
        }   
        else{
            addFunction(activeFuncPtr, funcEntryRecord);
            scope = 2; 
        }
    }
;

RES_ID: RESULT ID       
    {
        scope=1;
        activeFuncPtr = new funcEntry;
        activeFuncPtr->name = string($2);
        activeFuncPtr->returnType = resultType;
    } 
;

RESULT: INT  { resultType = INTEGER;  }
    | FLOAT  { resultType = FLOATING; }
    | VOID   { resultType = NULLVOID; }
;

DECL_PLIST: DECL_PL
    | %empty
;

DECL_PL: DECL_PL COMMA DECL_PARAM
    {
        searchParam(varRecord->name, typeRecordList, found);
        if(found){
            cout<<"Redeclaration of parameter"<<(varRecord->name)<<endl;
        } else {
            // cout<<"\nVar Name:"<<varRecord->name<<endl;
            typeRecordList.push_back(varRecord);
        }
        
    }
    | DECL_PARAM
    {   
        searchParam(varRecord->name, typeRecordList, found);
        if(found){
            cout<<"Redeclaration of parameter"<<(varRecord->name)<<endl;
        } else {
            // cout<<"\nVar Name : "<<varRecord->name<<endl;
            typeRecordList.push_back(varRecord);
        }
    }
    
;

DECL_PARAM: T ID
    {
        varRecord = new typeRecord;
        varRecord->name = string($2);
        varRecord->type = SIMPLE;
        varRecord->tag = VARIABLE;
        varRecord->scope = scope;
        varRecord->eleType = resultType;
    }
;

BODY: STMT_LIST
    | %empty
;

STMT_LIST: STMT_LIST STMT 
    | STMT 
;

STMT: VAR_DECL
    | ASG SEMI
    | FORLOOP
    | IFSTMT
    | WHILESTMT
    | SWITCHCASE
    | LCB BODY RCB
    | BREAK SEMI
    | CONTINUE SEMI
    | RETURN ASG1 SEMI
;

VAR_DECL: D SEMI 
;

D: T L
    { 
        patchDataType(resultType, typeRecordList, scope);
        insertSymTab(typeRecordList, activeFuncPtr);
        typeRecordList.clear();
    }
;

T:  INT         { resultType = INTEGER; }
    | FLOAT     { resultType = FLOATING; }
;    

L: DEC_ID_ARR
    | L COMMA DEC_ID_ARR      
;

DEC_ID_ARR: ID
    {   
        // printf("var $1:%s\n", $1);
        int found = 0;
        typeRecord* vn = NULL;
        // cout << "Scope : "<<scope<<endl;
        searchVariable(string($1), activeFuncPtr, found, vn);
        if (found && vn->scope == scope) {
            printf("Variable %s already declared at same level %d\n", $1, scope);
        }
        else if (scope == 2) {
            searchParam(string($1), activeFuncPtr->parameterList, found);
            if (found) {
                printf("Parameter with name %s exists %d\n", $1, scope);
            } 
            else {
                varRecord = new typeRecord;
                varRecord->name = string($1);
                // printf("var $1:%s\n", $1);
                varRecord->type = SIMPLE;
                varRecord->tag = VARIABLE;
                varRecord->scope = scope;
                // cout<<"variable name: "<<varRecord->name<<endl;
                typeRecordList.push_back(varRecord);
            }
        }
        else {
            varRecord = new typeRecord;
            varRecord->name = string($1);
            varRecord->type = SIMPLE;
            varRecord->tag = VARIABLE;
            varRecord->scope = scope;
            // cout<<"variable name: "<<varRecord->name<<endl;
            typeRecordList.push_back(varRecord);
        }
    }
    | ID ASSIGN CONDITION1
    | ID BR_DIMLIST
    {  
        int found = 0;
        typeRecord* vn = NULL;
        searchVariable(string($1), activeFuncPtr, found, vn); 
        if (found && vn->scope == scope) {
            printf("Variable %s already declared at same level %d\n", $1, scope);
        }
        else if (scope == 2) {
            searchParam(string($1), activeFuncPtr->parameterList, found);
            if (found) {
                printf("Parameter with name %s exists %d\n", $1, scope);
            } 
            else {
                varRecord = new typeRecord;
                varRecord->name = string($1);
                varRecord->type = SIMPLE;
                varRecord->tag = VARIABLE;
                varRecord->scope = scope;
                // cout<<"variable name: "<<varRecord->name<<endl;
                typeRecordList.push_back(varRecord);
            }
        }
        else{
            varRecord = new typeRecord;        
            varRecord->name = string($1);
            varRecord->type = ARRAY;
            varRecord->tag = VARIABLE;
            varRecord->scope = scope;
            varRecord->dimlist = dimlist;
            dimlist.clear();
            typeRecordList.push_back(varRecord);
        }  
    }
;

BR_DIMLIST: LSB NUMINT RSB
    {
        dimlist.push_back($2);
    }
    | BR_DIMLIST LSB NUMINT RSB 
    {
        dimlist.push_back($3);
    }
;

FUNC_CALL: ID LP PARAMLIST RP
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
    | FUNC_CALL
    | LP ASG RP
;

ID_ARR: ID
    {   
        // retrieve the highest level id with same name in param list or var list

        // int found = 0;
        // typeRecord* vn = NULL;
        // searchVariable(string($1), activeFuncPtr->variableList, found, vn); 
        // if(found == 0){
        //     searchParam(string)
        // }
        
    }
    | ID BR_DIMLIST
    {

    }
;

%%

void yyerror(char *s)
{      
    printf( "\nSyntax error %s at line %d\n", s, yylineno);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    scope = 0;
    yyparse();
}
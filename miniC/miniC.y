%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
#include <bits/stdc++.h>
#include "funcTab.h"
#include "codegenHelpers.h"
using namespace std;

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(char* s);

FILE *outasm, *outinter, *outtemp;
string text;
eletype resultType;
vector<typeRecord*> typeRecordList;
typeRecord* varRecord;
vector<int> dimlist;

int nextquad;
vector<string> functionInstruction;
registerSet tempSet;

vector<funcEntry*> funcEntryRecord;
funcEntry* activeFuncPtr;
funcEntry* callFuncPtr;
int scope;
int found;
int labelCount;

bool errorFound;
%} 


%code requires{
    #include "funcTab.h"
    #include "codegenHelpers.h"
}

%union {
    int intval;
    float floatval;
    char *idName;
    int quad;

    struct expression expr;
    struct stmt stmtval;
    struct whileexp whileexpval;
}

%token INT FLOAT VOID NUMFLOAT NUMINT ID NEWLINE
%token COLON QUESTION DOT LCB RCB LSB RSB LP RP SEMI COMMA ASSIGN
%token IF ELSE CASE BREAK DEFAULT CONTINUE WHILE FOR RETURN SWITCH MAIN
%token LSHIFT RSHIFT PLUSASG MINASG MULASG MODASG DIVASG INCREMENT DECREMENT XOR BITAND BITOR PLUS MINUS DIV MUL MOD
%token NOT AND OR LT GT LE GE EQUAL NOTEQUAL

%type <idName> NUMFLOAT
%type <idName> NUMINT
%type <idName> ID
%type <expr> EXPR2 TERM FACTOR ID_ARR ASG ASG1 EXPR1 EXPR21 CONDITION1 CONDITION2 LHS
%type <whileexpval> WHILEEXP IFEXP 
%type <stmtval> BODY WHILESTMT IFSTMT M2
%type <quad> M1 M3 N3 P3

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
        typeRecord* pn = NULL;
        searchParam(varRecord->name, typeRecordList, found, pn);
        if(found){
            cout<<"Redeclaration of parameter"<<(varRecord->name)<<endl;
        } else {
            // cout<<"\nVar Name:"<<varRecord->name<<endl;
            typeRecordList.push_back(varRecord);
        }
        
    }
    | DECL_PARAM
    {  
        typeRecord* pn = NULL;
        searchParam(varRecord->name, typeRecordList, found , pn );
        if (found){
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
    | LCB {scope++;} BODY RCB 
    {
        deleteVarList(activeFuncPtr, scope);
        scope--;
    }
    | BREAK SEMI
    | CONTINUE SEMI
    | RETURN ASG1 SEMI 
    {
        if(activeFuncPtr->returnType == NULLVOID && ($2.type != NULLVOID)){
            cout<<"The function "<< activeFuncPtr->name<<" has no return type"<<endl;
        }
        else if(activeFuncPtr->returnType != NULLVOID && ($2.type == NULLVOID || $2.type == ERRORTYPE)){
            cout<<"The function "<< activeFuncPtr->name<<" must have a"<<" return type"<<endl;
        }
        else{

        }
    }
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
            typeRecord* pn = NULL;
            searchParam(string($1), activeFuncPtr->parameterList, found , pn);
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
    | ID ASSIGN ASG
    {
        int found = 0;
        typeRecord* vn = NULL;
        // cout << "Scope : "<<scope<<endl;
        searchVariable(string($1), activeFuncPtr, found, vn);
        if (found && vn->scope == scope) {
            printf("Variable %s already declared at same level %d\n", $1, scope);
        }
        else if (scope == 2) {
            typeRecord* pn = NULL;
            searchParam(string($1), activeFuncPtr->parameterList, found , pn);
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
    | ID BR_DIMLIST
    {  
        int found = 0;
        typeRecord* vn = NULL;
        searchVariable(string($1), activeFuncPtr, found, vn); 
        if (found && vn->scope == scope) {
            printf("Variable %s already declared at same level %d\n", $1, scope);
        }
        else if (scope == 2) {
            typeRecord* pn = NULL;
            searchParam(string($1), activeFuncPtr->parameterList, found, pn);
            if (found) {
                printf("Parameter with name %s exists %d\n", $1, scope);
            } 
            else {
                varRecord = new typeRecord;
                varRecord->name = string($1);
                varRecord->type = ARRAY;
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
        dimlist.push_back(atoi($2));
    }
    | BR_DIMLIST LSB NUMINT RSB 
    {
        dimlist.push_back(atoi($3));
    }
;

FUNC_CALL: ID LP PARAMLIST RP
    {
        callFuncPtr = new funcEntry;
        callFuncPtr->name = string($1);
        callFuncPtr->parameterList = typeRecordList;
        callFuncPtr->numOfParam = typeRecordList.size();
        typeRecordList.clear();
        int found = 0;
        // printFunction(activeFuncPtr);
        // printFunction(callFuncPtr);
        compareFunc(callFuncPtr,funcEntryRecord,found);
        if(found == 0){
            cout<<"No function with name --"<<string($1)<<"-- exits"<<endl;
        }
        else if(found == -1){
            cout <<"Parameter list does not match with declared function paramters"<<endl;
        }
        else{
            // to do when funtion is called correctly
            // cout<<"YESSS"<<endl;
        }
    }
;


PARAMLIST: PLIST 
    | %empty 
;

PLIST: PLIST COMMA ASG
    {
        varRecord = new typeRecord;
        varRecord->eleType = $3.type;
        typeRecordList.push_back(varRecord);
    }
    | ASG
    {
        varRecord = new typeRecord;
        varRecord->eleType = $1.type;
        typeRecordList.push_back(varRecord);
    }
;

ASG: CONDITION1
    {
        $$.type = $1.type;
    }
    | LHS ASSIGN ASG
    {
        if($3.type == NULLVOID || $3.type==ERRORTYPE){
            cout<<"Can't assign void to int or float"<<endl;
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = $1.type;
        }
        
    }
    | LHS PLUSASG ASG
    {
        if($3.type == NULLVOID || $3.type==ERRORTYPE){
            cout<<"Can't assign void to int or float"<<endl;
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = $1.type;
        }
    }
    | LHS MINASG ASG
    {
        if($3.type == NULLVOID || $3.type==ERRORTYPE){
            cout<<"Can't assign void to int or float"<<endl;
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = $1.type;
        }
    }
    | LHS MULASG ASG
    {
        if($3.type == NULLVOID || $3.type==ERRORTYPE){
            cout<<"Can't assign void to int or float"<<endl;
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = $1.type;
        }
    }
    | LHS DIVASG ASG
    {
        if($3.type == NULLVOID || $3.type==ERRORTYPE){
            cout<<"Can't assign void to int or float"<<endl;
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = $1.type;
        }
    }
    | LHS MODASG ASG
    {
        if($3.type == NULLVOID || $3.type==ERRORTYPE){
            cout<<"Can't assign void to int or float"<<endl;
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = $1.type;
        }
    }
;

LHS: ID_ARR  
    {
        $$.type = $1.type;
    } 
;

SWITCHCASE: SWITCH LP ASG RP {scope++;} LCB CASELIST RCB 
    {
        deleteVarList(activeFuncPtr,scope);
        scope--;
    }
;

CASELIST:   CASE CONDITION1 COLON BODY CASELIST
    | CASE CONDITION1 COLON BODY
    | DEFAULT COLON BODY
;

FORLOOP: FOREXP LCB BODY RCB
    {
        deleteVarList(activeFuncPtr, scope);
        scope--;
    }
;

FOREXP: FOR LP ASG1 SEMI M3 ASG1 SEMI N3 ASG1 P3 RP
    {
        
        scope++;
    }
;

ASG1: ASG
    {
        $$.type= $1.type;
    }
    | %empty
    {
        $$.type = NULLVOID;
    }
;

M1: %empty
    {
        $$=nextquad;
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
;

M2: %empty
    {
        ($$.nextList)->push_back(nextquad);
        gen(functionInstruction, "goto ", nextquad);
    }
;

M3: %empty { $$ = nextquad; }
;
N3: %empty { $$ = nextquad; }
;
P3: %empty { $$ = nextquad; }
;


IFSTMT: IFEXP LCB BODY RCB 
    {
        deleteVarList(activeFuncPtr,scope);
        scope--;
        merge($$.nextList, $1.falseList);
        merge($$.breakList, $3.breakList);
        merge($$.continueList, $3.continueList);
        backpatch($$.nextList,nextquad,functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
    | IFEXP LCB BODY RCB {deleteVarList(activeFuncPtr,scope);} M2 ELSE M1 LCB BODY RCB
    {
        deleteVarList(activeFuncPtr,scope);
        scope--;
        backpatch($1.falseList,$8,functionInstruction);
        merge($$.nextList,$6.nextList );
        backpatch($$.nextList,nextquad,functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        merge($$.breakList, $3.breakList);
        merge($$.continueList, $3.continueList);
        merge($$.breakList, $10.breakList);
        merge($$.continueList, $10.continueList);
    }
;

IFEXP: IF LP ASG RP 
    {
        $$.falseList->push_back(nextquad);
        if($3.type == NULLVOID){
            cout<<"Expression in if statement can't be empty"<<endl;
            errorFound=true;
        }
        gen(functionInstruction, "if "+ (*($3.registerName)) + " == 0 goto ", nextquad);
        scope++;
    }
;

WHILESTMT:  WHILEEXP LCB BODY RCB 
    {
        deleteVarList(activeFuncPtr,scope);
        scope--;

        gen(functionInstruction, "goto L" + to_string($1.begin), nextquad);
        backpatch($3.nextList, $1.begin, functionInstruction);
        backpatch($3.continueList, $1.begin, functionInstruction);
        merge($$.nextList, $1.falseList);
        merge($$.nextList, $3.breakList);
        backpatch($$.nextList,nextquad,functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
;

WHILEEXP: WHILE M1 LP ASG RP
    {
        if($4.type == NULLVOID){
            cout<<"Expression in if statement can't be empty"<<endl;
            errorFound = true;
        }
        scope++;
        
        ($$.falseList)->push_back(nextquad);
        gen(functionInstruction, "if " + *($4.registerName) + "== 0 goto ", nextquad);
        $$.begin = $2; 
    }
;

CONDITION1: CONDITION2 OR CONDITION1
    {
        if($1.type==ERRORTYPE || $3.type==ERRORTYPE){
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " || " + (*($3.registerName)) + ";";   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName)); 
        }
    }
    | CONDITION2
    {
        $$.type = $1.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $1.registerName;    
        }
    }
;  

CONDITION2: EXPR1 AND CONDITION2
    {
        if ($1.type==ERRORTYPE || $3.type==ERRORTYPE) {
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " && " + (*($3.registerName)) + ";";   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));   
        }
    }
    | EXPR1
    {
        $$.type = $1.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $1.registerName;    
        }
    }
;

EXPR1: NOT EXPR21
    {
        $$.type = $2.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $2.registerName;
            string s = (*($$.registerName)) + " = ~" + (*($2.registerName))+";";   
            gen(functionInstruction, s, nextquad);
        }
    }
    | EXPR21
    {
        $$.type = $1.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $1.registerName;    
        }
    }
;

EXPR21: EXPR2 EQUAL EXPR2
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
        }
        else {
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());     
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " == " + (*($3.registerName))+ ";";   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    }
    | EXPR2 NOTEQUAL EXPR2
    {
        if($1.type == ERRORTYPE || $3.type == ERRORTYPE){
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());     
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " != " + (*($3.registerName))+ ";";   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    }
    | EXPR2 LT EXPR2 
    {
        if($1.type == ERRORTYPE || $3.type == ERRORTYPE){
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());     
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " < " + (*($3.registerName))+ ";";   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    }
    | EXPR2 GT EXPR2
    {
        if($1.type == ERRORTYPE || $3.type == ERRORTYPE){
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());     
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " > " + (*($3.registerName))+ ";";   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    }
    | EXPR2 LE EXPR2
    {
        if($1.type == ERRORTYPE || $3.type == ERRORTYPE){
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());     
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " <= " + (*($3.registerName))+ ";";   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    }
    | EXPR2 GE EXPR2
    {
        if($1.type == ERRORTYPE || $3.type == ERRORTYPE){
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());     
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " >= " + (*($3.registerName))+ ";";  
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    }
    | ID_ARR INCREMENT
    {
        if ($1.type == INTEGER) {
            $$.type = INTEGER;   
            string newReg = tempSet.getRegister();
            $$.registerName = new string(newReg);
            string s = newReg + " = " + (*($1.registerName)) + ";";
            gen(functionInstruction, s, nextquad);
            s = (*($1.registerName)) + " = " + newReg + " + 1 ;";
            gen(functionInstruction, s, nextquad);
        }
        else {
            $$.type = ERRORTYPE;
            cout << "Cannot increment non-integer type variable" << endl; 
        }
    } 
    | ID_ARR DECREMENT
    {
        if ($1.type == INTEGER) {
            $$.type = INTEGER;   
            string newReg = tempSet.getRegister();
            $$.registerName = new string(newReg);
            string s = newReg + " = " + (*($1.registerName)) + ";";
            gen(functionInstruction, s, nextquad);
            s = (*($1.registerName)) + " = " + newReg + " - 1 ;";
            gen(functionInstruction, s, nextquad);     
        }
        else {
            $$.type = ERRORTYPE;
            cout << "Cannot increment non-integer type variable" << endl; 
        }
    } 
    | INCREMENT ID_ARR
    {
        if ($2.type == INTEGER) {
            $$.type = INTEGER;   
            string newReg = tempSet.getRegister();
            $$.registerName = new string(newReg);
            string s = newReg + " = " + (*($2.registerName)) + " + 1 ;";
            gen(functionInstruction, s, nextquad);
            s = (*($2.registerName)) + " = " + newReg + ";";
            gen(functionInstruction, s, nextquad);      
        }
        else {
            $$.type = ERRORTYPE;
            cout << "Cannot increment non-integer type variable" << endl; 
        }
    } 
    | DECREMENT ID_ARR
    {
        if ($2.type == INTEGER) {
            $$.type = INTEGER;   
            string newReg = tempSet.getRegister();
            $$.registerName = new string(newReg);
            string s = newReg + " = " + (*($2.registerName)) + " - 1 ;";
            gen(functionInstruction, s, nextquad);
            s = (*($2.registerName)) + " = " + newReg + ";";
            gen(functionInstruction, s, nextquad);        
        }
        else {
            $$.type = ERRORTYPE;
            cout << "Cannot increment non-integer type variable" << endl; 
        }
    } 
    | EXPR2 
    {
        $$.type = $1.type; 
        $$.registerName = new string(*($1.registerName)); 
        delete $1.registerName;     
    }
;

EXPR2:  EXPR2 PLUS TERM
    {
      if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE; 
            errorFound = true; 
        }
        else {
            if (arithmeticCompatible($1.type, $3.type)) {
                $$.type = compareTypes($1.type,$3.type);

                if ($1.type == INTEGER && $3.type == FLOATING) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ");";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ");";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " + " + (*($3.registerName))+ ";";;   
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($1.registerName));
                tempSet.freeRegister(*($3.registerName));   
            }
            else {
                cout << "Type mismatch in expression" << endl;
                $$.type = ERRORTYPE;
            }
        }
    }
    | EXPR2 MINUS TERM
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
            errorFound = true;  
        }
        else {
            if (arithmeticCompatible($1.type, $3.type)) {
                $$.type = compareTypes($1.type,$3.type);

                if ($1.type == INTEGER && $3.type == FLOATING) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ");";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ");";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " - " + (*($3.registerName))+ ";";;   
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($1.registerName));
                tempSet.freeRegister(*($3.registerName));   
            }
            else {
                cout << "Type mismatch in expression" << endl;
                $$.type = ERRORTYPE;
            }
        }
    }
    | TERM 
    { 
        $$.type = $1.type; 
        if ($1.type == ERRORTYPE) {
            errorFound = true;
        }
        else {
            $$.registerName = new string(*($1.registerName)); 
            delete $1.registerName;
        } 
    }
;

TERM: TERM MUL FACTOR
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;  
        }
        else {
            if (arithmeticCompatible($1.type, $3.type)) {
                $$.type = compareTypes($1.type,$3.type);

                if ($1.type == INTEGER && $3.type == FLOATING) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ");";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ");";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " * " + (*($3.registerName))+ ";";;   
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($1.registerName));
                tempSet.freeRegister(*($3.registerName));   
            }
            else {
                cout << "Type mismatch in expression" << endl;
                $$.type = ERRORTYPE;
            }
        }
   
    }
    | TERM DIV FACTOR  
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
          $$.type = ERRORTYPE;  
        }
        else {
            if (arithmeticCompatible($1.type, $3.type)) {
                $$.type = compareTypes($1.type,$3.type);

                if ($1.type == INTEGER && $3.type == FLOATING) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ");";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ");";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " / " + (*($3.registerName))+ ";";;   
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($1.registerName));
                tempSet.freeRegister(*($3.registerName));   
            }
            else {
                cout << "Type mismatch in expression" << endl;
                $$.type = ERRORTYPE;
            }
        }   
    } 
    | FACTOR 
    { 
        $$.type = $1.type; 
        if ($1.type == ERRORTYPE) {
            errorFound = true;
        }
        else {
            $$.registerName = new string(*($1.registerName)); 
            delete $1.registerName;
        } 
    }
;

FACTOR: ID_ARR  
    { 
        $$.type = $1.type;
        if ($$.type == INTEGER)
            $$.registerName = new string(tempSet.getRegister());
        else $$.registerName = new string(tempSet.getFloatRegister());
        string s = (*($$.registerName)) + " = " + (*($1.registerName)) + ";";
        gen(functionInstruction, s, nextquad);
    }
    | NUMINT    
    { 
        $$.type = INTEGER; 
        $$.registerName = new string(tempSet.getRegister());
        string s = (*($$.registerName)) + " = " + string($1) + ";";
        gen(functionInstruction, s, nextquad);  
    }
    | NUMFLOAT  
    { 
        $$.type = FLOATING;
        $$.registerName = new string(tempSet.getFloatRegister());
        string s = (*($$.registerName)) + " = " + string($1) + ";";
        gen(functionInstruction, s, nextquad);  
    }
    | FUNC_CALL 
    { 
        // TODO revert back ehere when funccall is handled
        $$.type = callFuncPtr->returnType; 
        delete callFuncPtr;
    }
    | LP ASG RP 
    { 
        $$.type = $2.type; 
        if($2.registerName == NULL){
            cout << "String name in FACTOR : LP ASG RP is empty"<<endl;
        }
        else{
            $$.registerName = new string(*($2.registerName));
            delete $2.registerName;
        }
    } 
;

ID_ARR: ID
    {   
        // retrieve the highest level id with same name in param list or var list
        int found = 0;
        typeRecord* vn = NULL;
        searchVariable(string($1), activeFuncPtr, found, vn); 
        if(found){
            if (vn->type == SIMPLE) {
                $$.type = vn->eleType;
                $$.registerName = new string(string($1));
            }
            else {
                $$.type = ERRORTYPE;
                cout << $1 << " is declared as an array" << endl; 
            }
        }
        else {
            searchParam(string ($1), activeFuncPtr->parameterList, found, vn);
            if (found) {
                if (vn->type == SIMPLE) {
                    $$.type = vn->eleType;
                    $$.registerName = new string(string($1));
                }
                else {
                    $$.type = ERRORTYPE;
                    cout << $1 << " is declared as an array" << endl;
                }
            }
            else {
                $$.type = ERRORTYPE;
                cout << "Undeclared identifier " << $1 << endl;
            }
        }
    }
    | ID BR_DIMLIST
    {
        // retrieve the highest level id with same name in param list or var list
        int found = 0;
        typeRecord* vn = NULL;
        searchVariable(string($1), activeFuncPtr, found, vn); 
        if(found){
            if (vn->type == ARRAY) {
                if (dimlist.size() == vn->dimlist.size()) {
                    $$.type = vn->eleType;
                    // calculate linear address using dimensions then pass to FACTOR
                    int offset = 0;
                    for (int i = 0; i < vn->dimlist.size(); i++) {
                        offset += dimlist[i];
                        if (i != vn->dimlist.size()-1) offset *= vn->dimlist[i+1];  
                    }
                    string os = to_string(offset);
                    string s = string(*($1.registerName)) + "[" + os + "]";
                    $$.registerName = new string(s); 
                }
                else {
                    $$.type = ERRORTYPE;
                    cout << "Dimension mismatch: " << $1 << "should have %d dimensions" << endl;
                }
            }
            else {
                $$.type = ERRORTYPE;
                cout << $1 << " is declared as a singleton" << endl; 
            }
        }
        else {
            searchParam(string ($1), activeFuncPtr->parameterList, found, vn);
            if (found) {
                if (vn->type == ARRAY) {
                    if (dimlist.size() == vn->dimlist.size()) {
                        $$.type = vn->eleType;
                        // calculate linear address using dimensions then pass to FACTOR
                        int offset = 0;
                        for (int i = 0; i < vn->dimlist.size(); i++) {
                            offset += dimlist[i];
                            if (i != vn->dimlist.size()-1) offset *= vn->dimlist[i+1];  
                        }
                        string os = to_string(offset);
                        string s = *($1.registerName) + "[" + os + "]";
                        $$.registerName = new string(s); 
                    }
                    else {
                        $$.type = ERRORTYPE;
                        cout << "Dimension mismatch: " << $1 << "should have %d dimensions" << endl;
                    }
                }
                else {
                    $$.type = ERRORTYPE;
                    cout << $1 << " is declared as a singleton" << endl;
                }
            }
            else {
                $$.type = ERRORTYPE;
                cout << "Undeclared identifier " << $1 << endl;
            }
        }
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
    nextquad = 0;
    scope = 0;
    found = 0;
    errorFound=false;
    outinter = fopen("./output/intermediate.txt", "w");
    yyparse();
    if(!errorFound){
        for(auto it:functionInstruction){
            cout<<it<<endl;
        }
    } else {
        cout<<"exited without intermediate code generation"<<endl;
    }
}
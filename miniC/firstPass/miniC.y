%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
#include <iostream>
#include <vector>
#include <stack>
#include <stdio.h>
#include <algorithm>
#include <utility>
#include <fstream>
#include "funcTab.h"
#include "codegenHelpers.h"
using namespace std;

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(char* s);

int offsetCalc;
string text;
eletype resultType;
vector<typeRecord*> typeRecordList;
stack<vector<typeRecord*> > paramListStack;
typeRecord* varRecord;
vector<int> decdimlist;

int nextquad;
vector<string> functionInstruction;
registerSet tempSet;

vector<funcEntry*> funcEntryRecord;
funcEntry* activeFuncPtr;
funcEntry* callFuncPtr;
int scope;
int found;
bool errorFound;
int numberOfParameters;
string conditionVar;
vector<string> switchVar;
vector<funcEntry*> callFuncPtrList;
vector<string> dimlist;

vector<pair<string,int>> sVar;
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
    struct shortcircuit shortCircuit;
    struct switchcaser switchCase;
    struct switchtemp switchTemp;
    struct condition2temp ctemp;
}

%token INT FLOAT VOID NUMFLOAT NUMINT ID NEWLINE READ PRINT
%token COLON QUESTION DOT LCB RCB LSB RSB LP RP SEMI COMMA ASSIGN
%token IF ELSE CASE BREAK DEFAULT CONTINUE WHILE FOR RETURN SWITCH MAIN
%token LSHIFT RSHIFT PLUSASG MINASG MULASG MODASG DIVASG INCREMENT DECREMENT XOR BITAND BITOR PLUS MINUS DIV MUL MOD
%token NOT AND OR LT GT LE GE EQUAL NOTEQUAL

%type <idName> NUMFLOAT
%type <idName> NUMINT
%type <idName> ID
%type <expr> EXPR2 TERM FACTOR ID_ARR ASG ASG1 EXPR1 EXPR21 LHS FUNC_CALL BR_DIMLIST
%type <whileexpval> WHILEEXP IFEXP N3 P3 Q3 FOREXP TEMP1
%type <stmtval> BODY WHILESTMT IFSTMT M2 FORLOOP STMT STMT_LIST
%type <quad> M1 M3 Q4 
%type <shortCircuit> CONDITION1 CONDITION2
%type <switchCase> CASELIST
%type <switchTemp> TEMP2
%type <ctemp> TP1
%%

MAIN_PROG: PROG MAINFUNCTION
    | MAINFUNCTION
;

PROG: PROG FUNC_DEF
    | FUNC_DEF
;

MAINFUNCTION: MAIN_HEAD LCB BODY RCB
    {
        // Function(activeFuncPtr);
        deleteVarList(activeFuncPtr, scope);
        activeFuncPtr=NULL;
        scope=0;
        string s = "function end";
        gen(functionInstruction, s, nextquad);
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
        activeFuncPtr->variableList.clear();  
        activeFuncPtr->functionOffset = 0;      ;
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
            string s = "function begin main";
            gen(functionInstruction, s, nextquad);
        }
    }
;

FUNC_DEF: FUNC_HEAD LCB BODY RCB
    {
        // Function(activeFuncPtr);
        deleteVarList(activeFuncPtr, scope);
        activeFuncPtr=NULL;
        scope=0;
        string s = "function end";
        gen(functionInstruction, s, nextquad);
    }
;

FUNC_HEAD: RES_ID LP DECL_PLIST RP
    {
        activeFuncPtr->numOfParam = typeRecordList.size();
        activeFuncPtr->parameterList = typeRecordList;
        activeFuncPtr->functionOffset = 0;
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
            string s = "function begin _" + activeFuncPtr->name;
            gen(functionInstruction, s, nextquad);
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
    {
        $$.nextList = new vector<int>;
        merge($$.nextList, $1.nextList);
        $$.breakList = new vector<int>;
        merge($$.breakList, $1.breakList);
        $$.continueList = new vector<int>;
        merge($$.continueList, $1.continueList);
    }
    | %empty
;

STMT_LIST: STMT_LIST STMT 
        {
            $$.nextList = new vector<int>;
            merge($$.nextList, $1.nextList);
            merge($$.nextList, $2.nextList);
            $$.breakList = new vector<int>;
            merge($$.breakList, $1.breakList);
            merge($$.breakList, $2.breakList);
            $$.continueList = new vector<int>;
            merge($$.continueList, $1.continueList);
            merge($$.continueList, $2.continueList);
        }
    | STMT 
    {
        $$.nextList = new vector<int>;
        merge($$.nextList, $1.nextList);
        $$.breakList = new vector<int>;
        merge($$.breakList, $1.breakList);
        $$.continueList = new vector<int>;
        merge($$.continueList, $1.continueList);
    }
;

STMT: VAR_DECL{
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
}
    | ASG SEMI
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        if ($1.type != NULLVOID && $1.type != ERRORTYPE)
            tempSet.freeRegister(*($1.registerName));
    } 
    | FORLOOP{
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
    }
    | IFSTMT{
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
    }
    | WHILESTMT{
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
    }
    | SWITCHCASE{
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
    }
    | LCB {scope++;} BODY RCB 
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        deleteVarList(activeFuncPtr, scope);
        scope--;
    }
    | BREAK SEMI{
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.breakList->push_back(nextquad);  
        gen(functionInstruction, "goto L", nextquad);      
    }
    | CONTINUE SEMI{
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.continueList->push_back(nextquad);
        gen(functionInstruction, "goto L", nextquad);
    }
    | RETURN ASG SEMI 
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        if ($2.type != ERRORTYPE) {
            if (activeFuncPtr->returnType == NULLVOID && $2.type != NULLVOID) {
                cout<<"The function "<< activeFuncPtr->name<<" has void return type"<<endl;
            }
            else if (activeFuncPtr->returnType != NULLVOID && $2.type == NULLVOID) {
                cout<<"The function "<< activeFuncPtr->name<<" must have a"<<" return type"<<endl;
            }
            else {
                string s;
                if ($2.type != NULLVOID) {
                    s = "return " + (*($2.registerName));
                    tempSet.freeRegister(*($2.registerName));
                }
                else {
                    s = "return";
                }
                gen(functionInstruction, s, nextquad);
            }
        }   
    }
    | READ ID_ARR SEMI
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        if($2.type == ERRORTYPE){
            errorFound = true;
        }
        else{
            string registerName;
            if ($2.type == INTEGER){
                registerName = tempSet.getRegister();
            }
            else {
                registerName = tempSet.getFloatRegister();
            }
            string s = registerName + " = " + (*($2.registerName)) ;
            gen(functionInstruction, s, nextquad);
            s = "read " + registerName;
            gen(functionInstruction, s, nextquad);
            s = (*($2.registerName)) + " = " +  registerName;
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(registerName);
            if ($2.offsetRegName != NULL) tempSet.freeRegister(*($2.offsetRegName));
        }
    }
    | PRINT ID_ARR SEMI
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        if($2.type == ERRORTYPE){
            errorFound = true;
        }
        else{
            string registerName;
            if ($2.type == INTEGER){
                registerName = tempSet.getRegister();
            }
            else {
                registerName = tempSet.getFloatRegister();
            }
            string s = registerName + " = " + (*($2.registerName)) ;
            gen(functionInstruction, s, nextquad);
            s = "print " + registerName;
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(registerName);
            if ($2.offsetRegName != NULL) tempSet.freeRegister(*($2.offsetRegName));
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
        searchVariable(string($1), activeFuncPtr, found, vn, scope);
        if (found) {
            if(vn->isValid==true){
                printf("Variable %s already declared at same level %d\n", $1, scope);
            }
            else{
                if(vn->eleType == resultType){
                    vn->isValid=true;
                    vn->maxDimlistOffset = max(vn->maxDimlistOffset,1);
                    vn->type=SIMPLE;
                }
                else {
                    varRecord = new typeRecord;
                    varRecord->name = string($1);
                    varRecord->type = SIMPLE;
                    varRecord->tag = VARIABLE;
                    varRecord->scope = scope;
                    varRecord->isValid=true;
                    varRecord->maxDimlistOffset=1;
                    typeRecordList.push_back(varRecord);
                }
            }
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
                varRecord->isValid=true;
                varRecord->maxDimlistOffset=1;
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
            varRecord->isValid=true;
            varRecord->maxDimlistOffset=1;
            // cout<<"variable name: "<<varRecord->name<<endl;
            typeRecordList.push_back(varRecord);
        }
    }
    | ID ASSIGN ASG
    {
        int found = 0;
        typeRecord* vn = NULL;
        // cout << "Scope : "<<scope<<endl;
        searchVariable(string($1), activeFuncPtr, found, vn, scope);
        if (found) {
            if(vn->isValid==true){
                printf("Variable %s already declared at same level %d\n", $1, scope);
            }
            else{
                if(vn->eleType == resultType){
                    vn->isValid=true;
                    vn->maxDimlistOffset = max(vn->maxDimlistOffset,1);
                    vn->type=SIMPLE;
                }
                else {
                    varRecord = new typeRecord;
                    varRecord->name = string($1);
                    varRecord->type = SIMPLE;
                    varRecord->tag = VARIABLE;
                    varRecord->scope = scope;
                    varRecord->isValid=true;
                    varRecord->maxDimlistOffset=1;
                    typeRecordList.push_back(varRecord);
                }
            }
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
                varRecord->maxDimlistOffset=1;
                varRecord->isValid=true;
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
            varRecord->maxDimlistOffset=1;
            varRecord->isValid=true;
            // cout<<"variable name: "<<varRecord->name<<endl;
            typeRecordList.push_back(varRecord);
        }
    }
    | ID DEC_BR_DIMLIST
    {  
        int found = 0;
        typeRecord* vn = NULL;
        searchVariable(string($1), activeFuncPtr, found, vn,scope); 
        if (found) {
            if(vn->isValid==true){
                printf("Variable %s already declared at same level %d\n", $1, scope);
            }
            else{
                if(vn->eleType == resultType){
                    vn->isValid=true;
                    int a=1;
                    for(auto it : decdimlist){
                        a*=(it);
                    }
                    vn->maxDimlistOffset = max(vn->maxDimlistOffset,a);
                    if(vn->type==ARRAY){
                        vn->dimlist.clear();           
                    }
                    vn->type=ARRAY;
                    vn->dimlist = decdimlist;
                }
                else {
                    varRecord = new typeRecord;
                    varRecord->name = string($1);
                    varRecord->type = ARRAY;
                    varRecord->tag = VARIABLE;
                    varRecord->scope = scope;
                    varRecord->dimlist = decdimlist;
                    varRecord->isValid=true;
                    int a=1;
                    for(auto it : decdimlist){
                        a*=(it);
                    }
                    varRecord->maxDimlistOffset = a;
                    // cout<<"variable name: "<<varRecord->name<<endl;
                    typeRecordList.push_back(varRecord);
                }
            }
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
                varRecord->dimlist = decdimlist;
                varRecord->isValid=true;
                int a=1;
                for(auto it : decdimlist){
                    a*=(it);
                }
                varRecord->maxDimlistOffset = a;
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
            varRecord->dimlist = decdimlist;
            varRecord->isValid=true;
            int a=1;
            for(auto it : decdimlist){
                a*=(it);
            }
            varRecord->maxDimlistOffset = a;
            typeRecordList.push_back(varRecord);
        }
        decdimlist.clear();  
    } 
;

DEC_BR_DIMLIST: LSB NUMINT RSB
    {
        decdimlist.push_back(atoi($2));
    }
    | DEC_BR_DIMLIST LSB NUMINT RSB 
    {
        decdimlist.push_back(atoi($3));
    }
;

FUNC_CALL: ID LP PARAMLIST RP
    {
        callFuncPtr = new funcEntry;
        callFuncPtr->name = string($1);
        callFuncPtr->parameterList = typeRecordList;
        callFuncPtr->numOfParam = typeRecordList.size();
        int found = 0;
        // printFunction(activeFuncPtr);
        // printFunction(callFuncPtr);
        compareFunc(callFuncPtr,funcEntryRecord,found);
        $$.type = ERRORTYPE;
        if (found == 0) {
            cout << "No function with name " << string($1) << " exists" << endl;
        }
        else if (found == -1) {
            cout << "Parameter list does not match with defined paramters of function " << string($1) << endl;
        }
        else {
            $$.type = callFuncPtr->returnType;
            int isRefParam = 0;
            if(callFuncPtr->returnType == INTEGER){
                $$.registerName = new string(tempSet.getRegister());
                isRefParam++;
            }
            else if(callFuncPtr->returnType == FLOATING){
                $$.registerName = new string(tempSet.getFloatRegister());
                isRefParam++;
            }
            gen(functionInstruction, "refparam " + (*($$.registerName)), nextquad);
            gen(functionInstruction, "call _" + callFuncPtr->name + ", " + to_string(typeRecordList.size() + isRefParam ), nextquad);       
        }
        typeRecordList.clear();
        typeRecordList.swap(paramListStack.top());
        paramListStack.pop();
    }
;

PARAMLIST: PLIST
    | %empty 
;

PLIST: PLIST COMMA ASG
    {
        varRecord = new typeRecord;
        varRecord->eleType = $3.type;
        if ($3.type == ERRORTYPE) {
            errorFound = true;
        }
        else {
            varRecord->name = *($3.registerName);
            varRecord->type = SIMPLE;
            gen(functionInstruction, "param " +  *($3.registerName), nextquad);   
            tempSet.freeRegister(*($3.registerName));
        }
        typeRecordList.push_back(varRecord);
    }
    | {paramListStack.push(typeRecordList); typeRecordList.clear();} ASG
    {
        varRecord = new typeRecord;
        varRecord->eleType = $2.type;
        if ($2.type == ERRORTYPE) {
            errorFound = true;
        }
        else {
            varRecord->name = *($2.registerName);
            varRecord->type = SIMPLE; 
            gen(functionInstruction, "param " +  *($2.registerName), nextquad);   
            tempSet.freeRegister(*($2.registerName));
        }
        typeRecordList.push_back(varRecord);
    }
;

ASG: CONDITION1
    {
        $$.type = $1.type;
        if($$.type != ERRORTYPE) {
            $$.registerName = $1.registerName;
            // backpatch($1.jumpList, nextquad, functionInstruction);
            // gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
            if($1.jumpList!=NULL){
                vector<int>* qList = new vector<int>;
                // gen(functionInstruction,(*($$.registerName)) + " = 0",nextquad) ;
                qList->push_back(nextquad);
                gen(functionInstruction,"goto L",nextquad);
                backpatch($1.jumpList, nextquad, functionInstruction);
                gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
                gen(functionInstruction,(*($$.registerName)) + " = 1",nextquad) ;
                backpatch(qList,nextquad,functionInstruction);
                qList->clear();
                gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
            }
        }
    }
    | LHS ASSIGN ASG
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else if ($3.type == NULLVOID) {
            cout << "Cannot assign void to non-void type " << *($1.registerName) << endl;
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else {
            $$.type = $1.type;
            string registerName;
            if ($1.type == INTEGER && $3.type == FLOATING) {
                registerName = tempSet.getRegister();
                string s = registerName + " = convertToInt(" + (*($3.registerName)) + ")";   
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($3.registerName));
            }
            else if($1.type == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                registerName = tempSet.getFloatRegister();
                string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")";   
                gen(functionInstruction, s, nextquad); 
                tempSet.freeRegister(*($3.registerName));
            }
            else {
                registerName = *($3.registerName);
            }
            string s = (*($1.registerName)) + " = " + registerName ;
            gen(functionInstruction, s, nextquad);
            $$.registerName = new string(registerName);
            if ($1.offsetRegName != NULL) tempSet.freeRegister(*($1.offsetRegName));
        }
    }
    | LHS PLUSASG ASG
    | LHS MINASG ASG
    | LHS MULASG ASG
    | LHS DIVASG ASG
    | LHS MODASG ASG
;

LHS: ID_ARR  
    {
        $$.type = $1.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $1.registerName;
            $$.offsetRegName = $1.offsetRegName;
        } 
    } 
;

SWITCHCASE: SWITCH LP ASG RP TEMP1 LCB  CASELIST RCB 
    {
        deleteVarList(activeFuncPtr,scope);
        scope--;

        int q=nextquad;
        vector<int>* qList = new vector<int>;
        qList->push_back(q);
        gen(functionInstruction, "goto L", nextquad);
        backpatch($5.falseList, nextquad, functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        reverse($7.casepair->begin(), $7.casepair->end());
        for(auto it : *($7.casepair)){
            if(it.first == "default"){
                gen(functionInstruction, "goto L"+to_string(it.second), nextquad);
                // break;
            }
            else{
                gen(functionInstruction, "if "+ (*($3.registerName)) +" == "+ it.first + " goto L" + to_string(it.second), nextquad);
            }
            // tempSet.freeRegister(it.first);            
        }
        $7.casepair->clear();
        backpatch(qList, nextquad, functionInstruction);
        backpatch($7.breakList, nextquad, functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        
        // switchVar.pop_back();
        // tempSet.freeRegister(*($3.registerName));
        
        // gen(functionInstruction, "L" + to_string(nextquad)+":", nextquad);
    }
;

TEMP1: %empty
    {
        // string varName = switchVar[switchVar.size()-1]; 
        $$.begin=nextquad;
        $$.falseList = new vector<int>;
        $$.falseList->push_back(nextquad);
        gen(functionInstruction, "goto L", nextquad);
        // gen(functionInstruction, "if "+ varName +" != "+ conditionVar + " goto L", nextquad);   
        // tempSet.freeRegister(conditionVar);
        scope++;

    }
;

TEMP2:%empty
    {
        $$.casepair = new vector<pair<string,int>>;

    }
;

CASELIST:
    CASE MINUS NUMINT TEMP2 {
        // sVar.push_back(make_pair(string($2), nextquad));
        $4.casepair->push_back(make_pair("-"+string($3), nextquad));
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        } COLON BODY 
    CASELIST
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.casepair = new vector<pair<string,int>>;
        // $$.casepair->push_back(make_pair(string($2), nextquad));
        merge($$.continueList,$8.continueList);
        merge($$.breakList, $8.breakList);
        merge($$.nextList, $8.nextList);
        merge($$.continueList,$7.continueList);
        merge($$.breakList, $7.breakList);
        merge($$.nextList, $7.nextList);
        mergeSwitch($$.casepair, $8.casepair);
        mergeSwitch($$.casepair, $4.casepair);
        // sVar.clear();
    }
    |
    CASE NUMINT TEMP2 {
        // sVar.push_back(make_pair(string($2), nextquad));
        $3.casepair->push_back(make_pair(string($2), nextquad));
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        } COLON BODY 
    CASELIST
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.casepair = new vector<pair<string,int>>;
        // $$.casepair->push_back(make_pair(string($2), nextquad));
        merge($$.continueList,$6.continueList);
        merge($$.breakList, $6.breakList);
        merge($$.nextList, $6.nextList);
        merge($$.continueList,$7.continueList);
        merge($$.breakList, $7.breakList);
        merge($$.nextList, $7.nextList);
        mergeSwitch($$.casepair, $7.casepair);
        mergeSwitch($$.casepair, $3.casepair);
        // sVar.clear();
    }
    | %empty
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.casepair = new vector<pair<string,int>>;
    }
    | DEFAULT COLON TEMP2 {
        $3.casepair->push_back(make_pair("default", nextquad));
        // sVar.push_back(make_pair("default", nextquad));
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
     BODY {
        // gen(functionInstruction, "L" + to_string(nextquad)+":", nextquad);
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.casepair = new vector<pair<string,int>>;
        $$.continueList = new vector <int>;
        merge($$.continueList,$5.continueList);
        merge($$.breakList, $5.breakList);
        merge($$.nextList, $5.nextList);
        mergeSwitch($$.casepair, $3.casepair);
        // sVar.clear();
    }
;

M3: %empty { 
        $$ = nextquad;
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad); 
    }
;

N3: %empty { 
    $$.begin = nextquad; 
    $$.falseList = new vector<int>;
    $$.falseList->push_back(nextquad);
    gen(functionInstruction, "goto L", nextquad);
    }
;

P3: %empty { 
    $$.falseList = new vector<int>;
    $$.falseList->push_back(nextquad);
    gen(functionInstruction, "goto L", nextquad);
    $$.begin = nextquad; 
    gen(functionInstruction, "L"+to_string(nextquad)+":", nextquad);
    }
;

Q3: %empty
    {
        $$.begin = nextquad;
        $$.falseList = new vector<int>;
        $$.falseList->push_back(nextquad);
    }
;

Q4: %empty
    {
        $$ = nextquad;
    }
;

FORLOOP: FOREXP Q4 LCB BODY RCB
    {
        deleteVarList(activeFuncPtr, scope);
        scope--;
        gen(functionInstruction, "goto L" + to_string($1.begin), nextquad); 
        merge($1.falseList,$4.breakList);
        backpatch($4.continueList,$1.begin, functionInstruction);
        backpatch($1.falseList, nextquad, functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad); 
    }
;

FOREXP: FOR LP ASG1 SEMI M3 ASG1 Q3 {
        if($6.type!=NULLVOID){
            gen(functionInstruction, "if "+ (*($6.registerName)) + " == 0 goto L", nextquad);
        }
    } P3 SEMI ASG1 N3 RP 
    {
        backpatch($12.falseList,$5,functionInstruction);
        backpatch($9.falseList,nextquad,functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad); 
        $$.falseList = new vector<int>;
        if($6.type!=NULLVOID){
            $$.falseList->push_back($7.begin);            
        }
        $$.begin = $9.begin;
        scope++;
        if($3.type!=NULLVOID){
            tempSet.freeRegister(*($3.registerName));
        }
        tempSet.freeRegister(*($3.registerName));
        if($6.type!=NULLVOID){
            tempSet.freeRegister(*($6.registerName));
        }
        if($11.type!=NULLVOID){
            tempSet.freeRegister(*($11.registerName));
        }
    }
;

ASG1: ASG
    {
        $$.type= $1.type;
        if ($$.type == ERRORTYPE) {
            $$.registerName = $1.registerName;
        }
    }
    | %empty {
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
        $$.nextList = new vector<int>;
        ($$.nextList)->push_back(nextquad);
        gen(functionInstruction, "goto L", nextquad);
    }
;

IFSTMT: IFEXP LCB BODY RCB 
    {
        // cout<<"Test1"<<endl;
        deleteVarList(activeFuncPtr,scope);
        // cout<<"Test2"<<endl;
        scope--;
        $$.nextList= new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList= new vector<int>;
        merge($$.nextList, $1.falseList);
        // cout<<"Test5"<<endl;
        merge($$.breakList, $3.breakList);
        // cout<<"Test6"<<endl;
        merge($$.continueList, $3.continueList);
        // cout<<"Test3"<<endl;
        backpatch($$.nextList,nextquad,functionInstruction);
        // cout<<"Test4"<<endl;
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
    | IFEXP LCB BODY RCB {deleteVarList(activeFuncPtr,scope);} M2 ELSE M1 LCB BODY RCB
    {
        deleteVarList(activeFuncPtr,scope);
        scope--;
        $$.nextList= new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList= new vector<int>;
        backpatch($1.falseList,$8,functionInstruction);
        // cout<<"test6"<<endl;
        merge($$.nextList,$6.nextList );
        // cout<<"test7"<<endl;
        backpatch($$.nextList,nextquad,functionInstruction);
        // cout<<"test8"<<endl;
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        // cout<<"test9"<<endl;
        merge($$.breakList, $3.breakList);
        // cout<<"test10"<<endl;
        merge($$.continueList, $3.continueList);
        // cout<<"test11"<<endl;
        merge($$.breakList, $10.breakList);
        // cout<<"test12"<<endl;
        merge($$.continueList, $10.continueList);
        // cout<<"test13"<<endl;
    }
;

IFEXP: IF LP ASG RP 
    {
        if($3.type != ERRORTYPE && $3.type!=NULLVOID){
            $$.falseList = new vector <int>;
            $$.falseList->push_back(nextquad);
            if($3.type == NULLVOID){
                cout<<"Expression in if statement can't be empty"<<endl;
                errorFound=true;
            }
            gen(functionInstruction, "if "+ (*($3.registerName)) + " == 0 goto L", nextquad);
            scope++;
            tempSet.freeRegister(*($3.registerName));
        } 
    }
;

WHILESTMT:  WHILEEXP LCB BODY RCB 
    {
        deleteVarList(activeFuncPtr,scope);
        scope--;

        gen(functionInstruction, "goto L" + to_string($1.begin), nextquad);
        backpatch($3.nextList, $1.begin, functionInstruction);
        backpatch($3.continueList, $1.begin, functionInstruction);
        $$.nextList = new vector<int>;
        merge($$.nextList, $1.falseList);
        merge($$.nextList, $3.breakList);
        backpatch($$.nextList,nextquad,functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
;

WHILEEXP: WHILE M1 LP ASG RP
    {
        scope++;
        if($4.type == NULLVOID || $4.type == ERRORTYPE){
            cout<<"Expression in if statement can't be empty"<<endl;
            errorFound = true;
        }
        else{
            $$.falseList = new vector<int>;
            ($$.falseList)->push_back(nextquad);
            gen(functionInstruction, "if " + *($4.registerName) + "== 0 goto L", nextquad);
            $$.begin = $2; 
        }
    }
;

TP1: %empty
{
    $$.temp = new vector<int>;
}
;

CONDITION1: CONDITION1 TP1
    {
        if($1.type!=ERRORTYPE){
            $2.temp->push_back(nextquad);
            gen(functionInstruction, "if " + *($1.registerName) + "!= 0 goto L", nextquad);

        }
    }
     OR CONDITION2
    {
        if($1.type==ERRORTYPE || $5.type==ERRORTYPE){
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());
            vector<int>* qList = new vector<int>;
            if($5.jumpList!=NULL){
                // gen(functionInstruction,(*($$.registerName)) + " =  x 1",nextquad) ;
                qList->push_back(nextquad);
                gen(functionInstruction,"goto L",nextquad);
                backpatch($5.jumpList, nextquad, functionInstruction);
                gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
                gen(functionInstruction,(*($5.registerName)) + " = 0",nextquad) ;
                backpatch(qList,nextquad,functionInstruction);
                gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
                qList->clear();
            }
            
            $$.jumpList = new vector<int>;
            merge($$.jumpList,$1.jumpList);
            
            
            // ($$.jumpList)->push_back(nextquad);
            // gen(functionInstruction, "if " + *($1.registerName) + "!= 0 goto L", nextquad);
            merge($$.jumpList, $2.temp);
            ($$.jumpList)->push_back(nextquad);
            gen(functionInstruction, "if " + *($5.registerName) + "!= 0 goto L", nextquad);
            string s = (*($$.registerName)) + " = 0";   
            gen(functionInstruction,s,nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($5.registerName)); 
        }
    }
    | CONDITION2
    {
        $$.type = $1.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $1.registerName; 
            if($1.jumpList!=NULL){
                vector<int>* qList = new vector<int>;
                qList->push_back(nextquad);
                gen(functionInstruction,"goto L",nextquad);
                backpatch($1.jumpList, nextquad, functionInstruction);
                gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
                gen(functionInstruction,(*($$.registerName)) + " = 0",nextquad) ;
                backpatch(qList,nextquad,functionInstruction);
                gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
                qList->clear();   
            }
        }
    }
;  


CONDITION2: CONDITION2 TP1
    {
      if ($1.type!=ERRORTYPE ){

          ($2.temp)->push_back(nextquad);
         gen(functionInstruction, "if " + *($1.registerName) + " == 0 " +" goto L", nextquad);
      } 
    }
    AND EXPR1 
    {
        if ($1.type==ERRORTYPE || $5.type==ERRORTYPE) {
            $$.type = ERRORTYPE;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());
            $$.jumpList = new vector<int>;
            merge($$.jumpList,$1.jumpList);
            vector<int>* qList = new vector<int>;
            
            // ($$.jumpList)->push_back(nextquad);
            // gen(functionInstruction, "if " + *($1.registerName) + " == 0 " +" goto L", nextquad);
            merge($$.jumpList, $2.temp);
            ($$.jumpList)->push_back(nextquad);
            gen(functionInstruction, "if " + *($5.registerName) + " == 0 "+" goto L", nextquad);

            string s = (*($$.registerName)) + " = 1";   
            gen(functionInstruction,s,nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($5.registerName));   
        }
    }
    | EXPR1
    {
        $$.type = $1.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $1.registerName; 
            $$.jumpList = new vector<int>;
            $$.jumpList=NULL;   
        }
    }
;

EXPR1: NOT EXPR21
    {
        $$.type = $2.type;
        if ($$.type != ERRORTYPE) {
            $$.registerName = $2.registerName;
            string s = (*($$.registerName)) + " = ~" + (*($2.registerName));   
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
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " == " + (*($3.registerName))   ;
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
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " != " + (*($3.registerName));   
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
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " < " + (*($3.registerName));   
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
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " > " + (*($3.registerName));   
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    }
    | EXPR2 LE EXPR2
    {
        if($1.type == ERRORTYPE || $3.type == ERRORTYPE){
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());     
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " <= " + (*($3.registerName));   
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
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " >= " + (*($3.registerName));  
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(*($1.registerName));
            tempSet.freeRegister(*($3.registerName));  
        }   
    } 
    | EXPR2 
    {
        $$.type = $1.type; 
        if($$.type == ERRORTYPE){
            errorFound = true;
        }
        else{
            $$.registerName = new string(*($1.registerName)); 
            delete $1.registerName; 
        }    
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
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ")";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " + " + (*($3.registerName));;   
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
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ")";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " - " + (*($3.registerName));;   
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
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ")";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " * " + (*($3.registerName));;   
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
                    string s = newReg + " = " + "convertToFloat(" + (*($1.registerName)) + ")";
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    tempSet.freeRegister(*($3.registerName));
                    $3.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }

                if ($$.type == INTEGER) 
                    $$.registerName = new string(tempSet.getRegister());
                else
                    $$.registerName = new string(tempSet.getFloatRegister());
                    
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " / " + (*($3.registerName));   
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
    | TERM MOD FACTOR
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
          $$.type = ERRORTYPE;  
        }
        else {
            if ($1.type == INTEGER && $3.type == INTEGER) {
                $$.type = INTEGER;
                $$.registerName = new string(tempSet.getRegister());  
                string s = (*($$.registerName)) + " = " + (*($1.registerName)) + " % " + (*($3.registerName));;   
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
        string s = (*($$.registerName)) + " = " + (*($1.registerName)) ;
        gen(functionInstruction, s, nextquad);
        if($1.offsetRegName != NULL){
            tempSet.freeRegister((*($1.offsetRegName)));
        }
    }
    | MINUS ID_ARR
    {
        $$.type = $2.type;
        if ($$.type == INTEGER)
            $$.registerName = new string(tempSet.getRegister());
        else $$.registerName = new string(tempSet.getFloatRegister());
        string s = (*($$.registerName)) + " = -" + (*($2.registerName)) ;
        gen(functionInstruction, s, nextquad);
        if($2.offsetRegName != NULL){
            tempSet.freeRegister((*($2.offsetRegName)));
        }
    }
    | MINUS NUMINT
    {
        $$.type = INTEGER; 
        $$.registerName = new string(tempSet.getRegister());
        string s = (*($$.registerName)) + " = -" + string($2) ;
        gen(functionInstruction, s, nextquad);  
    }
    | NUMINT    
    { 
        $$.type = INTEGER; 
        $$.registerName = new string(tempSet.getRegister());
        string s = (*($$.registerName)) + " = " + string($1) ;
        gen(functionInstruction, s, nextquad);  
    }
    | MINUS NUMFLOAT
    {
        $$.type = FLOATING;
        $$.registerName = new string(tempSet.getFloatRegister());
        string s = (*($$.registerName)) + " = " + string($2) ;
        gen(functionInstruction, s, nextquad);     
    }
    | NUMFLOAT  
    { 
        $$.type = FLOATING;
        $$.registerName = new string(tempSet.getFloatRegister());
        string s = (*($$.registerName)) + " = " + string($1) ;
        gen(functionInstruction, s, nextquad);  
    }
    | FUNC_CALL 
    { 
        $$.type = $1.type; 
        if($1.type != ERRORTYPE && $1.type != NULLVOID){
            $$.registerName = $1.registerName;
            delete callFuncPtr;
        }
    }
    | LP ASG RP 
    { 
        $$.type = $2.type; 
        if ($2.type != ERRORTYPE) {
            $$.registerName = $2.registerName;
        }
    }
    | ID_ARR INCREMENT
    {
        if ($1.type == INTEGER) {
            $$.type = INTEGER;   
            string newReg = tempSet.getRegister();
            $$.registerName = new string(newReg); 
            string s = newReg + " = " + (*($1.registerName)) ;
            gen(functionInstruction, s, nextquad); // T2 = i
            string newReg2 = tempSet.getRegister();
            s = newReg2 + " = " + newReg + " + 1"; // T3 = T2+1
            gen(functionInstruction, s, nextquad);
            s = (*($1.registerName)) + " = " + newReg2; // i = T3
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(newReg2);
            if($1.offsetRegName != NULL){
                tempSet.freeRegister((*($1.offsetRegName)));
            }
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
            string s = newReg + " = " + (*($1.registerName)); // T0 = i
            gen(functionInstruction, s, nextquad);
            string newReg2 = tempSet.getRegister();
            s = newReg2 + " = " + newReg + " - 1"; // T3 = T2+1
            gen(functionInstruction, s, nextquad);
            s = (*($1.registerName)) + " = " + newReg2; // i = T3
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(newReg2); 
            if($1.offsetRegName != NULL){
                tempSet.freeRegister((*($1.offsetRegName)));
            }    
        }
        else {
            $$.type = ERRORTYPE;
            cout << "Cannot increment non-integer type variable " << *($1.registerName) << endl; 
        }
    } 
    | INCREMENT ID_ARR
    {
        if ($2.type == INTEGER) {
            $$.type = INTEGER;   
            string newReg = tempSet.getRegister();
            string s = newReg + " = " + (*($2.registerName)); // T2 = i
            gen(functionInstruction, s, nextquad);
            string newReg2 = tempSet.getRegister();
            $$.registerName = new string(newReg2);
            s = newReg2 + " = " + newReg + " + 1"; // T3 = T2+1
            gen(functionInstruction, s, nextquad);
            s = (*($2.registerName)) + " = " + newReg2; // i = T3
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(newReg); 
            if($2.offsetRegName != NULL){
                tempSet.freeRegister((*($2.offsetRegName)));
            }     
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
            string s = newReg + " = " + (*($2.registerName)); // T2 = i
            gen(functionInstruction, s, nextquad);
            string newReg2 = tempSet.getRegister();
            $$.registerName = new string(newReg2);
            s = newReg2 + " = " + newReg + " - 1"; // T3 = T2+1
            gen(functionInstruction, s, nextquad);
            s = (*($2.registerName)) + " = " + newReg2; // i = T3
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(newReg);
            if($2.offsetRegName != NULL){
                tempSet.freeRegister((*($2.offsetRegName)));
            }         
        }
        else {
            $$.type = ERRORTYPE;
            cout << "Cannot increment non-integer type variable" << endl; 
        }
    }
;

ID_ARR: ID
    {   
        // retrieve the highest level id with same name in param list or var list
        int found = 0;
        typeRecord* vn = NULL;
        searchCallVariable(string($1), activeFuncPtr, found, vn); 
        $$.offsetRegName = NULL;
        if(found){
            if (vn->type == SIMPLE) {
                $$.type = vn->eleType;
                string dataType = eletypeMapper($$.type);
                dataType += "_" + to_string(vn->scope);
                $$.registerName = new string("_" + string($1) + "_" + dataType);
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
                    string dataType = eletypeMapper($$.type);
                    dataType += "_" + to_string(vn->scope);
                    $$.registerName = new string("_" + string($1) + "_" + dataType);
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
        $$.offsetRegName = NULL; 
        if($2.type == ERRORTYPE){
            errorFound = true;
            $$.type = ERRORTYPE;
        }
        else{
            searchCallVariable(string($1), activeFuncPtr, found, vn); 
            if(found){
                if (vn->type == ARRAY) {
                    if (dimlist.size() == vn->dimlist.size()) {
                        $$.type = vn->eleType;
                        // calculate linear address using dimensions then pass to FACTOR
                        string offsetRegister = tempSet.getRegister();
                        string dimlistRegister = tempSet.getRegister();
                        string s = offsetRegister + " = 0";
                        gen(functionInstruction, s, nextquad);
                        for (int i = 0; i < vn->dimlist.size(); i++) {
                            s = offsetRegister + " = " + offsetRegister + " + " + dimlist[i];
                            gen(functionInstruction, s, nextquad);
                            // offset += dimlist[i];
                            if (i != vn->dimlist.size()-1) {
                                // offset *= vn->dimlist[i+1];
                                s = dimlistRegister + " = " + to_string(vn->dimlist[i+1]);
                                gen(functionInstruction, s, nextquad);                                
                                s = offsetRegister + " = " + offsetRegister + " * " + dimlistRegister;
                                gen(functionInstruction, s, nextquad);
                            }
                            tempSet.freeRegister(dimlist[i]);
                        }
                        string dataType = eletypeMapper($$.type);
                        dataType += "_" + to_string(vn->scope); 
                        s = "_" + string($1) + "_" + dataType ;
                        s += "[" + offsetRegister + "]";
                        $$.registerName = new string(s);
                        tempSet.freeRegister(dimlistRegister);
                        $$.offsetRegName = new string(offsetRegister);
                        
                    }
                    else {
                        $$.type = ERRORTYPE;
                        cout << "Dimension mismatch: " << $1 << " should have " << dimlist.size() <<" dimensions" << endl;
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
                // searchParam(string ($1), activeFuncPtr->parameterList, found, vn);
                // if (found) {
                //     if (vn->type == ARRAY) {
                //         if (dimlist.size() == vn->dimlist.size()) {
                //             $$.type = vn->eleType;
                //             // calculate linear address using dimensions then pass to FACTOR
                //             int offset = 0;
                //             for (int i = 0; i < vn->dimlist.size(); i++) {
                //                 offset += dimlist[i];
                //                 if (i != vn->dimlist.size()-1) offset *= vn->dimlist[i+1];  
                //             }
                //             string os = to_string(offset);
                //             string dataType = eletypeMapper($$.type);
                //             dataType += "_" + to_string(vn->scope);
                //             string s = "_" + string($1) + "_" + dataType;
                //             // string s = string($1) + "[" + os + "]";
                //             $$.registerName = new string(s); 
                //         }
                //         else {
                //             $$.type = ERRORTYPE;
                //             cout << "Dimension mismatch: " << $1 << " should have " << dimlist.size() << " dimensions" << endl;
                //         }
                //     }
                //     else {
                //         $$.type = ERRORTYPE;
                //         cout << $1 << " is declared as a singleton" << endl;
                //     }
                // }
                // else {
                //     $$.type = ERRORTYPE;
                //     cout << "Undeclared identifier " << $1 << endl;
                // }
            }
            dimlist.clear();
        }
    }
;

BR_DIMLIST: LSB ASG RSB
    {
        if ($2.type == INTEGER) {
            dimlist.push_back(*($2.registerName));
        }
        else {
            cout << "One of the dimension of an array cannot be evaluated to integer" << endl;
        }
    }   
    | BR_DIMLIST LSB ASG RSB 
    {
        if ($3.type == INTEGER) {
            dimlist.push_back(*($3.registerName));
        }
        else {
            cout << "One of the dimension of an array cannot be evaluated to integer" << endl;
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
    offsetCalc = 0;
    errorFound=false;
    switchVar.clear();
    dimlist.clear();
    
    if( remove( "tempInter.txt" ) != 0 )
    {
    }
    yyparse();
    if( remove( "./output/intermediate.txt" ) != 0 )
    {
    }
    populateOffsets(funcEntryRecord);
    ofstream outinter;
    outinter.open("./output/intermediate.txt");
    if(1){
        for(auto it:functionInstruction){
            outinter<<it<<endl;
        }
    } else {
        cout<<"exited without intermediate code generation"<<endl;
    }
    outinter.close();
}
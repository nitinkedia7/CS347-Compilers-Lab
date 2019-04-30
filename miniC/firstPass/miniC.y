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
#define YYERROR_VERBOSE 1

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(const char* s);

int offsetCalc;
string text;
eletype resultType;
vector<typeRecord*> typeRecordList;
stack<vector<typeRecord*> > paramListStack;
typeRecord* varRecord;
vector<int> decdimlist;
vector<typeRecord*> globalVariables;

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
    | PROG VAR_DECL
    | FUNC_DEF
    | VAR_DECL
;

MAINFUNCTION: MAIN_HEAD LCB BODY RCB
    {
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Function " << activeFuncPtr->name <<  " already declared." << endl;
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
        deleteVarList(activeFuncPtr, scope);   
        activeFuncPtr = NULL;
        scope = 0;
        string s = "function end";
        gen(functionInstruction, s, nextquad);
    }
;

FUNC_HEAD: RES_ID LP DECL_PLIST RP
    {
        int found = 0;
        searchFunc(activeFuncPtr, funcEntryRecord, found);
        if(found){
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Function " << activeFuncPtr->name <<  " already declared." << endl;
            errorFound = true;
            delete activeFuncPtr;
            // cout<<"Function head me activeFuncPtr deleted"<<endl;
        }   
        else{
            activeFuncPtr->numOfParam = typeRecordList.size();
            activeFuncPtr->parameterList = typeRecordList;
            activeFuncPtr->functionOffset = 0;
            typeRecordList.clear();
            addFunction(activeFuncPtr, funcEntryRecord);
            scope = 2; 
            string s = "function begin _" + activeFuncPtr->name;
            gen(functionInstruction, s, nextquad);
        }
    }
; 

RES_ID: T ID       
    {   
        scope=1;
        activeFuncPtr = new funcEntry;
        activeFuncPtr->name = string($2);
        activeFuncPtr->returnType = resultType;
    } 
    | VOID ID
    {
        scope=1;
        activeFuncPtr = new funcEntry;
        activeFuncPtr->name = string($2);
        activeFuncPtr->returnType = NULLVOID;
    }
;




DECL_PLIST: DECL_PL
    | %empty
;

DECL_PL: DECL_PL COMMA DECL_PARAM
    {
        int found = 0;
        typeRecord* pn = NULL;
        searchParam(varRecord->name, typeRecordList, found, pn);
        if(found){
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Redeclaration of parameter " << varRecord->name <<endl;
        } else {
            // cout << "Variable: "<< varRecord->name << " declared." << endl;
            typeRecordList.push_back(varRecord);
        }
        
    }
    | DECL_PARAM
    {  
        int found = 0;
        typeRecord* pn = NULL;
        searchParam(varRecord->name, typeRecordList, found , pn );
        if (found){
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Redeclaration of parameter " << varRecord->name <<endl;
        } else {
            // cout << "Variable: "<< varRecord->name << " declared." << endl;
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
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector<int>;
    }
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

STMT: VAR_DECL
    {
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
    | FORLOOP
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
    }
    | IFSTMT
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        merge($$.continueList, $1.continueList);
        merge($$.breakList, $1.breakList);

    }
    | WHILESTMT
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
    }
    | SWITCHCASE
    {
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
        merge($$.continueList, $3.continueList);
        merge($$.breakList, $3.breakList);
    }
    | BREAK SEMI
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.breakList->push_back(nextquad);  
        gen(functionInstruction, "goto L", nextquad);      
    }
    | CONTINUE SEMI
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.continueList->push_back(nextquad);
        gen(functionInstruction, "goto L", nextquad);
    }
    | RETURN ASG1 SEMI 
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        if ($2.type != ERRORTYPE && activeFuncPtr != NULL) {
            if (activeFuncPtr->returnType == NULLVOID && $2.type != NULLVOID) {
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": function " << activeFuncPtr->name << " has void return type not " << $2.type << endl;
            }
            else if (activeFuncPtr->returnType != NULLVOID && $2.type == NULLVOID) {
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": function " << activeFuncPtr->name << " has non-void return type" << endl;
            }
            else {
                string s;
                if (activeFuncPtr->returnType != NULLVOID && $2.type != NULLVOID) {
                    if ($2.type == INTEGER && activeFuncPtr->returnType == FLOATING)  {
                        string floatReg = tempSet.getFloatRegister();
                        s = floatReg + " = " + "convertToFloat(" + *($2.registerName) + ")";
                        cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                        gen(functionInstruction, s, nextquad);
                        s = "return " + floatReg;
                        gen(functionInstruction, s, nextquad);
                        tempSet.freeRegister(*($2.registerName));
                        tempSet.freeRegister(floatReg);
                    }
                    else if ($2.type == FLOATING && activeFuncPtr->returnType == INTEGER) {
                        string intReg = tempSet.getRegister();
                        s = intReg + " = " + "convertToInt(" + *($2.registerName) + ")";
                        cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                        gen(functionInstruction, s, nextquad);
                        s = "return " + intReg;
                        gen(functionInstruction, s, nextquad);
                        tempSet.freeRegister(*($2.registerName));
                        tempSet.freeRegister(intReg);                        
                    }
                    else {
                        s = "return " + *($2.registerName);
                        gen(functionInstruction, s, nextquad);
                        tempSet.freeRegister(*($2.registerName));
                    }
                }
                else if (activeFuncPtr->returnType == NULLVOID && $2.type == NULLVOID) {
                    s = "return";
                    gen(functionInstruction, s, nextquad);
                }
                else {
                    errorFound = 1;
                    cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Exactly one of function " << activeFuncPtr->name << "and this return statement has void return type" << endl;
                    if ($2.type != NULLVOID) tempSet.freeRegister(*($2.registerName));
                } 
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
            string s;
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
    | error SEMI
    {
        errorFound = 1;
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        cout << BOLD(FRED("ERROR : ")) << FYEL("Line no. " + to_string(yylineno) + ": Syntax error") << endl;
    }
    | error
    {
        errorFound = 1;
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        cout << BOLD(FRED("ERROR : ")) << FYEL("Line no. " + to_string(yylineno) + ": Syntax error") << endl;
    }
;

VAR_DECL: D SEMI 
;

D: T L
    { 
        patchDataType(resultType, typeRecordList, scope);
        if(scope > 1){
            insertSymTab(typeRecordList, activeFuncPtr);
            
        }
        else if(scope == 0){
            insertGlobalVariables(typeRecordList, globalVariables);
        }
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
        int found = 0;
        typeRecord* vn = NULL;
        // cout << "Scope : "<<scope<<endl;
        if(activeFuncPtr!=NULL && scope > 0){
            searchVariable(string($1), activeFuncPtr, found, vn, scope);
            if (found) {
                if(vn->isValid==true){
                    cout << BOLD(FRED("ERROR : ")) << "Line no. :" << yylineno << " Variable " << string($1) << " already declared at same level " << scope << endl ;
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
                    // printf("Line no. %d: Vaiable %s is already declared as a parameter with scope %d\n", yylineno, $1, scope);
                    cout << BOLD(FRED("ERROR : ")) << "Line no. :" << yylineno << " Variable " << string($1) << " already declared in parameters " << endl ;
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
        else if(scope == 0){
            searchGlobalVariable(string($1), globalVariables, found, vn, scope);
            if (found) {
                // printf("Variable %s already declared at global level \n", $1);
                cout << BOLD(FRED("ERROR : ")) << "Line no. :" << yylineno << " Variable " << string($1) << " already declared at global level " << endl ;
            }
            else{
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
        else {
            errorFound = true;
        }
        
    }
    | ID ASSIGN ASG
    {
        int found = 0;
        typeRecord* vn = NULL;
        if(activeFuncPtr!=NULL){
            searchVariable(string($1), activeFuncPtr, found, vn, scope);
            bool varCreated = false;;
            if (found) {
                if(vn->isValid==true){
                    cout << BOLD(FRED("ERROR : ")) << "Line no. :" << yylineno << " Variable " << string($1) << " already declared at same level " << scope << endl ;
                }
                else{
                    if(vn->eleType == resultType){
                        vn->isValid=true;
                        vn->maxDimlistOffset = max(vn->maxDimlistOffset,1);
                        vn->type=SIMPLE;
                        varCreated = true;
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
                        varCreated = true;
                    }
                }
            }
            else if (scope == 2) {
                typeRecord* pn = NULL;
                searchParam(string($1), activeFuncPtr->parameterList, found , pn);
                if (found) {
                    cout << BOLD(FRED("ERROR : ")) << "Line no. :" << yylineno << " Variable " << string($1) << " already declared at parameter level " << endl ;
                } 
                else {
                    varRecord = new typeRecord;
                    varRecord->name = string($1);
                    varRecord->type = SIMPLE;
                    varRecord->tag = VARIABLE;
                    varRecord->scope = scope;
                    varRecord->maxDimlistOffset=1;
                    varRecord->isValid=true;
                    typeRecordList.push_back(varRecord);
                    varCreated = true;
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
                typeRecordList.push_back(varRecord);
                varCreated = true;
            }
            if(varCreated){
                if ($3.type == ERRORTYPE) {
                    errorFound = true;
                }
                else if ($3.type == NULLVOID) {
                    cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Cannot assign void to non-void type " << string($1) << endl;
                    errorFound = true;
                }
                else {
                    string registerName;
                    if (resultType == INTEGER && $3.type == FLOATING) {
                        registerName = tempSet.getRegister();
                        string s = registerName + " = convertToInt(" + (*($3.registerName)) + ")";   
                        cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                        gen(functionInstruction, s, nextquad);
                        tempSet.freeRegister(*($3.registerName));
                    }
                    else if(resultType == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                        registerName = tempSet.getFloatRegister();
                        string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")"; 
                        cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                        gen(functionInstruction, s, nextquad); 
                        tempSet.freeRegister(*($3.registerName));
                    }
                    else {
                        registerName = *($3.registerName);
                    }
                    string dataType = eletypeMapper(resultType);
                    dataType += "_" + to_string(scope);
                    string s =  "_" + string($1) + "_" + dataType + " = " + registerName ;
                    gen(functionInstruction, s, nextquad);
                    tempSet.freeRegister(registerName);
                }   
            }
        }
        else if(scope == 0){
            cout << BOLD(FRED("ERROR : ")) << "Line No " << yylineno << ": ID assignments not allowed in global level : Variable " << string($1) << endl;
            errorFound = true;
        }
        else {
            errorFound = true;
        }
    }
    | ID DEC_BR_DIMLIST
    {  
        if (activeFuncPtr != NULL) {
            int found = 0;
            typeRecord* vn = NULL;
            searchVariable(string($1), activeFuncPtr, found, vn,scope); 
            if (found) {
                if(vn->isValid==true){
                    cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Variable " << string($1) << " already declared at same level " << scope << endl;
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
                        typeRecordList.push_back(varRecord);
                    }
                }
            }
            else if (scope == 2) {
                typeRecord* pn = NULL;
                searchParam(string($1), activeFuncPtr->parameterList, found, pn);
                if (found) {
                    cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Variable " << string($1) << " already declared at parameter level " << endl;
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
            // decdimlist.clear();  
        } 
        else if(scope == 0){
            typeRecord* vn = NULL;
            searchGlobalVariable(string($1), globalVariables, found, vn, scope);
            if (found) {
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Variable " << string($1) << " already declared at global level " << endl;
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
                // cout<<"variable name: "<<varRecord->name<<endl;
                typeRecordList.push_back(varRecord);   
            }
        }   
        else{
            errorFound = 1;
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
        int vfound=0;
        typeRecord* vn;
        searchVariable(callFuncPtr->name,activeFuncPtr,vfound,vn,scope);
        if (vfound) {
            $$.type = ERRORTYPE;
            cout<< BOLD(FRED("ERROR : ")) << "Line no." << yylineno << ": called object "<< callFuncPtr->name << " is not a function or function pointer"<< endl;
        }
        else {
            compareFunc(callFuncPtr,funcEntryRecord,found);
            $$.type = ERRORTYPE;
            if (found == 0) {
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
                cout << "No function with name " << string($1) << " exists" << endl;
            }
            else if (found == -1) {
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
                cout << "call parameter list does not match with defined paramters of function " << string($1) << endl;
            }
            else {
                $$.type = callFuncPtr->returnType;
                if(callFuncPtr->returnType == INTEGER){
                    $$.registerName = new string(tempSet.getRegister());
                    gen(functionInstruction, "refparam " + (*($$.registerName)), nextquad);
                    gen(functionInstruction, "call _" + callFuncPtr->name + ", " + to_string(typeRecordList.size() + 1 ), nextquad);      
                }
                else if(callFuncPtr->returnType == FLOATING){
                    $$.registerName = new string(tempSet.getFloatRegister());
                    gen(functionInstruction, "refparam " + (*($$.registerName)), nextquad);
                    gen(functionInstruction, "call _" + callFuncPtr->name + ", " + to_string(typeRecordList.size() + 1 ), nextquad);      
                }
                else if (callFuncPtr->returnType == NULLVOID) {
                    $$.registerName = NULL;
                    gen(functionInstruction, "call _" + callFuncPtr->name + ", " + to_string(typeRecordList.size()), nextquad);      
                }
                else {
                    cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": Illegal return type of function " << callFuncPtr->name << endl;
                }
            }
        }
        typeRecordList.clear();
        typeRecordList.swap(paramListStack.top());
        paramListStack.pop();
    }
;

PARAMLIST: PLIST
    | {paramListStack.push(typeRecordList); typeRecordList.clear();} %empty 
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
        if($$.type != ERRORTYPE && $$.type != NULLVOID) {
            $$.registerName = $1.registerName;
            if($1.jumpList!=NULL){
                vector<int>* qList = new vector<int>;
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($3.registerName));
            }
            else if($1.type == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                registerName = tempSet.getFloatRegister();
                string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")";   
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
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
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else if ($3.type == NULLVOID) {
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($3.registerName));
            }
            else if($1.type == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                registerName = tempSet.getFloatRegister();
                string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")";   
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad); 
                tempSet.freeRegister(*($3.registerName));
            }
            else {
                registerName = *($3.registerName);
            }
            string s, tempReg;
            if($1.type == INTEGER){
                tempReg = tempSet.getRegister();
                s = tempReg + " = " + (*($1.registerName));
                gen(functionInstruction, s, nextquad);
            }
            else{
                tempReg = tempSet.getFloatRegister();
                s = tempReg + " = " + (*($1.registerName));   
                gen(functionInstruction, s, nextquad);
            }
            s = registerName + " = " + registerName + " + " + tempReg;
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(tempReg);
            s = (*($1.registerName)) + " = " + registerName ;
            gen(functionInstruction, s, nextquad);
            $$.registerName = new string(registerName);
            if ($1.offsetRegName != NULL) tempSet.freeRegister(*($1.offsetRegName));
        }
    }
    | LHS MINASG ASG
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else if ($3.type == NULLVOID) {
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($3.registerName));
            }
            else if($1.type == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                registerName = tempSet.getFloatRegister();
                string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")"; 
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad); 
                tempSet.freeRegister(*($3.registerName));
            }
            else {
                registerName = *($3.registerName);
            }
            string s, tempReg;
            if($1.type == INTEGER){
                tempReg = tempSet.getRegister();
                s = tempReg + " = " + (*($1.registerName));
                gen(functionInstruction, s, nextquad);
            }
            else{
                tempReg = tempSet.getFloatRegister();
                s = tempReg + " = " + (*($1.registerName));   
                gen(functionInstruction, s, nextquad);
            }
            s = registerName + " = " + registerName + " - " + tempReg;
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(tempReg);
            s = (*($1.registerName)) + " = " + registerName ;
            gen(functionInstruction, s, nextquad);
            $$.registerName = new string(registerName);
            if ($1.offsetRegName != NULL) tempSet.freeRegister(*($1.offsetRegName));
        }
    }
    | LHS MULASG ASG
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else if ($3.type == NULLVOID) {
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($3.registerName));
            }
            else if($1.type == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                registerName = tempSet.getFloatRegister();
                string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")";  
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad); 
                tempSet.freeRegister(*($3.registerName));
            }
            else {
                registerName = *($3.registerName);
            }
            string s, tempReg;
            if($1.type == INTEGER){
                tempReg = tempSet.getRegister();
                s = tempReg + " = " + (*($1.registerName));
                gen(functionInstruction, s, nextquad);
            }
            else{
                tempReg = tempSet.getFloatRegister();
                s = tempReg + " = " + (*($1.registerName));   
                gen(functionInstruction, s, nextquad);
            }
            s = registerName + " = " + registerName + " * " + tempReg;
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(tempReg);
            s = (*($1.registerName)) + " = " + registerName ;
            gen(functionInstruction, s, nextquad);
            $$.registerName = new string(registerName);
            if ($1.offsetRegName != NULL) tempSet.freeRegister(*($1.offsetRegName));
        }
    }
    | LHS DIVASG ASG
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else if ($3.type == NULLVOID) {
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($3.registerName));
            }
            else if($1.type == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                registerName = tempSet.getFloatRegister();
                string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")";   
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad); 
                tempSet.freeRegister(*($3.registerName));
            }
            else {
                registerName = *($3.registerName);
            }
            string s, tempReg;
            if($1.type == INTEGER){
                tempReg = tempSet.getRegister();
                s = tempReg + " = " + (*($1.registerName));
                gen(functionInstruction, s, nextquad);
            }
            else{
                tempReg = tempSet.getFloatRegister();
                s = tempReg + " = " + (*($1.registerName));   
                gen(functionInstruction, s, nextquad);
            }
            s = registerName + " = " + registerName + " / " + tempReg;
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(tempReg);
            s = (*($1.registerName)) + " = " + registerName ;
            gen(functionInstruction, s, nextquad);
            $$.registerName = new string(registerName);
            if ($1.offsetRegName != NULL) tempSet.freeRegister(*($1.offsetRegName));
        }
    }
    | LHS MODASG ASG
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
            errorFound = true;
        }
        else if ($3.type == NULLVOID) {
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad);
                tempSet.freeRegister(*($3.registerName));
            }
            else if($1.type == FLOATING && ($3.type == INTEGER || $3.type == BOOLEAN)) {
                registerName = tempSet.getFloatRegister();
                string s = registerName + " = convertToFloat(" + (*($3.registerName)) + ")";   
                cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                gen(functionInstruction, s, nextquad); 
                tempSet.freeRegister(*($3.registerName));
            }
            else {
                registerName = *($3.registerName);
            }
            string s, tempReg;
            if($1.type == INTEGER){
                tempReg = tempSet.getRegister();
                s = tempReg + " = " + (*($1.registerName));
                gen(functionInstruction, s, nextquad);
            }
            else{
                tempReg = tempSet.getFloatRegister();
                s = tempReg + " = " + (*($1.registerName));   
                gen(functionInstruction, s, nextquad);
            }
            s = registerName + " = " + registerName + " % " + tempReg;
            gen(functionInstruction, s, nextquad);
            tempSet.freeRegister(tempReg);
            s = (*($1.registerName)) + " = " + registerName ;
            gen(functionInstruction, s, nextquad);
            $$.registerName = new string(registerName);
            if ($1.offsetRegName != NULL) tempSet.freeRegister(*($1.offsetRegName));
        }
    }
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
            }
            else{
                gen(functionInstruction, "if "+ (*($3.registerName)) +" == "+ it.first + " goto L" + to_string(it.second), nextquad);
            }
        }
        $7.casepair->clear();
        backpatch(qList, nextquad, functionInstruction);
        backpatch($7.breakList, nextquad, functionInstruction);
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
;

TEMP1: %empty
    {
        $$.begin=nextquad;
        $$.falseList = new vector<int>;
        $$.falseList->push_back(nextquad);
        gen(functionInstruction, "goto L", nextquad);
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
        $4.casepair->push_back(make_pair("-"+string($3), nextquad));
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        } COLON BODY 
    CASELIST
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.casepair = new vector<pair<string,int>>;
        merge($$.continueList,$8.continueList);
        merge($$.breakList, $8.breakList);
        merge($$.nextList, $8.nextList);
        merge($$.continueList,$7.continueList);
        merge($$.breakList, $7.breakList);
        merge($$.nextList, $7.nextList);
        mergeSwitch($$.casepair, $8.casepair);
        mergeSwitch($$.casepair, $4.casepair);
    }
    |
    CASE NUMINT TEMP2 {
        $3.casepair->push_back(make_pair(string($2), nextquad));
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
        } COLON BODY 
    CASELIST
    {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList = new vector <int>;
        $$.casepair = new vector<pair<string,int>>;
        merge($$.continueList,$6.continueList);
        merge($$.breakList, $6.breakList);
        merge($$.nextList, $6.nextList);
        merge($$.continueList,$7.continueList);
        merge($$.breakList, $7.breakList);
        merge($$.nextList, $7.nextList);
        mergeSwitch($$.casepair, $7.casepair);
        mergeSwitch($$.casepair, $3.casepair);
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
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad);
    }
     BODY {
        $$.nextList = new vector<int>;
        $$.breakList = new vector<int>;
        $$.casepair = new vector<pair<string,int>>;
        $$.continueList = new vector <int>;
        merge($$.continueList,$5.continueList);
        merge($$.breakList, $5.breakList);
        merge($$.nextList, $5.nextList);
        mergeSwitch($$.casepair, $3.casepair);
    }
;

M3: %empty
    { 
        $$ = nextquad;
        gen(functionInstruction, "L" + to_string(nextquad) + ":", nextquad); 
    }
;

N3: %empty
    { 
        $$.begin = nextquad; 
        $$.falseList = new vector<int>;
        $$.falseList->push_back(nextquad);
        gen(functionInstruction, "goto L", nextquad);
    }
;

P3: %empty 
    { 
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
        if($6.type!=NULLVOID){
            tempSet.freeRegister(*($6.registerName));
        }
        if($11.type!=NULLVOID){
            tempSet.freeRegister(*($11.registerName));
        }
    }
    | FOR error RP
    {
        errorFound = 1;
        $$.falseList = new vector<int>;
        cout << BOLD(FRED("ERROR : ")) << FYEL("Line no. " + to_string(yylineno) + ": Syntax error in for loop, discarded token till RP") << endl;
        scope++;
    }
;

ASG1: ASG
    {
        $$.type= $1.type;
        if ($1.type != ERRORTYPE && $1.type != NULLVOID) {
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
        deleteVarList(activeFuncPtr,scope);
        scope--;
        $$.nextList= new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList= new vector<int>;
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
        $$.nextList= new vector<int>;
        $$.breakList = new vector<int>;
        $$.continueList= new vector<int>;
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
        if($3.type != ERRORTYPE && $3.type!=NULLVOID){
            $$.falseList = new vector <int>;
            $$.falseList->push_back(nextquad);
            if($3.type == NULLVOID){
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << "condition in if statement can't be empty" << endl;
                errorFound=true;
            }
            gen(functionInstruction, "if "+ (*($3.registerName)) + " == 0 goto L", nextquad);
            scope++;
            tempSet.freeRegister(*($3.registerName));
        } 
    }
    | IF error RP
    {
        errorFound = 1;
        $$.falseList = new vector <int>;
        cout << BOLD(FRED("ERROR : ")) << FYEL("Line no. " + to_string(yylineno) + ": Syntax error in if, discarding tokens till RP") << endl;
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
    | WHILE error RP
    {   
        $$.falseList = new vector<int>;
        cout << BOLD(FRED("ERROR : ")) << FYEL("Line no. " + to_string(yylineno) + ": Syntax error in while loop, discarding tokens till RP") << endl;
        scope++;
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
        else if($1.type == NULLVOID || $5.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ": Both the expessions should not be NULL" << endl;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());
            vector<int>* qList = new vector<int>;
            if($5.jumpList!=NULL){
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
        if ($$.type != ERRORTYPE && $$.type != NULLVOID) {
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
        else if($1.type == NULLVOID || $5.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ": Both the expessions should not be NULL" << endl;
        }
        else{
            $$.type = BOOLEAN;
            $$.registerName = new string(tempSet.getRegister());
            $$.jumpList = new vector<int>;
            merge($$.jumpList,$1.jumpList);
            vector<int>* qList = new vector<int>;
            
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
        if ($1.type != ERRORTYPE && $1.type != NULLVOID) {
            $$.registerName = $1.registerName; 
            $$.jumpList = new vector<int>;
            $$.jumpList=NULL;   
        }
    }
;

EXPR1: NOT EXPR21
    {
        $$.type = $2.type;
        if ($2.type != ERRORTYPE && $2.type != NULLVOID) {
            $$.registerName = $2.registerName;
            string s = (*($$.registerName)) + " = ~" + (*($2.registerName));   
            gen(functionInstruction, s, nextquad);
        }
    }
    | EXPR21
    {
        $$.type = $1.type;
        if ($1.type != ERRORTYPE && $1.type != NULLVOID) {
            $$.registerName = $1.registerName;    
        }
    }
;

EXPR21: EXPR2 EQUAL EXPR2
    {
        if ($1.type == ERRORTYPE || $3.type == ERRORTYPE) {
            $$.type = ERRORTYPE;
        }
        else if($1.type == NULLVOID || $3.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ":Both the expessions should not be  NULL" << endl;
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
        else if($1.type == NULLVOID || $3.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ":Both the expessions should not be  NULL" << endl;
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
        else if($1.type == NULLVOID || $3.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ":Both the expessions should not be  NULL" << endl;
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
        else if($1.type == NULLVOID || $3.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ":Both the expessions should not be  NULL" << endl;
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
        else if($1.type == NULLVOID || $3.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ":Both the expessions should not be  NULL" << endl;
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
        else if($1.type == NULLVOID || $3.type == NULLVOID){
            $$.type = ERRORTYPE;
            cout << BOLD(FRED("ERROR : ")) << "Line no. "<< yylineno << ":Both the expessions should not be  NULL" << endl;
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
            if($1.type != NULLVOID){
                $$.registerName = new string(*($1.registerName)); 
                delete $1.registerName; 
            }
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
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
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
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
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
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
            if($1.type!= NULLVOID){
                $$.registerName = new string(*($1.registerName)); 
                delete $1.registerName;
            }         
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
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
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
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
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
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
                    tempSet.freeRegister(*($1.registerName));
                    $1.registerName = &newReg;
                    gen(functionInstruction, s, nextquad);
                }
                else if ($1.type == FLOATING && $3.type == INTEGER) {
                    string newReg = tempSet.getFloatRegister();
                    string s = newReg + " = " + "convertToFloat(" + (*($3.registerName)) + ")";
                    cout << BOLD(FBLU("Warning : ")) << FCYN("Line No. "+to_string(yylineno)+":Implicit Type Conversion") << endl;
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
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
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
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
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
            if($1.type != NULLVOID){
                $$.registerName = new string(*($1.registerName)); 
                delete $1.registerName;
            }  
        } 
    }
;

FACTOR: ID_ARR  
    { 
        $$.type = $1.type;
        if ($$.type != ERRORTYPE) {
            if ($$.type == INTEGER)
                $$.registerName = new string(tempSet.getRegister());
            else $$.registerName = new string(tempSet.getFloatRegister());
            string s = (*($$.registerName)) + " = " + (*($1.registerName)) ;
            gen(functionInstruction, s, nextquad);
            if($1.offsetRegName != NULL){
                tempSet.freeRegister((*($1.offsetRegName)));
            }
        }
    }
    | MINUS ID_ARR
    {
        $$.type = $2.type;
        if($2.type != ERRORTYPE){
            string s="";
            if ($$.type == INTEGER){
                $$.registerName = new string(tempSet.getRegister());
                string temp=tempSet.getRegister();
                string temp1=tempSet.getRegister();
                gen(functionInstruction, temp + " = 0", nextquad);
                gen(functionInstruction, temp1 + " = " +  (*($2.registerName)), nextquad);
                s = (*($$.registerName)) + " = " + temp + " -" + temp1 ;
                tempSet.freeRegister(temp);
                tempSet.freeRegister(temp1);
            }
            else{ 
                $$.registerName = new string(tempSet.getFloatRegister());
                string temp=tempSet.getFloatRegister();
                string temp1=tempSet.getRegister();
                gen(functionInstruction, temp + " = 0", nextquad);
                gen(functionInstruction, temp1 + " = " +  (*($2.registerName)), nextquad);
                s = (*($$.registerName)) + " = 0 -" + temp1 ;
                tempSet.freeRegister(temp);
                tempSet.freeRegister(temp1);
            }
            // string s = (*($$.registerName)) + " = 0 -" + (*($2.registerName)) ;
            gen(functionInstruction, s, nextquad);
            if($2.offsetRegName != NULL){
                tempSet.freeRegister((*($2.offsetRegName)));
            }
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
        if ($1.type == ERRORTYPE) {
            if ($1.type == NULLVOID){
                delete callFuncPtr;
            }
            else {
                $$.registerName = $1.registerName;
                delete callFuncPtr;
            }
        }; 
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
            cout << "Cannot increment non-integer type variable "<< *($1.registerName) << endl; 
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
            cout << "Cannot increment non-integer type variable "<<*($2.registerName) << endl; 
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
            cout << "Cannot increment non-integer type variable " << *($2.registerName) << endl; 
        }
    }
;

ID_ARR: ID
    {   
        // retrieve the highest level id with same name in param list or var list or global list
        int found = 0;
        typeRecord* vn = NULL;
        searchCallVariable(string($1), activeFuncPtr, found, vn, globalVariables); 
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
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ":  ";
                cout << $1 << " is declared as an array but is being used as a singleton" << endl; 
            }
        }
        else {
            if (activeFuncPtr != NULL)
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
                    cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
                    cout << $1 << " is declared as an array but is being used as a singleton" << endl;
                }
            }
            else {
                $$.type = ERRORTYPE;
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
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
            searchCallVariable(string($1), activeFuncPtr, found, vn, globalVariables); 
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
                        cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
                        cout << "Dimension mismatch: " << $1 << " should have " << dimlist.size() <<" dimensions" << endl;
                    }
                }
                else {
                    $$.type = ERRORTYPE;
                    cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
                    cout << string($1) << " is declared as a singleton but is being used as an array" << endl; 
                }
            }
            else {
                $$.type = ERRORTYPE;
                cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
                cout << "Undeclared identifier " << $1 << endl;
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
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
            cout << "One of the dimension of an array cannot be evaluated to integer" << endl;
        }
    }    
    | BR_DIMLIST LSB ASG RSB 
    {
        if ($3.type == INTEGER) {
            dimlist.push_back(*($3.registerName));
        }
        else {
            cout << BOLD(FRED("ERROR : ")) << "Line no. " << yylineno << ": ";
            cout << "One of the dimension of an array cannot be evaluated to integer" << endl;
        }  
    }
;

%%

void yyerror(const char *s)
{      
    errorFound=1;
    fprintf (stderr, "%s\n", s);
    // cout << "Line no. " << yylineno << ": Syntax error" << endl;
    // fflush(stdout);
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
    
    yyparse();
    populateOffsets(funcEntryRecord, globalVariables);
    ofstream outinter;
    outinter.open("./output/intermediate.txt");
    if(!errorFound){
        for(auto it:functionInstruction){
            outinter<<it<<endl;
        }
        cout << BOLD(FGRN("Intermediate Code Generated")) << endl;
    } else {
        cout << BOLD(FRED("Exited without intermediate code generation")) << endl;
    }
    outinter.close();
}
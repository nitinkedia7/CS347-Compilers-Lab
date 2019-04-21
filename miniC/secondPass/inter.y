%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
#include <bits/stdc++.h>
#include "symTabParser.h"
using namespace std;

#define INTSIZE 4
#define FLOATSIZE 4

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(char* s);

FILE *mips;
string activeFunc;
int paramOffset;
string returnVal;
int floatLabel = 0;
vector<funcEntry> functionList;

void saveRegisters(int frameSize);
void retrieveRegisters(int frameSize);    
%}

%union {
    int intval;
    float floatval;
    char *idName;
}

%token FUNCTION BEG END IF GOTO PARAM REFPARAM CALL LSB RSB RETURN NEWLINE
%token CONVERTINT CONVERTFLOAT LP RP
%token USERVAR REGINT REGFLOAT LABEL NUMINT NUMFLOAT 
%token COMMA COLON SEMI
%token PLUS MINUS MUL DIV MOD
%token EQUAL NOTEQUAL OR AND LT GT LE GE ASSIGN NEG

%type <idName> NUMFLOAT NUMINT REGINT REGFLOAT LABEL USERVAR 

%%

STMT_LIST: STMT_LIST STMT NEWLINE
    | STMT NEWLINE
;

STMT: ASG
    | FLOATASG
    | GOTO LABEL
    {
        fprintf(mips, "j %s\n", $2);
    }
    | LABEL COLON
    {
        fprintf(mips, "%s:\n", $1);
    }
    | IFSTMT
    | PARAM REGINT
    {
        // The initial frame of the caller function remains intact, grows downwards for each param
        paramOffset += INTSIZE;
        fprintf(mips, "sub $sp, $sp, %d\n", INTSIZE); // addu $sp, $sp, -INTSIZE
        fprintf(mips, "sw $t%c 0($sp)\n", $2[1]);     // sw $t0, 0($sp)
    }
    | PARAM REGFLOAT
    {
        paramOffset += FLOATSIZE;
        fprintf(mips, "sub $sp, $sp, %d\n", FLOATSIZE);    // addu $sp, $sp, -INTSIZE
        fprintf(mips, "mfc1 $s0 $f%s\n", $2+1);             // store a float reg into int reg s0
        fprintf(mips, "sw $s0, 0($sp)\n");                 // sw $t0, 0($sp)
    }
    | REFPARAM REGINT 
    {
        returnVal = string($2);
    }
    | REFPARAM REGFLOAT
    {
        returnVal = string($2);
    }
    | CALL USERVAR COMMA NUMINT
    {
        int frameSize = getFunctionOffset(functionList, activeFunc); 
        saveRegisters(frameSize+paramOffset);       // Save all temp registers
        fprintf(mips, "jal %s\n", $2);                     // jal calling
        retrieveRegisters(frameSize+paramOffset);   // retrieve all registers
        if(returnVal[0] == 'F'){
            fprintf(mips, "move $s0, $v0\n");   // move result to refparam
            fprintf(mips, "mtc1 $s0, $f%s\n", returnVal.c_str()+1);   // move result to refparam
            fprintf(mips, "cvt.s.w $f%s, $f%s\n", returnVal.c_str()+1, returnVal.c_str()+1);
        } else {
            fprintf(mips, "move $t%c, $v0\n", returnVal[1]);   // move result to refparam 
        }
        fprintf(mips, "add $sp, $sp, %d\n", paramOffset);  // collapse space used by parameters
        paramOffset = 0;
    }
    | FUNCTION BEG USERVAR
    {
        activeFunc = string($3);
        fprintf(mips, "%s:\n", $3);
        // Push return address and frame pointer to top of frame
        int frameSize = getFunctionOffset(functionList, activeFunc);
        fprintf(mips, "subu $sp, $sp, %d\n", frameSize);
        fprintf(mips, "sw $ra, %d($sp)\n", frameSize-INTSIZE);
        fprintf(mips, "sw $fp, %d($sp)\n", frameSize-2*INTSIZE);
        fprintf(mips, "move $fp, $sp\n");
    }
    | FUNCTION END
    {
        int frameSize = getFunctionOffset(functionList, activeFunc);
        fprintf(mips, "end_%s:\n", activeFunc.c_str()+1);
        fprintf(mips, "move $sp, $fp\n");                          // move    $sp,$fp
        fprintf(mips, "lw $ra, %d($sp)\n", frameSize-INTSIZE);     // lw      $31,52($sp)
        fprintf(mips, "lw $fp, %d($sp)\n", frameSize-2*INTSIZE);   // lw      $fp,48($sp)
        fprintf(mips, "addu $sp, $sp, %d\n", frameSize);           // addiu   $sp,$sp,56
        fprintf(mips, "j $ra\n");                                  // j       $31
        //nop
    }
    | RETURN 
    {
        fprintf(mips, "j end_%s\n", activeFunc.c_str()+1);
    }
    | RETURN REGINT
    {
        fprintf(mips, "move $v0, $t%c\n", $2[1]);
        fprintf(mips, "j end_%s\n", activeFunc.c_str()+1);
    }
    | RETURN REGFLOAT
    {
        fprintf(mips, "mfc1 $s0, $f%s", activeFunc.c_str()+1);
        fprintf(mips, "move $v0, $s0\n");
        fprintf(mips, "j end_%s\n", activeFunc.c_str());
    }
;


ASG: USERVAR ASSIGN REGINT
    {
        int offset = getOffset(functionList,activeFunc, string($1), 0);
        fprintf(mips, "sw $t%c, %d($sp)\n", $3[1], offset);
    }
    | USERVAR LSB NUMINT RSB ASSIGN REGINT
    {
        int offset = getOffset(functionList,activeFunc, string($1), 0);
        fprintf(mips, "sw $t%c, %d($sp)\n", $3[1], offset);
    }
    | REGINT ASSIGN USERVAR
    {
        int offset = getOffset(functionList,activeFunc, string($3), 0);
        fprintf(mips, "lw $t%c, %d($sp)\n", $1[1], offset);
    }
    | REGINT ASSIGN NUMINT
    {
        fprintf(mips, "li $t%c, %s\n", $1[1], $3);
    }
    | REGINT ASSIGN REGINT
    {
        fprintf(mips, "move $t%c, $t%c\n", $1[1], $3[3]);
    }
    | REGINT ASSIGN CONVERTINT LP REGFLOAT RP
    {
        fprintf(mips, "cvt.w.s $f%s, $f%s\n", $5+1, $5+1);
        fprintf(mips, "mfc1 $t%c, $f%s", $1[1], $5+1);
    }
    | REGINT ASSIGN REGINT PLUS NUMINT
    {
        fprintf(mips, "addu $t%c, $t%c, %s\n", $1[1], $3[1], $5);
    }
    | REGINT ASSIGN REGINT MINUS NUMINT
    {
        fprintf(mips, "subu $t%c, $t%c, %s\n", $1[1], $3[1], $5);
    }
    | REGINT ASSIGN REGINT PLUS REGINT
    {
        fprintf(mips, "add $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT MINUS REGINT
    {
        fprintf(mips, "sub $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT MUL REGINT
    {
        fprintf(mips, "mul $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT DIV REGINT
    {
        fprintf(mips, "div $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
        fprintf(mips, "mflo $t%c\n", $1[1]);
    }
    | REGINT ASSIGN REGINT MOD REGINT
    {
        fprintf(mips, "div $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
        fprintf(mips, "mfhi $t%c\n", $1[1]);
    }
    | REGINT ASSIGN REGINT EQUAL REGINT
    {
        fprintf(mips, "seq $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT NOTEQUAL REGINT
    {
        fprintf(mips, "sne $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT AND REGINT 
    {
        // hack, will not arise when short-circuit is done
        fprintf(mips, "sne $t%c, $t%c, 0\n", $3[1], $3[1]);
        fprintf(mips, "sne $t%c, $t%c, 0\n", $5[1], $5[1]);
        fprintf(mips, "and $t%c, $t%c, $t%c", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT OR REGINT
    {
        fprintf(mips, "or $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT LT REGINT
    {
        fprintf(mips, "slt $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT GT REGINT
    {
        fprintf(mips, "sgt $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT LE REGINT
    {
        fprintf(mips, "sle $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT GE REGINT
    {
        fprintf(mips, "sge $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
;

FLOATASG: USERVAR ASSIGN REGFLOAT
    {
        int offset = getOffset(functionList, activeFunc, string($1), 0);
        fprintf(mips, "s.s $f%s, %d($sp)\n", $3+1, offset);
    }
    | USERVAR LSB NUMINT RSB ASSIGN REGFLOAT
    {
        int offset = getOffset(functionList, activeFunc, string($1), 0);
        fprintf(mips, "s.s $f%s, %d($sp)\n", $3+1, offset);
    }
    | REGFLOAT ASSIGN USERVAR
    {
        int offset = getOffset(functionList, activeFunc, string($3), 0);
        fprintf(mips, "l.s $f%s, %d($sp)\n", $3+1, offset);
    }
    | REGFLOAT ASSIGN CONVERTFLOAT LP REGINT RP
    {
        // convert from integer to float
        fprintf(mips, "mtc1 $t%c, $f%s\n", $5[1], $1+1);
        fprintf(mips, "cvt.s.w $f%s, $f%s\n", $1+1, $1+1);
    }
    | REGFLOAT ASSIGN NUMFLOAT
    {
        fprintf(mips, "li.s $f%s, %s\n", $1+1, $3);
    }
    | REGFLOAT ASSIGN REGFLOAT
    {
        fprintf(mips, "mov.s $f%s, $f%s\n", $1+1, $3+1);
    }
    | REGFLOAT ASSIGN REGFLOAT PLUS REGFLOAT
    {
        fprintf(mips, "add.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGFLOAT ASSIGN REGFLOAT MINUS REGFLOAT
    {
        fprintf(mips, "sub.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGFLOAT ASSIGN REGFLOAT MUL REGFLOAT
    {
        fprintf(mips, "mul.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGFLOAT ASSIGN REGFLOAT DIV REGFLOAT
    {
        fprintf(mips, "div.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGINT ASSIGN REGFLOAT EQUAL REGFLOAT
    {
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "c.eq.s $f%s, $f%s\n", $3+1, $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT NOTEQUAL REGFLOAT
    {
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "c.eq.s $f%s, $f%s\n", $3+1, $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT AND REGFLOAT
    {
        fprintf(mips, "li.d $f31, 0\n");
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "c.eq.s $f%s, $f31\n", $3+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "c.eq.s $f%s, $f31\n", $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT OR REGFLOAT
    {
        fprintf(mips, "li.d $f31, 0\n");
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "c.eq.s $f%s, $f31\n", $3+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "c.eq.s $f%s, $f31\n", $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT LT REGFLOAT
    {
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "c.lt.s $f%s, $f%s\n", $3+1, $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT GT REGFLOAT
    {
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "c.le.s $f%s, $f%s\n", $3+1, $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT LE REGFLOAT
    {
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "c.le.s $f%s, $f%s\n", $3+1, $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT GE REGFLOAT
    {
        fprintf(mips, "li $t%c, 1\n", $1[1]);
        fprintf(mips, "c.lt.s $f%s, $f%s\n", $3+1, $5+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $t%c, 0\n", $1[1]);
        fprintf(mips, "FLOAT%d\n", floatLabel);
        floatLabel++;
    }
;

IFSTMT: IF REGINT EQUAL REGINT GOTO LABEL
    {
        fprintf(mips, "beq $t%c, $t%c, %s", $2[1], $4[1], $6);
    }
    | IF REGINT NOTEQUAL REGINT GOTO LABEL
    {
        fprintf(mips, "bne $t%c, $t%c, %s", $2[1], $4[1], $6);
    }
    | IF REGINT EQUAL NUMINT GOTO LABEL
    {
        fprintf(mips, "beq $t%c, $0, %s\n", $2[1], $6);
    }
    | IF REGFLOAT NOTEQUAL REGFLOAT GOTO LABEL
    {
        fprintf(mips, "li $s0, 1\n");
        fprintf(mips, "c.eq.s $f%s, $f%s\n", $2+1, $4+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $s0, 0\n");
        fprintf(mips, "FLOAT%d\n", floatLabel);
        fprintf(mips, "beq $s0, $0, %s\n", $6);
        floatLabel++;
    }
    IF REGFLOAT EQUAL REGFLOAT GOTO LABEL
    {
        fprintf(mips, "li $s0, 1\n");
        fprintf(mips, "c.eq.s $f%s, $f%s\n", $2+1, $4+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $s0, 0\n");
        fprintf(mips, "FLOAT%d\n", floatLabel);
        fprintf(mips, "beq $s0, 1, %s\n", $6);
        floatLabel++;
    }
    | IF REGFLOAT EQUAL NUMINT GOTO LABEL
    {
        fprintf(mips, "mtc1 $0, $f31");
        fprintf(mips, "cvt.s.w $f31, $f31");
        fprintf(mips, "li $s0, 1\n");
        fprintf(mips, "c.eq.s $f%s, $f31\n", $2+1);
        fprintf(mips, "bc1f FLOAT%d\n", floatLabel);
        fprintf(mips, "li $s0, 0\n");
        fprintf(mips, "FLOAT%d\n", floatLabel);
        fprintf(mips, "beq $s0, 1, %s\n", $6);
        floatLabel++;
    }
;

%%

void saveRegisters(int frameSize){
    for(int i=0; i<10; i++){
        fprintf(mips, "sw $t%d, %d($sp)\n", i, frameSize-2*INTSIZE-(i+1)*INTSIZE);
    }
}

void retrieveRegisters(int frameSize){
    for(int i=0; i<10; i++){
        fprintf(mips, "lw $t%d, %d($sp)\n", i, frameSize-2*INTSIZE-(i+1)*INTSIZE);
    }
}

void yyerror(char *s)
{      
    printf("\nSyntax error %s at line %d\n", s, yylineno);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    mips = fopen("./mips.s", "w");
    fprintf(mips,".text\n");
    readSymbolTable(functionList);
    paramOffset = 0;
    floatLabel = 0;
    yyparse();
}
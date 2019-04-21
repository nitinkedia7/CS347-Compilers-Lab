%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
#include <bits/stdc++.h>
using namespace std;

#define INTSIZE 4

extern int yylex();
extern int yyparse();
extern int yylineno;
extern char* yytext;
extern int yyleng;
void yyerror(char* s);
string activeFunc;
int funcNumber; 
int paramOffset;
string returnVal;
int floatLabel = 0;
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

%type <idName> NUMFLOAT NUMINT REGINT REGFLOAT USERVAR

%%

STMT_LIST: STMT_LIST STMT NEWLINE
    | STMT NEWLINE
;

STMT: ASG
    | FLOATASG
    | GOTO LABEL
    {
        printf("j %s\n", $2);
    }
    | LABEL COLON
    {
        printf("%s:\n", $3);
    }
    | IFSTMT
    | PARAM REGINT
    {
        paramOffset+=INTSIZE;
        printf("sub $sp, $sp, %d\n", INTSIZE);// addu $sp, $sp, -INTSIZE
        printf("sw $t%c 0($sp)\n", $2[1]);// sw $t0, 0($sp)
    }
    | PARAM REGFLOAT
    | REFPARAM REGINT 
    {
        returnVal = string($2);
    }
    | REFPARAM REGFLOAT
    {
        //
    }
    | CALL USERVAR COMMA NUMINT
    {
        // TODO caller function jobs
        int frameSize = 32; //to be obtained from symbol table relative to activeFunc
        saveRegisters(frameSize+paramOffset);// Save all temp registers
        printf("jal %s\n", $2);// jal calling
        printf("move $t%d, $v0\n", $2, returnVal[1]);// move result to refparam 
        retrieveRegisters(frameSize);// retrieve all registers
        printf("add $sp, $sp, %d\n", paramOffset);// remove space used by parameters
    }
    | FUNCTION BEG USERVAR
    {
        funcNumber++;
        activeFunc = string($2);
        printf("%s:\n", $3, funcNumber);
        // Push return address and frame pointer to top of frame
        int frameSize = 40;
        printf("subu $sp, $sp, %d\n", frameSize);
        printf("sw $ra, %d($sp)\n", frameSize-INTSIZE);
        printf("sw $fp, %d($sp)\n", frameSize-2*INTSIZE);
        printf("move $fp, $sp\n");
        // This callee should now extract its parameters (if any) WRONG
        // Instead it should know its parametrers location when required
    }
    | FUNCTION END
    {
        int frameSize = 40;
        printf("end_%d:\n", funcNumber);
        printf("move $sp, $fp\n");//move    $sp,$fp
        printf("lw $ra, %d($sp)\n", frameSize-INTSIZE)//lw      $31,52($sp)
        printf("lw $ra, %d($sp)\n", frameSize-2*INTSIZE)//lw      $fp,48($sp)
        printf("addu $sp, $sp, %d\n", frameSize);//addiu   $sp,$sp,56
        printf("j $ra\n", frameSize);//j       $31
        //nop
    }
    | RETURN 
    {
        printf("j end_%d:\n", funcNumber);
    }
    | RETURN REGINT
    {
        printf("move $v0 $t%c\n" $2[1]);
        printf("j end_%d:\n", funcNumber);
    }
;


ASG: USERVAR ASSIGN REGINT
    {
        int offset = 0; // to be replaced
        printf("sw $t%c, %d($sp)\n", $3[1], offset);
    }
    | USERVAR LSB NUMINT RSB ASSIGN REGINT
    {
        int offset = 0; // calc offset using NUMINT
        printf("sw $t%c, %d($sp)\n", $3[1], offset);
    }
    | REGINT ASSIGN USERVAR
    {
        int offset = 0;
        printf("lw $t%c, %d($sp)\n", $1[1], offset);
    }
    | REGINT ASSIGN NUMINT
    {
        int offset = 0;
        printf("li $t%c, %s\n", $1[1], $3);
    }
    | REGINT ASSIGN REGINT
    {
        int offset = 0;
        printf("move $t%c, $t%c\n", $1[1], $3[3]);
    }
    | REGINT ASSIGN CONVERTINT LP REGFLOAT RP
    {
        printf("cvt.w.s $f%s, $f%s\n", $5+1, $5+1);
        printf("mfc1 $t%c, $f%s", $1[1], $5+1);
    }
    | REGINT ASSIGN REGINT PLUS NUMINT
    {
        printf("addu $t%c, $t%c, %s\n", $1[1], $3[1], $5);
    }
    | REGINT ASSIGN REGINT MINUS NUMINT
    {
        printf("subu $t%c, $t%c, %s\n", $1[1], $3[1], $5);
    }
    | REGINT ASSIGN REGINT PLUS REGINT
    {
        printf("add $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT MINUS REGINT
    {
        printf("sub $t%c, $t%c, %t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT MUL REGINT
    {
        printf("mul $t%c, $t%c, %t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT DIV REGINT
    {
        printf("div $t%c, $t%c, %t%c\n", $1[1], $3[1], $5[1]);
        printf("mflo $t%c\n", $1[1]);
    }
    | REGINT ASSIGN REGINT MOD REGINT
    {
        printf("div $t%c, $t%c, %t%c\n", $1[1], $3[1], $5[1]);
        printf("mfhi $t%c\n", $1[1]);
    }
    | REGINT ASSIGN REGINT EQUAL REGINT
    {
        printf("seq $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT NOTEQUAL REGINT
    {
        printf("sne $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT AND REGINT 
    {
        // hack, will not arise when short-circuit is done
        printf("sne $t%c, $t%c, 0\n", $3[1], $3[1]);
        printf("sne $t%c, $t%c, 0\n", $5[1], $5[1]);
        printf("and $t%c, $t%c, $t%c", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT OR REGINT
    {
        printf("or $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT LT REGINT
    {
        printf("slt $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT GT REGINT
    {
        printf("sgt $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT LE REGINT
    {
        printf("sle $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
    | REGINT ASSIGN REGINT GE REGINT
    {
        printf("sge $t%c, $t%c, $t%c\n", $1[1], $3[1], $5[1]);
    }
;

FLOATASG: USERVAR ASSIGN REGFLOAT
    {
        int offset;
        printf("s.s $f%s, %d($sp)\n", $3+1, offset);
    }
    | USERVAR LSB NUMINT RSB ASSIGN REGFLOAT
    {
        int offset;
        printf("s.s $f%s, %d($sp)\n", $3+1, offset);
    }
    | REGFLOAT ASSIGN USERVAR
    {
        int offset;
        printf("l.s $f%s, %d($sp)\n", $3+1, offset);
    }
    | REGFLOAT ASSIGN CONVERTFLOAT LP REGINT RP
    {
        // convert from integer to float
        printf("mtc1 $t%c, $f%s\n", $5+1, $1+1);
        printf("cvt.s.w $f%s, $f%s\n", $1+1, $1+1);
    }
    | REGFLOAT ASSIGN NUMFLOAT
    {
        printf("li.s $f%s, %s\n", $1+1, $3);
    }
    | REGFLOAT ASSIGN REGFLOAT
    {
        printf("mov.s $f%s, $f%s\n", $1+1, $3+1);
    }
    | REGFLOAT ASSIGN REGFLOAT PLUS REGFLOAT
    {
        printf("add.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGFLOAT ASSIGN REGFLOAT MINUS REGFLOAT
    {
        printf("sub.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGFLOAT ASSIGN REGFLOAT MUL REGFLOAT
    {
        printf("mul.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGFLOAT ASSIGN REGFLOAT DIV REGFLOAT
    {
        printf("div.s $f%s, $f%s, $f%s\n", $1+1, $3+1, $5+1);
    }
    | REGINT ASSIGN REGFLOAT EQUAL REGFLOAT
    {
        printf("li $t%c, 0\n", $1+1);
        printf("c.eq.s $f%s, $f%s\n", $3+1, $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 1\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT NOTEQUAL REGFLOAT
    {
        printf("li $t%c, 1\n", $1+1);
        printf("c.eq.s $f%s, $f%s\n", $3+1, $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 0\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT AND REGFLOAT
    {
        printf("li.d $f31, 0\n");
        printf("li $t%c, 0\n", $1+1);
        printf("c.eq.s $f%s, $f31\n", $3+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("c.eq.s $f%s, $f31\n", $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 1\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT OR REGFLOAT
    {
        printf("li.d $f31, 0\n");
        printf("li $t%c, 1\n", $1+1);
        printf("c.eq.s $f%s, $f31\n", $3+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("c.eq.s $f%s, $f31\n", $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 0\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT LT REGFLOAT
    {
        printf("li $t%c, 0\n", $1+1);
        printf("c.lt.s $f%s, $f%s\n", $3+1, $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 1\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT GT REGFLOAT
    {
        printf("li $t%c, 1\n", $1+1);
        printf("c.le.s $f%s, $f%s\n", $3+1, $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 0\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT LE REGFLOAT
    {
        printf("li $t%c, 0\n", $1+1);
        printf("c.le.s $f%s, $f%s\n", $3+1, $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 1\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
    | REGINT ASSIGN REGFLOAT GE REGFLOAT
    {
        printf("li $t%c, 1\n", $1+1);
        printf("c.lt.s $f%s, $f%s\n", $3+1, $5+1);
        printf("bc1f FLOAT%d\n", floatLabel);
        printf("li $t%c, 0\n", $1+1);
        printf("FLOAT%d\n", floatLabel);
        floatLabel++;
    }
;

IFSTMT: IF REGINT EQUAL NUMINT GOTO LABEL
    {
        printf("beq $t%c, $0, %s\n", $2[1], $6);
        printf("bc1f ")
    }
;

%%

void saveRegisters(int frameSize){
    for(int i=0; i<10; i++){
        printf("sw $t%d, %d($sp)", i, frameSize-2*INTSIZE-(i+1)*INTSIZE);
    }
}

void retrieveRegisters(int frameSize){
    for(int i=0; i<10; i++){
        printf("lw $t%d, %d($sp)", i, frameSize-2*INTSIZE-(i+1)*INTSIZE);
    }
}

void yyerror(char *s)
{      
    printf( "\nSyntax error %s at line %d\n", s, yylineno);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    funcNumber = 0;
    paramOffset = 0;
    floatLabel = 0;
    yyparse();
}
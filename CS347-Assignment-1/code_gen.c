#include <stdio.h>
#include "name.c"
#include "lex.c"

void stmt(void);
void stmt_list(void);
char *expr(int);
char *expression(void);
char *term(void);
char *factor(void);

extern char *newname(void);
extern void freename(char *name);

FILE *outasm, *outinter, *outtemp;
int if_label = 0;
int while_label = 0;
int comp_label = 0;

void statements(void){
    /* statements -> stmt statements | stmt */

    outtemp = fopen("assembly.temp", "w+");
    outinter = fopen("intermediate.inter", "w");
    outasm = fopen("assembly.asm", "w");
    
    while(!match(EOI)){
        stmt();
    }
    fprintf(outtemp, "END\n");
    // rewind(outtemp);
    fprintf(outasm, "org 100h\n");
    fprintf(outasm, ".DATA\n");
    symbol* temp_symbol = symbol_list;
    while(temp_symbol!=NULL){
        fprintf(outasm, "%s DB ?\n", temp_symbol->idname);
        temp_symbol = temp_symbol->ptr;
    }
    fprintf(outasm, ".CODE\n");
    rewind(outtemp);
    char copy_byte;
    while((copy_byte = fgetc(outtemp))!=EOF){
        fputc(copy_byte, outasm);
    }
    fclose(outasm);
    fclose(outtemp);
    fclose(outinter);
    remove("assembly.temp");
}

void stmt(void)
{
    /* stmt -> id := expr
            | if expr then stmt
            | while expr do stmt
            | begin opt_stmts end */

    char *tempvar, *tempvar2;
    if (match(NUM_OR_ID))
    {
        if (isalpha(idname[0])) {
            if (!present(symbol_list, idname, yyleng)) {
                symbol_list = push(symbol_list, idname, yyleng);
            }
        }
        else {
            fprintf(stderr, "%d: Cannot assign value to integer %s\n", yylineno, idname);
        }  
        advance();
        if (match(ASSIGN))
        {
            char var[32];
            strncpy(var, idname, yyleng);
            advance();
            tempvar = expr(0);
            if(!match(SEMI)){
                fprintf( stderr, "%d: Inserting missing semicolon\n", yylineno );
            }
            advance();
            fprintf(outinter, "%s = %s\n", var, tempvar);
            fprintf(outtemp, "MOV %s, %s\n", var, tempvar);
            freename(tempvar);
        }
    }
    else if (match(IF))
    {
        advance();
        tempvar = expr(1);
        freename(tempvar);
        int curr_label = if_label;
        if_label++;
        if (match(THEN))
        {
            advance();
            stmt();
            fprintf(outinter, "}\n");
            fprintf(outtemp, "line_%d:\n", curr_label); 
        }
        else
        {
            fprintf(stderr, "%d: Missing then after if\n", yylineno);
        }
               
    }
    else if (match(WHILE))
    {
        advance();
        int curr_label = while_label;
        int cond_label = if_label;
        while_label++;

        fprintf(outtemp, "while_%d:\n", curr_label);
        tempvar = expr(2);
        freename(tempvar);
        if_label++;
        
        if (match(DO))
        {
            advance();
            stmt();
            fprintf(outtemp, "JMP while_%d\n", curr_label);
            fprintf(outtemp, "line_%d:\n", cond_label);
            fprintf(outinter, "}\n");        
        }
        else
        {
            fprintf(stderr, "%d: Missing do after while\n", yylineno);
        }
    }
    else if (match(BEGIN))
    {
        advance();
        stmt_list();
    }
    return;
}

void stmt_list(void)
{
    /* stmt_list -> stmt stmt_list'
       stmt_list' -> stmt stmt_list' |  END */

    char *tempvar, *tempvar2;

    while (!match(END))
    {
        stmt();
    }
    advance();
    return;
}

char *expr(int flag)
{
    /*expr -> expression GREAT expression
            | expression LESS expression
            | expression EQUAL expression
            | expression */

    char *tempvar, *tempvar2;
    tempvar = expression();
    if (match(GREAT))
    {
        advance();
        tempvar2 = expression();
        if (flag == 1){  
            fprintf(outinter, "if (%s > %s) {\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar,tempvar2);
            fprintf(outtemp, "JNG line_%d\n", if_label);
        } 
        else if (flag == 2){
            fprintf(outinter, "while (%s > %s) {\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar,tempvar2);
            fprintf(outtemp, "JNG line_%d\n", if_label);
        }
        else if (flag == 0){
            fprintf(outinter, "%s > %s\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar, tempvar2);
            fprintf(outtemp, "MOV %s, 0\n", tempvar);            
            fprintf(outtemp, "JNG line_%d\n", if_label);
            fprintf(outtemp, "MOV %s, 1\n", tempvar);
            fprintf(outtemp, "line_%d:\n", if_label);
            if_label++;      
        }
        freename(tempvar2);
    }
    else if (match(LESS))
    {
        advance();
        tempvar2 = expression();
        if (flag == 1)  {
            fprintf(outinter, "if (%s < %s) {\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar,tempvar2);
            fprintf(outtemp, "JNL line_%d\n", if_label);
        }
        else if (flag == 2) {
            fprintf(outinter, "while (%s < %s) {\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar,tempvar2);
            fprintf(outtemp, "JNL line_%d\n", if_label);
        }
        else if (flag == 0) {
            fprintf(outinter, "%s < %s\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar, tempvar2);
            fprintf(outtemp, "MOV %s, 0\n", tempvar);            
            fprintf(outtemp, "JNL line_%d\n", if_label);
            fprintf(outtemp, "MOV %s, 1\n", tempvar);
            fprintf(outtemp, "line_%d:\n", if_label);
            if_label++;
        }
        freename(tempvar2);
    }
    else if (match(EQUAL))
    {
        advance();
        tempvar2 = expression();
        if (flag == 1)  {
            fprintf(outinter, "if (%s == %s) {\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar,tempvar2);
            fprintf(outtemp, "JNE line_%d\n", if_label);
        }
        else if (flag == 2) {
            fprintf(outinter, "while (%s == %s) {\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar,tempvar2);
            fprintf(outtemp, "JNE line_%d\n", if_label);
        }
        else if (flag == 0) {
            fprintf(outinter, "%s == %s\n", tempvar, tempvar2);
            fprintf(outtemp, "CMP %s, %s\n", tempvar, tempvar2);
            fprintf(outtemp, "MOV %s, 0\n", tempvar);            
            fprintf(outtemp, "JNE line_%d\n", if_label);
            fprintf(outtemp, "MOV %s, 1\n", tempvar);
            fprintf(outtemp, "line_%d:\n", if_label);
            if_label++;
        }
        freename(tempvar2);
    }
    else {
        if (flag == 1)  {
            fprintf(outinter, "if (%s) {\n", tempvar);
            fprintf(outtemp, "CMP %s, 0\n", tempvar);
            fprintf(outtemp, "JE line_%d\n", if_label);
        }
        else if (flag == 2){
            fprintf(outinter, "while (%s) {\n", tempvar);
            fprintf(outtemp, "CMP %s, 0\n", tempvar);
            fprintf(outtemp, "JE line_%d\n", if_label);
        }
    }
    return tempvar;
}

char *expression(void)
{
    /* expression -> term expression'
     * expression' -> PLUS term expression' |  epsilon */

    char *tempvar, *tempvar2;
    tempvar = term();
    while (match(PLUS) || match(MINUS))
    {
        int type;
        if(match(PLUS)) {
            type = PLUS;
        }
        else {
            type = MINUS;
        }
        advance();
        tempvar2 = term();
        if(type == PLUS) {
            fprintf(outinter, "%s += %s\n", tempvar, tempvar2);
            fprintf(outtemp, "ADD %s, %s\n", tempvar, tempvar2);
        }
        else {
            fprintf(outinter, "%s -= %s\n", tempvar, tempvar2);
            fprintf(outtemp, "SUB %s, %s\n", tempvar, tempvar2);
        }
        freename(tempvar2);
    }
    return tempvar;
}

char *term(void)
{
    char *tempvar, *tempvar2;
    tempvar = factor();
    while (match(TIMES) || match(DIVIDE))
    {
        int type;
        if(match(TIMES)) {
            type = TIMES;
        }
        else {
            type = DIVIDE;
        }
        advance();
        tempvar2 = factor();
        if(type == TIMES){
            fprintf(outinter, "%s *= %s\n", tempvar, tempvar2);
            fprintf(outtemp, "MOV AL, %s\n", tempvar);
            fprintf(outtemp, "IMUL %s\n", tempvar2);
            fprintf(outtemp, "MOV %s, AL\n", tempvar);
        }
        else{
            fprintf(outinter, "%s /= %s\n", tempvar, tempvar2);
            fprintf(outtemp, "MOV AL, %s\n", tempvar);
            fprintf(outtemp, "IDIV %s\n", tempvar2);
            fprintf(outtemp, "MOV %s, AL\n", tempvar);
        }
        freename(tempvar2);
    }
    return tempvar;
}

char *factor()
{
    char *tempvar;
    if (match(NUM_OR_ID))
    {
        /* Print the assignment instruction. The %0.*s conversion is a form of
        * %X.Ys, where X is the field width and Y is the maximum number of
        * characters that will be printed (even if the string is longer). I'm
        * using the %0.*s to print the string because it's not \0 terminated.
        * The field has a default width of 0, but it will grow the size needed
        * to print the string. The ".*" tells printf() to take the maximum-
        * number-of-characters count from the next argument (yyleng).
        */
        if (isalpha(idname[0])) {
            if (!present(symbol_list, idname, yyleng)) {
                fprintf(stderr, "%d: Undeclared identifier %0.*s, inserting anyway\n", yylineno, yyleng, idname);
                symbol_list = push(symbol_list, idname, yyleng);
            }
        }
        fprintf(outinter, "%s = %0.*s\n", tempvar = newname(), yyleng, yytext);
        fprintf(outtemp, "MOV %s, %0.*s\n", tempvar, yyleng, yytext);
        advance();
    }
    else if (match(LP))
    {   
        advance();
        tempvar = expression();
        if (match(RP))
            advance();
        else
            fprintf(stderr, "%d: Mismatched parenthesis\n", yylineno);
    }
    else
    {
        fprintf(stderr, "%d: Number or identifier expected\n", yylineno);
    }
    return tempvar;
}

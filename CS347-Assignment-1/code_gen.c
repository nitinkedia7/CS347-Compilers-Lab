#include <stdio.h>
#include "name.c"
#include "lex.c"
#include <stdarg.h>

#define MAXFIRST 16
#define SYNCH	 SEMI

int	legal_lookahead(int first_arg, ...)
{
    /* Simple error detection and recovery. Arguments are a 0-terminated list of
     * those tokens that can legitimately come next in the input. If the list is
     * empty, the end of file must come next. Print an error message if
     * necessary. Error recovery is performed by discarding all input symbols
     * until one that's in the input list is found
     *
     * Return true if there's no error or if we recovered from the error,
     * false if we can't recover.
     */

    va_list  	args;
    int		tok;
    int		lookaheads[MAXFIRST], *p = lookaheads, *current;
    int		error_printed = 0;
    int		rval	      = 0;

    va_start( args, first_arg );

    if( !first_arg )
    {
	if( match(EOI) )
	    rval = 1;
    }
    else
    {
	*p++ = first_arg;
	while( (tok = va_arg(args, int)) && p < &lookaheads[MAXFIRST] )
	    *p++ = tok;

	while( !match( SYNCH ) )
	{
	    for( current = lookaheads; current < p ; ++current )
		if( match( *current ) )
		{
		    rval = 1;
		    goto exit;
		}

	    if( !error_printed )
	    {
		fprintf( stderr, "Line %d: Syntax error\n", yylineno );
		error_printed = 1;
	    }

	    advance();
	}
    }

exit:
    va_end( args );
    return rval;
}

void terminate() {
    remove("./output/assembly.temp");
    remove("./output/assembly.txt");
    remove("./output/intermediate.txt");  
    exit(1);
}

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

    outtemp = fopen("./output/assembly.temp", "w+");
    outinter = fopen("./output/intermediate.txt", "w");
    outasm = fopen("./output/assembly.txt", "w");
    
    while(!match(EOI)){
        stmt();
    }

    fprintf(outtemp, "RET\nEND\n");
    fprintf(outasm, "org 100h\n");
    fprintf(outasm, ".DATA\n");
    symbol* temp_symbol = symbol_list;
    while(temp_symbol!=NULL){
        fprintf(outasm, "_%s DB ?\n", temp_symbol->idname);
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
    remove("./output/assembly.temp");
}

void stmt(void)
{
    /* stmt -> id := expr
            | if expr then stmt
            | while expr do stmt
            | begin opt_stmts end */

    char *tempvar, *tempvar2;
    if (match(ID))
    {
        if (!present(symbol_list, idname, yyleng)) {
            symbol_list = push(symbol_list, idname, yyleng);
        }
        advance();
        if (match(ASSIGN))
        {
            char var[32];
            strncpy(var, idname, idlength+1);
            advance();
            tempvar = expr(0);

            if(match(SEMI)){
                advance();
            }
            else {
                fprintf( stderr, "%d: missing semicolon\n", yylineno );
                terminate();
            }
            fprintf(outinter, "_%s = %s\n", var, tempvar);
            fprintf(outtemp, "MOV _%s, %s\n", var, tempvar);
            freename(tempvar);
        }
        else {
            loopback();
            tempvar = expr(0);
            if(!match(SEMI)){
                fprintf( stderr, "%d: Missing semicolon\n", yylineno );
                terminate();
            }
            advance();
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
            terminate();
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
            terminate();
        }
    }
    else if (match(BEGIN))
    {
        advance();
        stmt_list();
    }
    else {
        tempvar = expr(0);
        if(!match(SEMI)){
            fprintf( stderr, "%d: Missing semicolon\n", yylineno );
            terminate();
        }
        advance();
        freename(tempvar);    
    }
    return;
}

void stmt_list(void)
{
    /* stmt_list -> stmt stmt_list  | END */
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
        else if (match(ASSIGN)){
            fprintf( stderr, "%d: Fatal error: unknown :=\n", yylineno );
            terminate();
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
            fprintf(outtemp, "MOV AH, 0\n");
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
    if (match(ID)||match(NUM))
    {
        /* Print the assignment instruction. The %0.*s conversion is a form of
        * %X.Ys, where X is the field width and Y is the maximum number of
        * characters that will be printed (even if the string is longer). I'm
        * using the %0.*s to print the string because it's not \0 terminated.
        * The field has a default width of 0, but it will grow the size needed
        * to print the string. The ".*" tells printf() to take the maximum-
        * number-of-characters count from the next argument (yyleng).
        */
        if (match(ID)) {
            if (!present(symbol_list, idname, yyleng)) {
                fprintf(stderr, "%d: Undeclared identifier %1.*s\n", yylineno, yyleng, idname);
                terminate();
            }        
            fprintf(outinter, "%s = _%1.*s\n", tempvar = newname(), yyleng, yytext);
            fprintf(outtemp, "MOV %s, _%1.*s\n", tempvar, yyleng, yytext);
            advance();    
        }
        else { 
            fprintf(outinter, "%s = %1.*s\n", tempvar = newname(), yyleng, yytext);
            fprintf(outtemp, "MOV %s, %1.*s\n", tempvar, yyleng, yytext);
            advance();
        }
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
        terminate();
    }
    return tempvar;
}

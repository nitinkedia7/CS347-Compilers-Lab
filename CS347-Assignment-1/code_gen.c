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

void print_tabs(int t){
    int i=0;
    for(i=0;i<t;i++){
        printf("\t");
    }
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
int tabs=0;

void statements(void){
    /* statements -> stmt statements | stmt */

    outtemp = fopen("./output/assembly.temp", "w+");
    outinter = fopen("./output/intermediate.txt", "w");
    outasm = fopen("./output/assembly.txt", "w");\
    
    int tab2=0;
    while(!match(EOI)){
        print_tabs(tabs);
        printf("statements()\n");
        tabs++;
        tab2++;
        stmt();
        // tab2++;
        // tabs++;
        // tabs--;
    }
    tabs -= tab2;
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
    
    print_tabs(tabs);
    printf("stmt()\n");
    tabs++;
    char *tempvar, *tempvar2;
    if (match(ID))
    {
        if (!present(symbol_list, idname, yyleng)) {
            symbol_list = push(symbol_list, idname, yyleng);
        }
        advance();
        print_tabs(tabs);
        printf("< ID %1.*s > \n", idlength, idname);
        if (match(ASSIGN))
        {
            print_tabs(tabs);
            printf("ASSIGN\n");
            char var[32];
            strncpy(var, idname, idlength+1);
            advance();
            tempvar = expr(0);
            if(match(SEMI)){
                print_tabs(tabs);
                printf("SEMI\n");
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
        print_tabs(tabs);
        printf("IF\n");
        tempvar = expr(1);
        freename(tempvar);
        int curr_label = if_label;
        if_label++;
        if (match(THEN))
        {
            print_tabs(tabs);
            printf("THEN\n");
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
        print_tabs(tabs);
        printf("WHILE\n");
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
            print_tabs(tabs);
            printf("DO\n");
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
        print_tabs(tabs);
        printf("BEGIN\n");
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
    tabs--;
    return;
}

void stmt_list(void)
{
    /* stmt_list -> stmt stmt_list  | END */
    // tabs++;
    int tabs2 = 0;
    print_tabs(tabs);
    printf("stmt_list()\n");
    while (!match(END))
    {
        tabs2++;
        tabs++;
        stmt();
        // tabs--;
        print_tabs(tabs);
        printf("stmt_list()\n");
    }
    tabs++;
    print_tabs(tabs);
    printf("END\n");
    tabs--;
    tabs -= tabs2;
    advance();
    return;
}

char *expr(int flag)
{
    /*expr -> expression GREAT expression
            | expression LESS expression
            | expression EQUAL expression
            | expression */
    print_tabs(tabs);
    printf("expr()\n");
    tabs++;
    char *tempvar, *tempvar2;
    tempvar = expression();
    if (match(GREAT))
    {
        print_tabs(tabs);
        printf("GREAT\n");
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
        print_tabs(tabs);
        printf("LESS\n");
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
        print_tabs(tabs);
        printf("EQUAL\n");
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
    tabs--;
    return tempvar;
}

char *expression(void)
{
    /* expression -> term expression'
     * expression' -> PLUS term expression' |  epsilon */
    print_tabs(tabs);
    printf("expression()\n");
    tabs++;
    char *tempvar, *tempvar2;
    tempvar = term();
    int tabs2=0;
    while (match(PLUS) || match(MINUS))
    {
        int type;
        if(match(PLUS)) {
            print_tabs(tabs);
            printf("PLUS\n");
            type = PLUS;
        }
        else {
            print_tabs(tabs);
            printf("MINUS\n");
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
        tabs++, tabs2++;
        freename(tempvar2);
    }
    tabs-=tabs2;
    tabs--;
    return tempvar;
}

char *term(void)
{
    print_tabs(tabs);
    printf("term()\n");
    tabs++;
    char *tempvar, *tempvar2;
    tempvar = factor();
    int tabs2=0;
    while (match(TIMES) || match(DIVIDE))
    {
        
        int type;
        if(match(TIMES)) {
            print_tabs(tabs);
            printf("TIMES\n");
            type = TIMES;
        }
        else {
            print_tabs(tabs);
            printf("DIVIDE\n");
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
        tabs++, tabs2++;
        freename(tempvar2);
    }
    tabs-=tabs2;
    tabs--;
    return tempvar;
}

char *factor()
{
    char *tempvar;
    print_tabs(tabs);
    printf("factor()\n");
    tabs++;
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
            print_tabs(tabs);
            printf(" < ID %1.*s > \n", yyleng, yytext);    
            fprintf(outinter, "%s = _%1.*s\n", tempvar = newname(), yyleng, yytext);
            fprintf(outtemp, "MOV %s, _%1.*s\n", tempvar, yyleng, yytext);
            advance();    
        }
        else { 
            print_tabs(tabs);
            printf(" < NUM %1.*s > \n", yyleng, yytext);
            fprintf(outinter, "%s = %1.*s\n", tempvar = newname(), yyleng, yytext);
            fprintf(outtemp, "MOV %s, %1.*s\n", tempvar, yyleng, yytext);
            advance();
        }
    }
    else if (match(LP))
    {   
        print_tabs(tabs);
        printf("LP\n");
        advance();
        tempvar = expression();
        if (match(RP)){
            print_tabs(tabs);
            printf("RP\n");
            advance();
        }
        else
            fprintf(stderr, "%d: Mismatched parenthesis\n", yylineno);
    }
    else
    {
        fprintf(stderr, "%d: Number or identifier expected\n", yylineno);
        terminate();
    }
    tabs--;
    return tempvar;
}

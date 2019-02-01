#include <stdio.h>
#include "name.c"
#include "lex.c"

char *factor(void);
char *term(void);
char *expression(void);
void stmt(void);
char *expr(int);
void stmt_list(void);

extern char *newname(void);
extern void freename(char *name);
int assignment_found;

void statements(void){
    // statements -> stmt statements | stmt
    // stmt();
    while(!match(EOI)){
        // printf("statements hjgk\n");
        // char* tempvar = stmt();
        stmt();
        // freename(tempvar);
    }

}

void stmt(void)
{
    /* stmt -> id := expr
            | if expr then stmt
            | while expr do stmt
            | begin opt_stmts end */
    // printf("stmt");
    char *tempvar, *tempvar2;
    if (match(NUM_OR_ID))
    {
        if (isalpha(idname[0])) {
            if (!present(symbol_list, idname)) {
                symbol_list = push(symbol_list, idname, yyleng);
            }
        }
        else {
            fprintf(stderr, "%d: Cannot assign value to integer %s\n", yylineno, idname);
            exit(0);
        }
        advance();
        // printf("assign above\n");
        if (match(ASSIGN))
        {
            char *var = malloc(yyleng + 1);
            strncpy(var, idname, yyleng);
            advance();
            assignment_found = 1;
            tempvar = expr(0);
            if(!match(SEMI)){
                fprintf( stderr, "%d: Inserting missing semicolon\n", yylineno );
            }
            advance();
            printf("%s = %s\n", var, tempvar);
            freename(tempvar);
        }
    }
    else if (match(IF))
    {
        advance();
        tempvar = expr(1);
        freename(tempvar);
        if (match(THEN))
        {
            // printf("then\n");
            advance();
            stmt();
            // tempvar2 = stmt();
            printf("}\n");
        }
        else
        {
            fprintf(stderr, "error!!");
        }
    }
    else if (match(WHILE))
    {
        advance();
        tempvar = expr(2);
        freename(tempvar);
        if (match(DO))
        {
            advance();
            // tempvar2 = stmt();
            stmt();
            printf("}\n");        
        }
        else
        {
            fprintf(stderr, "error!!");
        }
        // tempvar2 = stmt();
    }
    else if (match(BEGIN))
    {
        advance();
        stmt_list();
    }
    // return tempvar;
    // freename(tempvar);
}

void stmt_list(void)
{
    /* stmt_list -> stmt stmt_list'
       stmt_list' -> stmt stmt_list' |  epsilon */

    char *tempvar, *tempvar2;
    // tempvar = stmt();
    while (!match(END))
    {
        // printf("stmt caught\n");
        stmt();
        // tempvar = stmt();
        // freename(tempvar);
    }
    advance();
    // assert(match(END));
    // freename(tempvar);
    return;
}

char *expr(int flag)
{
    /*expr -> expression GREAT expression
            | expression LESS expression
            | expression EQUAL expression
            | expression */

    // printf("aaya\n");
    char *tempvar, *tempvar2;
    tempvar = expression();
    // printf("comparing\n");
    if (match(GREAT))
    {
        advance();
        tempvar2 = expression();
        // printf("    %s -= %s\n", tempvar, tempvar2);
        if (flag == 1)  printf("if (%s > %s) {\n", tempvar, tempvar2);
        else if (flag == 2) printf("while (%s > %s) {\n", tempvar, tempvar2);
        else if (flag == 0) printf("%s > %s\n", tempvar, tempvar2);

        if(assignment_found){
            assignment_found = 0;
        }
        freename(tempvar2);
    }
    else if (match(LESS))
    {
        advance();
        tempvar2 = expression();
        // printf("    %s -= %s\n", tempvar, tempvar2);
        if (flag == 1)  printf("if (%s < %s) {\n", tempvar, tempvar2);
        else if (flag == 2) printf("while (%s < %s) {\n", tempvar, tempvar2);
        else if (flag == 0) printf("%s < %s\n", tempvar, tempvar2);
        if(assignment_found){
            assignment_found = 0;
        }
        freename(tempvar2);
    }
    else if (match(EQUAL))
    {
        advance();
        tempvar2 = expression();
        // printf("    %s -= %s\n", tempvar, tempvar2);
        if (flag == 1)  printf("if (%s == %s) {\n", tempvar, tempvar2);
        else if (flag == 2) printf("while (%s == %s) {\n", tempvar, tempvar2);
        else if (flag == 0) printf("%s == %s\n", tempvar, tempvar2);
        if(assignment_found){
            assignment_found = 0;
        }
        freename(tempvar2);
    }
    else {
        if (flag == 1)  printf("if (%s) {\n", tempvar);
        else if (flag == 2) printf("while (%s) {\n", tempvar);
        // else if (flag == 0) printf("%s > %s\n", tempvar, tempvar2);
        // printf("(%s)\n", tempvar);
    }

    return tempvar;
}

char *expression()
{
    /* expression -> term expression'
     * expression' -> PLUS term expression' |  epsilon
     */

    char *tempvar, *tempvar2;
    // printf("upar");
    tempvar = term();
    // printf("expre");
    while (match(PLUS) || match(MINUS))
    {
        // printf("plus");
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
            printf("%s += %s\n", tempvar, tempvar2);
        }
        else{
            printf("    %s -= %s\n", tempvar, tempvar2);
        }
        
        freename(tempvar2);
    }
    // while( match(PLUS)){
    //     advance();
    //     tempvar2 =term();
    //     printf("   %s += %s\n", tempvar, tempvar2 );
    //     freename( tempvar2 );
    // }
    // printf("niche %s\n", tempvar);
    return tempvar;
}

char *term()
{
    char *tempvar, *tempvar2;
    // printf("term hua\n");
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
            printf("%s *= %s\n", tempvar, tempvar2);
        }
        else{
            printf("%s /= %s\n", tempvar, tempvar2);
        }
        freename(tempvar2);
    }

    return tempvar;
}

char *factor()
{
    char *tempvar;
    // printf("factor hua\n");
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
        // printf("factor 1 hua\n");
        if (isalpha(idname[0])) {
            if (!present(symbol_list, idname)) {
                fprintf(stderr, "%d: Undeclared identifier %s, inserting anyway\n", yylineno, idname);
                symbol_list = push(symbol_list, idname, yyleng);
            }
        }
        printf("%s = %0.*s\n", tempvar = newname(), yyleng, yytext);
        advance();
    }
    else if (match(LP))
    {   
        // printf("factor 2 hua\n");
        advance();
        tempvar = expression();
        if (match(RP))
            advance();
        else
            fprintf(stderr, "%d: Mismatched parenthesis\n", yylineno);
    }
    else{
        // printf("factor 3 hua\n");
        fprintf(stderr, "%d: Number or identifier expected\n", yylineno);
    }
    return tempvar;
}

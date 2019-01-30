#include <stdio.h>
// #include "lex.h"
#include "name.c"
#include "lex.c"

char    *factor     ( void );
char    *term       ( void );
char    *expression ( void );
char    *stmt       ( void );
char    *expr       ( void );
char    *opt_stmts  ( void );

extern char *newname( void       );
extern void freename( char *name );

char    *stmt_list(void)
{
    /* stmt_list -> stmt stmt_list'
       stmt_list' -> SEMI stmt stmt_list' |  epsilon */

    char  *tempvar, *tempvar2;
    printf("start\n");
    tempvar = stmt();
    while( match( SEMI ) )
    {
        advance();
        tempvar2 = stmt();
        // printf("    %s += %s\n", tempvar, tempvar2 );
        freename( tempvar2 );
    }

    return tempvar;
}

char    *stmt(void)
{
    /* stmt -> id := expr
            | if expr then stmt
            | while expr do stmt
            | begin opt_stmts end */

    char *tempvar, *tempvar2;
    if(match(NUM_OR_ID)){
        advance();
        if(match(ASSIGN)){
            char *var = malloc(yyleng + 1);
            strncpy(var, idname, yyleng);
            advance();
            tempvar = expr();
            printf("    %s := %s\n", var, tempvar );
        }
    } else if(match(IF)){
        advance();
        tempvar = expr();
        if(match(THEN)){
            advance();
            tempvar2 = stmt();
        } else {
            fprintf(stderr, "error!!");
        }
    } else if(match(WHILE)){
        advance();
        tempvar = expr();
        if(match(DO)){
            advance();
            tempvar2 = stmt();
        } else {
            fprintf(stderr, "error!!");
        }
        tempvar2 = stmt();
    } else if(match(BEGIN)){
        advance();
        tempvar = opt_stmts();
    }
    
}

char    *expr(void)
{
    /*expr -> expression GREAT expression
            | expression LESS expression
            | expression EQUAL expression
            | expression*/
    
    char *tempvar, *tempvar2;
    tempvar = expression();
    printf("%s\n", tempvar);
    // return tempvar;
    // if(match(GREAT)){
    //     advance();
    //     tempvar2 = expression();
    //     freename(tempvar2);
    // } else if(match(LESS)){
    //     advance();
    //     tempvar2 = expression();
    //     freename(tempvar2);
    // } else if(match(EQUAL)){
    //     advance();
    //     tempvar2 = expression();
    //     freename(tempvar2);
    // }
    return tempvar;

}

char    *opt_stmts(void)
{
    /* opt_stmts -> stmt_list |  epsilon */
    char *tempvar;
    tempvar = stmt_list();
    return tempvar;
}

char    *expression()
{
    /* expression -> term expression'
     * expression' -> PLUS term expression' |  epsilon
     */

    char  *tempvar, *tempvar2;

    tempvar = term();

    while( match( PLUS ) )
    {
        advance();
        tempvar2 = term();
        // printf("%s\n", tempvar2);
        printf("    %s += %s\n", tempvar, tempvar2 );
        freename( tempvar2 );
    }

    return tempvar;
}

char    *term()
{
    char  *tempvar, *tempvar2 ;

    tempvar = factor();
    while( match( TIMES ))
    {
        advance();
        tempvar2 = factor();
        printf("    %s *= %s\n", tempvar, tempvar2 );
        freename( tempvar2 );
    }

    return tempvar;
}

char    *factor()
{
    char *tempvar;

    if( match(NUM_OR_ID) )
    {
	/* Print the assignment instruction. The %0.*s conversion is a form of
	 * %X.Ys, where X is the field width and Y is the maximum number of
	 * characters that will be printed (even if the string is longer). I'm
	 * using the %0.*s to print the string because it's not \0 terminated.
	 * The field has a default width of 0, but it will grow the size needed
	 * to print the string. The ".*" tells printf() to take the maximum-
	 * number-of-characters count from the next argument (yyleng).
	 */

        printf("    %s = %0.*s\n", tempvar = newname(), yyleng, yytext );
        advance();
    }
    else if( match(LP) )
    {
        advance();
        tempvar = expression();
        if( match(RP) )
            advance();
        else
            fprintf(stderr, "%d: Mismatched parenthesis\n", yylineno );
    }
    else
	fprintf( stderr, "%d: Number or identifier expected\n", yylineno );

    return tempvar;
}

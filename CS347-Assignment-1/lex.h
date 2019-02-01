#define EOI		    0	/* End of input			*/
#define SEMI		1	/* ; 				*/
#define PLUS 		2	/* + 				*/
#define TIMES		3	/* * 				*/
#define LP		    4	/* (				*/
#define RP		    5	/* )				*/
#define NUM_OR_ID	6	/* Decimal Number or Identifier */
#define MINUS       7
#define DIVIDE      8
#define LESS        9
#define GREAT       10
#define EQUAL       11
#define ASSIGN      12
#define IF          13
#define THEN        14
#define WHILE       15
#define DO          16
#define BEGIN       17
#define END         18
#define ID          19

extern char *yytext;		/* in lex.c			*/
extern int yyleng;
extern int yylineno;
extern char idname[32];

int lex(void);
int match(int);
void advance(void);
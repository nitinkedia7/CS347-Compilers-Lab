%{
# include "miniC.tab.h"
%}

%%
"int"                           { printf("<%s>", yytext);return INT; }
"float"                         { printf("<%s>", yytext);return FLOAT; }
"void"                          { printf("<%s>", yytext);return VOID; }
"if"                            { printf("<%s>", yytext);return IF; }
"else"                          { printf("<%s>", yytext);return ELSE; }
"case"                          { printf("<%s>", yytext);return CASE; }
"break"                         { printf("<%s>", yytext);return BREAK; }
"default"                       { printf("<%s>", yytext);return DEFAULT; }
"continue"                      { printf("<%s>", yytext);return CONTINUE; }
"while"                         { printf("<%s>", yytext);return WHILE; }
"for"                           { printf("<%s>", yytext);return FOR; }
"return"                        { printf("<%s>", yytext);return RETURN; }
"switch"                        { printf("<%s>", yytext);return SWITCH; }
"main"                          { printf("<%s>", yytext);return MAIN; }

"{"                             { printf("<%s>", yytext);return LCB; }
"}"                             { printf("<%s>", yytext);return RCB; }
";"                             { printf("<%s>", yytext);return SEMI; }
"<="                            { printf("<%s>", yytext);return LE; }
">="                            { printf("<%s>", yytext);return GE; }
"=="                            { printf("<%s>", yytext);return EQUAL; }
"!="                            { printf("<%s>", yytext);return NOTEQUAL; }
"<<"                            { printf("<%s>", yytext);return LSHIFT; }
">>"                            { printf("<%s>", yytext);return RSHIFT; }
"&&"                            { printf("<%s>", yytext);return AND; }
"||"                            { printf("<%s>", yytext);return OR; }
"+="                            { printf("<%s>", yytext);return PLUSASG; }
"-="                            { printf("<%s>", yytext);return MINASG; }
"*="                            { printf("<%s>", yytext);return MULASG; }
"%="                            { printf("<%s>", yytext);return MODASG; }
"/="                            { printf("<%s>", yytext);return DIVASG; }
"++"                            { printf("<%s>", yytext);return INCREMENT; }
"--"                            { printf("<%s>", yytext);return DECREMENT; }
":"                             { printf("<%s>", yytext);return COLON; }
"?"                             { printf("<%s>", yytext);return QUESTION; }
"["                             { printf("<%s>", yytext);return LSB; }
"]"                             { printf("<%s>", yytext);return RSB; }
"("                             { printf("<%s>", yytext);return LP; }
")"                             { printf("<%s>", yytext);return RP; }
","                             { printf("<%s>", yytext);return COMMA; }
"="                             { printf("<%s>", yytext);return ASSIGN; }
"<"                             { printf("<%s>", yytext);return LT; }
">"                             { printf("<%s>", yytext);return GT; }
"!"                             { printf("<%s>", yytext);return NOT; }
"^"                             { printf("<%s>", yytext);return XOR; }
"&"                             { printf("<%s>", yytext);return BITAND; }
"|"                             { printf("<%s>", yytext);return BITOR; }
"+"                             { printf("<%s>", yytext);return PLUS; }
"-"                             { printf("<%s>", yytext);return MINUS; }
"/"                             { printf("<%s>", yytext);return DIV; }
"*"                             { printf("<%s>", yytext);return MUL; }
"%"                             { printf("<%s>", yytext);return MOD; }

[0-9]+\.[0-9]*                  { yylval.intval = atoi(yytext); printf("<%s>", yytext);return NUMFLOAT; }
[0-9]+                          { yylval.floatval = atof(yytext); printf("<%s>", yytext);return NUMINT; }
[a-zA-Z_][a-zA-Z_0-9]*          { yylval.text = malloc(128); memset(yylval.text, 0, 128) ; printf("<%s>", yytext);return ID; }

\n                              { printf("\n");yylineno++;}
[ \t]                           {/* ignore whitespace */ }
%%
%{    
# include "inter.tab.h"
%}
%option noyywrap
%%


"function"                     { printf(" <%s> ", yytext);return FUNCTION; }
"begin"                        { printf(" <%s> ", yytext);return BEG; }
"if"                           { printf(" <%s> ", yytext);return IF; }
"goto"                         { printf(" <%s> ", yytext);return GOTO; }
"param"                        { printf(" <%s> ", yytext);return PARAM; }
"refparam"                     { printf(" <%s> ", yytext);return REFPARAM; }
"call"                         { printf(" <%s> ", yytext);return CALL; }
"end"                          { printf(" <%s> ", yytext);return END; }
"return"                       { printf(" <%s> ", yytext);return RETURN; }
"convertToFloat"                { printf(" <%s> ", yytext);return CONVERTFLOAT; }
"convertToInt"                { printf(" <%s> ", yytext);return CONVERTINT; }

"<="                            { printf(" <%s> ", yytext);return LE; }
">="                            { printf(" <%s> ", yytext);return GE; }
"=="                            { printf(" <%s> ", yytext);return EQUAL; }
"!="                            { printf(" <%s> ", yytext);return NOTEQUAL; }
"&&"                            { printf(" <%s> ", yytext);return AND; }
"||"                            { printf(" <%s> ", yytext);return OR; }
":"                             { printf(" <%s> ", yytext);return COLON; }
"["                             { printf(" <%s> ", yytext);return LSB; }
"]"                             { printf(" <%s> ", yytext);return RSB; }
"("                             { printf(" <%s> ", yytext);return LP; }
")"                             { printf(" <%s> ", yytext);return RP; }
","                             { printf(" <%s> ", yytext);return COMMA; }
"="                             { printf(" <%s> ", yytext);return ASSIGN; }
"<"                             { printf(" <%s> ", yytext);return LT; }
">"                             { printf(" <%s> ", yytext);return GT; }
"~"                             { printf(" <%s> ", yytext);return NEG; }
"+"                             { printf(" <%s> ", yytext);return PLUS; }
"-"                             { printf(" <%s> ", yytext);return MINUS; }
"/"                             { printf(" <%s> ", yytext);return DIV; }
"*"                             { printf(" <%s> ", yytext);return MUL; }
"%"                             { printf(" <%s> ", yytext);return MOD; }

[0-9]+\.[0-9]*                  { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); printf(" <%s> ", yytext);return NUMFLOAT; }
[0-9]+                          { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); printf(" <%s> ", yytext);return NUMINT; }
[T][0-9]+                       { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); printf(" <%s> ", yytext);return REGINT; }
[F][0-9]+                       { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); printf(" <%s> ", yytext);return REGFLOAT; }
[L][0-9]+                       { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); printf(" <%s> ", yytext);return LABEL; }   
[_a-zA-Z][a-zA-Z_0-9]*          { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); printf(" <%s> ", yytext);return USERVAR; }

\n                              { printf("\n");yylineno++;return NEWLINE;}
[ \t]                           {/* ignore whitespace */ }
%%
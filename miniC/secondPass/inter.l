%{    
# include "inter.tab.h"
%}
%option noyywrap
%%

"function"                      { return FUNCTION; }
"begin"                         { return BEG; }
"if"                            { return IF; }
"goto"                          { return GOTO; }
"param"                         { return PARAM; }
"refparam"                      { return REFPARAM; }
"call"                          { return CALL; }
"end"                           { return END; }
"return"                        { return RETURN; }
"convertToFloat"                { return CONVERTFLOAT; }
"convertToInt"                  { return CONVERTINT; }
"print"                         { return PRINT;}
"read"                          { return READ; }
"<="                            { return LE; }
">="                            { return GE; }
"=="                            { return EQUAL; }
"!="                            { return NOTEQUAL; }
"&&"                            { return AND; }
"||"                            { return OR; }
":"                             { return COLON; }
"["                             { return LSB; }
"]"                             { return RSB; }
"("                             { return LP; }
")"                             { return RP; }
","                             { return COMMA; }
"="                             { return ASSIGN; }
"<"                             { return LT; }
">"                             { return GT; }
"~"                             { return NEG; }
"+"                             { return PLUS; }
"/"                             { return DIV; }
"*"                             { return MUL; }
"%"                             { return MOD; }

-[0-9]+\.[0-9]*|[0-9]+\.[0-9]*  { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return NUMFLOAT; }
-[0-9]+|[0-9]+                  { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return NUMINT; }
"-"                             { return MINUS; }
[T][0-9]+                       { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return REGINT; }
[F][0-9]+                       { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return REGFLOAT; }
[L][0-9]+                       { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return LABEL; }   
[_a-zA-Z][a-zA-Z_0-9]*          { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return USERVAR; }

\n                              { yylineno++;return NEWLINE;}
[ \t]                           { /* ignore whitespace */ }
%%
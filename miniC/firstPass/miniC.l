%{    
# include "miniC.tab.h"
%}
%option noyywrap
%%
"int"                           { return INT; }
"float"                         { return FLOAT; }
"void"                          { return VOID; }
"if"                            { return IF; }
"else"                          { return ELSE; }
"case"                          { return CASE; }
"break"                         { return BREAK; }
"default"                       { return DEFAULT; }
"continue"                      { return CONTINUE; }
"while"                         { return WHILE; }
"for"                           { return FOR; }
"return"                        { return RETURN; }
"switch"                        { return SWITCH; }
"main"                          { return MAIN; }
"read"                          { return READ; }
"print"                         { return PRINT; }

"{"                             { return LCB; }
"}"                             { return RCB; }
";"                             { return SEMI; }
"<="                            { return LE; }
">="                            { return GE; }
"=="                            { return EQUAL; }
"!="                            { return NOTEQUAL; }
"<<"                            { return LSHIFT; }
">>"                            { return RSHIFT; }
"&&"                            { return AND; }
"||"                            { return OR; }
"+="                            { return PLUSASG; }
"-="                            { return MINASG; }
"*="                            { return MULASG; }
"%="                            { return MODASG; }
"/="                            { return DIVASG; }
"++"                            { return INCREMENT; }
"--"                            { return DECREMENT; }
":"                             { return COLON; }
"["                             { return LSB; }
"]"                             { return RSB; }
"("                             { return LP; }
")"                             { return RP; }
","                             { return COMMA; }
"="                             { return ASSIGN; }
"<"                             { return LT; }
">"                             { return GT; }
"!"                             { return NOT; }
"^"                             { return XOR; }
"&"                             { return BITAND; }
"|"                             { return BITOR; }
"+"                             { return PLUS; }
"-"                             { return MINUS; }
"/"                             { return DIV; }
"*"                             { return MUL; }
"%"                             { return MOD; }

[0-9]+\.[0-9]+                  { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return NUMFLOAT; }
[0-9]+                          { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return NUMINT; }
[a-zA-Z_][a-zA-Z_0-9]*          { yylval.idName = (char *)malloc(100); memset(yylval.idName, 0, 100); memcpy(yylval.idName, yytext, yyleng); return ID; }

\n                              { yylineno++;}
[ \t]                           {/* ignore whitespace */ }
%%
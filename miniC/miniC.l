%{
# include "miniC.tab.h"
%}

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

"<="                            { return LE; }
">="                            { return GE; }
"=="                            { return EQUAL; }
"!="                            { return NOTEQUAL; }
"<<"                            { return LSHIFT; }
">>"                            { return RSHIFT; }
"&&"                            { return AND; }
"||"                            { return OR; }
"+="                            { return PLUSEQUAL; }
"-="                            { return MINUSEQUAL; }
"*="                            { return MULEQUAL; }
"%="                            { return MODEQUAL; }
"/="                            { return DIVEQUAL; }
"++"                            { return INCREMENT; }
"--"                            { return DECREMENT; }
":"                             { return COLON; }
"?"                             { return QUESTION; }
"."                             { return DOT; }
"{"                             { return LCB; }
"}"                             { return RCB; }
"["                             { return LSB; }
"]"                             { return RSB; }
"("                             { return LP; }
")"                             { return RP; }
";"                             { return SEMI; }
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

[1-9][0-9]*\.[0-9]*             { return NUMFLOAT; }
0\.[0-9]*                       { return NUMFLOAT; }
[1-9][0-9]*                     { return NUMINT; }

[a-bA-B_][a-bA-B_0-9]*          { return id; }

\n                              { yylineno++; return NEWLINE; }
[ \t]                           { /* ignore whitespace */ }
%%
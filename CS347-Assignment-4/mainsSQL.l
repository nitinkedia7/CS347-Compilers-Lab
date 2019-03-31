%{
# include "mainsSQL.tab.h"
%}

%%
"SELECT"|"select"                          { return SELECT; }
"PROJECT"|"project"                         { return PROJECT; }
"CARTESIAN_PRODUCT"|"cartesian_product"               { return CARTESIAN_PRODUCT; }
"EQUI_JOIN"|"equi_join"                       { return EQUI_JOIN; }
"<="                            { return LE; }
">="                            { return GE; }
"!="                            { return NOT_EQUAL; } 
"<"                             { return LA; }
">"                             { return RA; } 
"="                             { return EQUAL; }             
"AND"|"and"                           { return AND; }
"OR"|"and"                            { return OR; }
"NOT"|"and"                           { return NOT; }
,                               { return COMMA; }
\.                              { return DOT; }
'[0-9A-Za-z_,]*'                { sprintf(yylval.text,"%s", yytext); return QUOTED_STRING; }
[(]                             { return LP; }
[)]                             { return RP; }
[A-Za-z_][0-9A-Za-z_]*          { sprintf(yylval.text,"%s", yytext); return ID; }
[0-9]+                          { yylval.intval = atoi(yytext); return INT; }
\n                              { yylineno++; return NEWLINE; }
[ \t]                           { /* ignore whitespace */ }
.                               { printf("Unknown character %c\n", *yytext); }
%%
%{
# include "mainsSQL.tab.h"
%}

%%
[Ss][Ee][Ll][Ee][Cc][Tt]                          { return SELECT;}
[Pp][Rr][Oo][Jj][Ee][Cc][Tt]                         { return PROJECT;}
CARTESIAN_PRODUCT               { return CARTESIAN_PRODUCT;}
EQUI_JOIN                       { return EQUI_JOIN;}
"<="                            { return LE;}
">="                            { return GE;}
"!="                            { return NOT_EQUAL;} 
"<"                             { return LA;}
">"                             { return RA;} 
"="                             { return EQUAL;}             
"AND"                           { return AND;}
"OR"                           { return OR;}
"NOT"                           { return NOT;}
,                               { return COMMA;}
\.                              { return DOT;}
'[A-Za-z_][0-9A-Za-z_]*'        { sprintf(yylval.text,"%s", yytext); return QUOTED_STRING;}
[(]                             { return LP;}
[)]                             { return RP;}
[A-Za-z_][0-9A-Za-z_]*          { sprintf(yylval.text,"%s", yytext); return ID; }
[0-9]+                          { yylval.intval = atoi(yytext); return INT; }
\n                              { yylineno++; return NEWLINE; }
[ \t]                           { /* ignore whitespace */ }
.                               { printf("Unknown character %c\n", *yytext);}
%%
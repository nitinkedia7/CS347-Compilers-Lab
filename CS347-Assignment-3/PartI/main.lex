%{
    int number_of_classes = 0;
    int number_of_inherited_classes = 0;
    int number_of_constructors=0;
    int number_of_overloading=0;
    int number_of_objects=0;
    int class_found = 0;
%}
wd   [A-Za-z_0-9]
st   [A-Za-z_]
OP \+=|-=|\*=|\/=|%=|\^=|&=|\|=|<<|>>|>>=|<<=|==|!=|<=|>=|<=>|&&|\|\||\+\+|--|\,|->\*|\\->|\(\s*\)|\[\s*\]|\+|-|\*|\/|%|\^|&|\||~|!|=|<|>
%option noyywrap
%x S1 S2 S3 A1 C1 C2 C3
%%
"/"                   BEGIN(S1);
<S1>"*"               BEGIN(S2);
<S2>[^*]              ;
<S2>"*"               BEGIN(S3);
<S3>"*"               ;
<S3>[^*/]             BEGIN(S2);
<S3>"/"               BEGIN(INITIAL);

"\""                  BEGIN(A1);
<A1>\\.               BEGIN(A1);
<A1>[^\\\"]           BEGIN(A1);
<A1>\"                BEGIN(INITIAL); 

"//"[^\n]*             ;

class[ ]+   BEGIN(C1);
<C1>{st}         {  BEGIN(C2) ; printf("%s", yytext) ;}
<C2>{wd}         { printf("%s", yytext) ; }
<C2>[ ]          BEGIN(C3);
<C3>[ ]               ;
<C2,C3>"{"               { BEGIN(INITIAL); }
[^A-Za-z_]operator" "*{OP}" "*([^\{\;\n]*)[\n\{]     {printf("%s\n", yytext);}    
.|\n                  
%%
void main(int argc, char **argv){
    argv++;
    argc--;
    if ( argc > 0 )
        yyin = fopen( argv[0], "r" );
    else
        yyin = stdin;
    yylex();
    printf("\nNumber of Classes           : %d\n", number_of_classes);
    printf("Number of Inherited classes : %d\n", number_of_inherited_classes);
    printf("Number of Constructors      : %d\n", number_of_constructors);
    printf("Number of Overloading       : %d\n", number_of_overloading);
    printf("Number of Objects           : %d\n", number_of_objects);
}
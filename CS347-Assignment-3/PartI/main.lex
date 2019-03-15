%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    void comments_removal(FILE*, FILE*);
    void increase_counts(void);
    void add_class(char*);
    int check_class(char*);
    void print_classes();
    void objects(char*);


    char temp_class[1460];
    char classes[10000][200];
    int tempi=0;
    int number_of_classes = 0;
    int number_of_inherited_classes = 0;
    int number_of_constructors=0;
    int number_of_overloading=0;
    int number_of_objects=0;
    int class_found = 0;
    int inherited_found = 0;
    int constructor_found = 0;
    int operator_found = 0;
    int object_found=0;
%}

wd   [A-Za-z_0-9]
st   [A-Za-z_]
OP \+=|-=|\*=|\/=|%=|\^=|&=|\|=|<<|>>|>>=|<<=|==|!=|<=|>=|<=>|&&|\|\||\+\+|--|\,|->\*|\\->|\(\s*\)|\[\s*\]|\+|-|\*|\/|%|\^|&|\||~|!|=|<|>
dec   public|private|protected

%option noyywrap
%x S1 S2 S3 A1 C1 C2 C3 C4 C5 X1 X2 X3 D1 D2 D3 D4 E1 E2 E3 E4 E5 
%%
"/*"                   BEGIN(S2);
<S2>[^*]              ;
<S2>"*"               BEGIN(S3);
<S3>"*"               ;
<S3>[^*/]             BEGIN(S2);
<S3>"/"               BEGIN(INITIAL);

<X2>[^*]              ;
<X2>"*"               BEGIN(X3);
<X3>"*"               ;
<X3>[^*/]             BEGIN(X2);
<X3>"/"               BEGIN(C2);

\"                    BEGIN(A1);
<A1>\\.               BEGIN(A1);
<A1>[^\\\"]           BEGIN(A1);
<A1>\"                BEGIN(INITIAL); 

"//"[^\n]*            increase_counts(); 

[^A-Za-z0-9_]class[ ]+    { if(yytext[0] == '\n'){increase_counts();} BEGIN(C1); }
<C1>{st}{wd}*             { /*printf("%s-hello", yytext) ;*/  memset(temp_class, 0, sizeof(temp_class)) ; snprintf(temp_class, 200, "%s", yytext); BEGIN(C2) ; }
<C2>" "                   { BEGIN(C2) ; } 
<C2>\n                    { class_found = 1; increase_counts(); add_class(temp_class); BEGIN(INITIAL);}
<C2>"{"|"//"[^\n]*        { class_found = 1; add_class(temp_class); /*printf("%s-was here\n", temp_class);*/ BEGIN(INITIAL); }
<C2>":"                   { BEGIN(C3); }  
<C2>"/*"                  { BEGIN(X2); }
<C2>[^\n{:]               { BEGIN(INITIAL);}
<C3>" "                   { BEGIN(C3); }
<C3>{dec}                 { BEGIN(C3); }
<C3>{st}{wd}*             { BEGIN(C4); }
<C4>" "                   { BEGIN(C4); }
<C4>","                   { BEGIN(C3); }
<C4>\n                    { inherited_found = 1, class_found = 1; increase_counts(); add_class(temp_class); BEGIN(INITIAL);}
<C4>"{"                   { class_found = 1, inherited_found = 1; add_class(temp_class); BEGIN(INITIAL); }
<C4>[^,\n{ ]              { BEGIN(INITIAL);}

[~]                         { BEGIN(E1);}
<E1>{st}{wd}*             { BEGIN(E1); }
<E1>" "                   ;
<E1>[(]                   { BEGIN(E3);}
<E3>[^)]                  ;
<E3>[)]                   { BEGIN(E4);}
<E4>[ ]     { BEGIN(E4);}
<E4>[{:]                  {BEGIN(INITIAL);}
<E4>\n                    {increase_counts(); BEGIN(INITIAL);}
<E4>[^\n{:]               { BEGIN(INITIAL);} 


{st}{wd}*[ ]*[(]          {  memset(temp_class, 0, sizeof(temp_class)) ; sscanf(yytext, "%[A-Za-z0-9_]s", temp_class); BEGIN(D3) ; printf("%s-const-%d-%s-\n", yytext, yylineno, temp_class) ;}
<D1>" "                   { BEGIN(D1);}
<D1>[(]                   { BEGIN(D3);}
<D3>[^)]                  { BEGIN(D3);}
<D3>[)]                   { BEGIN(D4);}
<D4>[ \t]     { BEGIN(D4);}
<D4>[{:]                  {if (check_class(temp_class)){ constructor_found = 1; printf("######%s#######", temp_class);} /* printf("%s-was here\n", temp_class);*/ BEGIN(INITIAL);}
<D4>\n                    {if (check_class(temp_class)) {constructor_found = 1; printf("######%s#######", temp_class); }increase_counts(); /*printf("%s-was here\n", temp_class);*/ BEGIN(INITIAL);}
<D4>[^\n{:]               { BEGIN(INITIAL);} 

[^A-Za-z_]operator" "*{OP}" "*([^\{\;\n]*)[\n\{]     {printf("%s\n", yytext); operator_found = 1; if(yytext[yyleng-1]=='\n'){increase_counts();}}
.                         ;    
\n                        { increase_counts();}

{st}{wd}*[*]*[ ]+[*]*[A-Za-z0-9_,][A-Za-z0-9_,.\[\] ()]*[^\n;<>]*;  {printf("%s\n", yytext); objects(yytext);}      

%%
void add_class(char *temp_class){
    snprintf(classes[tempi], 200, "%s", temp_class);
    tempi++;
}

int check_class(char *class_name){
    int i;
    for(i=0;i<tempi;i++){
        printf("%s-%d-%s-%d\n", class_name, (int)strlen(class_name), classes[i], (int)strlen(classes[i]));
        if(strcmp(class_name, classes[i]) == 0){
            printf("%s-matched\n", class_name);
            return 1;
        }
    }
    return 0;
}

void objects(char *temp_char){
    char classname[250];
    memset(classname, 0, sizeof(classname));
    sscanf(temp_char, "%s", classname);
    int length = strlen(classname);
    while(classname[length-1] == '*') {
        classname[length-1] = '\0';
        length--;
    }
    if(check_class(classname)){
        object_found = 1;
        // printf("%s\n", classname);
    }
}
void print_classes(){
    int i;
    printf("Printing classes : \n");
    for(i=0;i<tempi;i++){
        printf("Class Name -- %s\n", classes[i]);
    }
}

void increase_counts(){
    number_of_classes += class_found;
    number_of_inherited_classes += inherited_found;
    number_of_constructors += constructor_found;
    number_of_overloading += operator_found;
    number_of_objects += object_found;
    class_found = inherited_found = constructor_found = operator_found = object_found = 0;
}

void comments_removal(FILE* source, FILE* destination){
    int singleline_comment_found = 0, multiline_comment_found = 0, length=0, i=0, string_started=0;
    char *read_line;
    read_line = malloc(1000);
    memset(read_line, 0, sizeof(read_line));
    size_t max_length = 1000;
    while(getline(&read_line, &max_length, source)!=-1){
        length = (int)strlen(read_line);
        if(read_line[length-1]=='\n'){
            length--;
        }
        // printf("%d\n", (int)length);
        singleline_comment_found = string_started = 0;
        for(i=0;i<length;i++){
            if(string_started && read_line[i] == '\"' && read_line[i-1] != '\\'){
                string_started = 0;
                read_line[i-1] = ' ';
                read_line[i] = ' ';
            }
            else if(multiline_comment_found == 1 && read_line[i] == '*' && read_line[i+1] == '/'){
                multiline_comment_found = 0;
                read_line[i] = ' ';
                read_line[i+1] = ' ';
                i++;
            }
            else if(string_started){
                read_line[i-1] = ' ';
            }
            else if(singleline_comment_found || multiline_comment_found){
                read_line[i] = ' ';
            }
            else if(read_line[i] == '\"' && read_line[i-1] != '\\'){
                string_started = 1;
            }
            else if(read_line[i] == '/' && read_line[i+1] == '/'){
                singleline_comment_found = 1;
                read_line[i] = ' ';
                read_line[i+1] = ' ';
                i++;
            }
            else if(read_line[i] == '/' && read_line[i+1] == '*'){
                multiline_comment_found = 1;
                read_line[i] = ' ';
                read_line[i+1] = ' ';
                i++;
            }
        }
        fprintf(destination, "%s", read_line);
        memset(read_line, 0, sizeof(read_line));
    }
}

void main(int argc, char **argv){
    argv++;
    argc--;
    if(argc == 0){
        printf("Supply file name\n");
        exit(0);
    }
    FILE* file_ptr = fopen(argv[0], "r");
    if(file_ptr == NULL){
        printf("File not found!\n");
        exit(0);
    }
    FILE* file_inter = fopen("intermediate.txt", "w");
    comments_removal(file_ptr, file_inter);   
    fclose(file_inter);
    fclose(file_ptr);
    file_ptr = fopen("intermediate.txt", "r");
    // yyin = fopen(argv[0], "r" );
    yyin = file_ptr;
    yylex();
    increase_counts();
    printf("\nNumber of Classes           : %d\n", number_of_classes);
    printf("Number of Inherited classes : %d\n", number_of_inherited_classes);
    print_classes();
    printf("Number of Constructors      : %d\n", number_of_constructors);
    printf("Number of Overloading       : %d\n", number_of_overloading);
    printf("Number of Objects           : %d\n", number_of_objects);
}
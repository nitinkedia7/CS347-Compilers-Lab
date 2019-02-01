#include "lex.h"
#include "linked-list.c"
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

char* yytext = ""; /* Lexeme (not '\0'
                      terminated)              */
int yyleng   = 0;  /* Lexeme length.           */
int yylineno = 0;  /* Input line number        */
char idname[32];
symbol* symbol_list = NULL;

int lex(void){
   static char input_buffer[1024];
   char        *current;
   
   current = yytext + yyleng; /* Skip current
                                 lexeme        */

   while(1){       /* Get the next one         */
      while(!*current ){
         /* Get new lines, skipping any leading
         * white space on the line,
         * until a nonblank line is found.
         */

         current = input_buffer;
         if(!fgets(input_buffer,1024,stdin)){
            *current = '\0' ;

            return EOI;
         }
         ++yylineno;
         while(isspace(*current))
            ++current;
      }
      for(; *current; ++current){
         /* Get the next token */
         yytext = current;
         yyleng = 1;
         // printf("%c\n", *yytext);
         switch( *current ){
            case ';':
               return SEMI;
            case '+':
               return PLUS;
            case '*':
               return TIMES;
            case '(':
               return LP;
            case ')':
               return RP;
            case '-':
               return MINUS;
            case '/':
               return DIVIDE;
            case '<':
               return LESS;
            case '>':
               return GREAT;
            case ':':
               current++;
               // printf("%c special", *current);
               if(*current != '='){
                  current--;
                  fprintf(stderr, "inserting missing '=' after ':'\n");
               }
               yyleng++;
               return ASSIGN;
            case '=':
               return EQUAL;
            case '\n':
            case '\t':
            case ' ' :
               break;
            default:
               
               if(!isalnum(*current)){
                  // printf("scanning 1 b\n");
                  fprintf(stderr, "Not alphanumeric <%c>\n", *current);
               }
               else{
                  // printf("scanning 2 b\n");
                  while(isalnum(*current)){
                     ++current;
                  }
                  yyleng = current - yytext;
                  char *tokens[] = {"if", "then", "while", "do", "begin", "end"};
                  int returnvals[] = {IF, THEN, WHILE, DO, BEGIN, END};
                  int lengths[] = {2,4,5,2,5,3};
                  int i=0;
                  // printf("location 1\n");                  
                  for(i=0; i<6; i++){
                     if(strncmp(yytext, tokens[i],yyleng)==0 && yyleng == lengths[i]){
                        // printf("keyword %d\n", i);
                        return returnvals[i];
                     }
                  }
                  // idname = (char *) malloc(yyleng+1);
                  // fprintf();
                  // char idname[32];
                  strncpy(idname, yytext, yyleng);
                  // if (isalpha(idname[0])) {
                  //    if (!present(symbol_list, idname)) {
                  //       fprintf(stderr, "%d: Found new variable %s\n", yylineno, idname);
                  //       symbol_list = push(symbol_list, idname, yyleng);
                  //    }
                  // }
                  // printf("location 3\n"); 
                  return NUM_OR_ID;
               }
            break;
         }
      }
   }
}


static int Lookahead = -1; /* Lookahead token  */

int match(int token){
   /* Return true if "token" matches the
      current lookahead symbol.                */

   if(Lookahead == -1)
      Lookahead = lex();

   return token == Lookahead;
}

void advance(void){
/* Advance the lookahead to the next
   input symbol.                               */

    Lookahead = lex();
}

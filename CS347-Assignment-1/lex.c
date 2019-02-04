#include "lex.h"
#include "list.c"
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

char* yytext = ""; /* Lexeme (not '\0'
                      terminated)              */
int yyleng   = 0;  /* Lexeme length.           */
int yylineno = 0;  /* Input line number        */
char idname[32];
int idlength = 0;
int spaces  = 0;
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
      spaces=0;
      for(; *current; ++current){
         /* Get the next token */
         yytext = current;
         yyleng = 1;
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
               if(*current != '='){
                  current--;
                  fprintf(stderr, "%d: Missing '=' after ':'\n", yylineno);
                  exit(1);
               }
               yyleng++;
               return ASSIGN;
            case '=':
               return EQUAL;
            case '\n':
            case '\t': 
            case ' ' : spaces++;
               break;
            default:               
               if(!isalnum(*current)){
                  fprintf(stderr, "Not alphanumeric <%c>\n", *current);
               }
               else{
                  while(isalnum(*current)){
                     ++current;
                  }
                  yyleng = current - yytext;
                  char *tokens[] = {"if", "then", "while", "do", "begin", "end"};
                  int returnvals[] = {IF, THEN, WHILE, DO, BEGIN, END};
                  int lengths[] = {2,4,5,2,5,3};
                  int i=0;
                  for(i=0; i<6; i++){
                     if(strncmp(yytext, tokens[i],yyleng)==0 && yyleng == lengths[i]){
                        return returnvals[i];
                     }
                  }
                  strncpy(idname, yytext, yyleng);   
                  idname[yyleng] = '\0';
                  idlength = yyleng;               
                  if(isalpha(idname[0])){
                     return ID;
                  }
                  // char* temp = yytext;
                  for(int i=0;i<yyleng;i++){
                     if(!isdigit(idname[i])){
                        fprintf(stderr, "%d: Fatal error not a number\n", yylineno);
                        exit(1);
                     }
                  }         
                  return NUM;
               }
            break;
         }
      }
   }
}


static int Lookahead = -1; /* Lookahead token  */
static int previousLookahead = -1;

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
   previousLookahead = Lookahead;
   Lookahead = lex();
}

void loopback(void){
   if(previousLookahead == -1) return;
   Lookahead = previousLookahead;
   yytext -= (yyleng+spaces);
}

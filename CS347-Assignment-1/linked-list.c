// #include "linked-list.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

typedef struct _symbol {
    char idname[32];
    int len;
    struct _symbol *ptr;

}symbol;

symbol *createNode() {
    return (symbol *) malloc(sizeof(symbol));
}


symbol *push(symbol *symbol_list, char idname[32], int len) {
    symbol *temp = createNode();
    strncpy(temp->idname, idname, len);
    temp->len = len;
    temp->ptr = symbol_list;
    return temp;
}

bool present(symbol *symbol_list, char idname[32], int len) {
    while (symbol_list != NULL) {
        if (strncmp(symbol_list->idname, idname, len) == 0)
            return true;
        symbol_list = symbol_list->ptr;
    }   
    return false;
}



// int main() {
//     symbol *symbol_list = NULL;
//     char *s = "nitin";
//     symbol_list = push(symbol_list, s, 5);
//     if (present(symbol_list, s)) {
//         printf("true");
//     }
//     char *s2 = "abhinav";
//     symbol_list = push(symbol_list, s2, 5);
//     if (present(symbol_list, s2)) {
//         printf("true");
//     }
//     char *s3 = "kedia";
//     if (present(symbol_list, s3)) {
//         printf("true");
//     }
//     else printf("false");
//     return 0;    
// }
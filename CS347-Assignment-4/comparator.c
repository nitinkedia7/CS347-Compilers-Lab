#include "comparator.h"

extern char list[100][100];
extern int vals;

void populate(char *tablename) {
    char table[100];
    memset(table, 0, 100);
    sprintf(table, "%s.csv", tablename);
    // printf("%s\n", table);    
    FILE* file = fopen(table,"r");
    char str[1000];
    fgets(str, 1000, file);
    char *token;
    const char s[2] = ",";
    token = strtok(str, s);
    int j = 0;
    while( token != NULL ) {
        sprintf(list[j], "%s", token);
        token = strtok(NULL, s);
        j++;
    }    
    vals = j;
    fclose(file);
    return;
}
 
int getColIndex(char *col) {
    int i = 0;
    for (i = 0; i < vals; i++) {
        if (strcmp(list[i], col) == 0) return i;
    }
    return -1;
}

char *retval(char *str, int colIndex) {
    char *token;
    const char s[2] = ",";
    token = strtok(str, s);
    int j = 0;
    while( token != NULL ) {
            if (colIndex == j) return token;
            token = strtok(NULL, s);
            j++;         
        }
}
 
int comparator(struct and_entry unit, char *str) {
    if (unit.int1_fnd) {

    }
    else { // col op INT
        int colIndex = getColIndex(unit.col1);
        unit.val1 = atoi(retval(str, colIndex));
        // printf("salary val %d\n", unit.val1);
        if (unit.operation == 1) {
            return unit.val1 < unit.val2;
        }
        else if (unit.operation == 2) {
            return unit.val1 > unit.val2;
        }
        else if (unit.operation == 3) {
            return unit.val1 <= unit.val2;
        }
        else if (unit.operation == 4) {
            return unit.val1 >= unit.val2;
        }
        else if (unit.operation == 5) {
            return unit.val1 == unit.val2;
        }
        else if (unit.operation == 6) {
            return unit.val1 != unit.val2;
        }
    }
    return -1;    
}

int compute_condition(struct or_list condition, char *str){
    and_list* temp = condition.head;
    int result = 0;
    
    while(temp!=NULL){
        and_entry* temp2 = temp->head;
        int val = 1;
        while(temp2!=NULL){
            char str2[1000];
            memset(str2, 0, 1000);
            sprintf(str2, "%s", str);
            int ret = comparator(*temp2, str2);
            val = val & ret;
            temp2 = temp2->next_ptr;
        }
        if(val==1){
            return 1;
        }
        result = result | val;
        temp = temp->next_ptr;
    }
    return result;
}
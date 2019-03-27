#include "comparator.h"

int getColIndex(char *table, char *column) { // table already .csv appended
    char tablecopy[200];
    memset(tablecopy,0,200);
    sprintf(tablecopy,"%s.csv",table);
    FILE* file = fopen(tablecopy, "r");
    char str[1000];
    char *token;
    const char s[2] = ",";
    int j = 0;
    fgets(str, 1000, file);
    sscanf(str, "%[^\n]", str);
    token = strtok(str, s);
    while( token != NULL ) {
        // printf("column - %s %d %d\n", token, strlen(token), strlen(column));
        if (strcmp(token, column) == 0) {
            fclose(file);
            return j;
        }
        j++;
        token = strtok(NULL, s);
    }    
    fclose(file);
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

char *getType(char *table, int colIndex){
    char tablecopy[200];
    memset(tablecopy,0,200);
    sprintf(tablecopy,"%s.csv",table);
    FILE* file = fopen(tablecopy, "r");
    char str[1000];
    char *token;
    const char s[2] = ",";
    int j = 0;
    fgets(str, 1000, file);
    fgets(str, 1000, file);
    sscanf(str, "%[^\n]", str);
    token = strtok(str, s);
    char data_type[10];
    memset(data_type, 0, 10);
    while( token != NULL ) {
        if (colIndex == j) {
            fclose(file);
            return token;
        }
        token = strtok(NULL, s);
        j++;  
    }    
    fclose(file);
    return NULL;
}

int compareByOp(int val1, int val2, int op) {
    if (op == 1) {
        return val1 < val2;
    }
    else if (op == 2) {
        return val1 > val2;
    }
    else if (op == 3) {
        return val1 <= val2;
    }
    else if (op == 4) {
        return val1 >= val2;
    }
    else if (op == 5) {
        return val1 == val2;
    }
    else if (op == 6) {
        return val1 != val2;
    } 
    return 1;   
}

int compareStringByOp(char *str1, char *str2, int op){
    // printf("--%s--%s--", str1, str2);
    int returnType = strcmp(str1, str2);
    switch (op)
    {
        case 1: if(returnType < 0) return 1;
            break;
        case 2: if(returnType > 0) return 1;
            break;
        case 3: if(returnType <= 0) return 1;
            break;
        case 4: if(returnType >= 0) return 1;
            break;
        case 5: if(returnType == 0) return 1; 
            break;
        case 6: if(returnType != 0) return 1;
            break;
        default:
            break;
    }
    return 0;
}
 
int select_comparator(struct and_entry unit, char *str1, char* table_name) {
    if (unit.int1_fnd) {
        int colIndex = getColIndex(table_name, unit.col2);
        if (colIndex == -1) {
            printf("Column not found\n");
            return -1;
        }
        char *data_type = getType(table_name, colIndex);
        if(strcmp(data_type,"int") != 0){
            printf("Data Type mismatch\n");
            return -1;
        }
        unit.val2 = atoi(retval(str1, colIndex));
        return compareByOp(unit.val1, unit.val2, unit.operation);
    }
    else if (unit.int2_fnd) { // col op INT
        // printf("I'm %s %s here\n", table_name, unit.col1);
        int colIndex = getColIndex(table_name, unit.col1);
        if (colIndex == -1) {
            printf("Column not found\n");
            return -1;
        }
        char *data_type = getType(table_name, colIndex);
        if(strcmp(data_type,"int") != 0){
            printf("Data Type mismatch\n");
            return -1;
        }
        unit.val1 = atoi(retval(str1, colIndex));
        return compareByOp(unit.val1, unit.val2, unit.operation);
    }
    else if(unit.str1 == NULL){
        int colIndex = getColIndex(table_name, unit.col1);
        if (colIndex == -1) {
            printf("Column not found\n");
            return -1;
        }
        char *data_type = getType(table_name, colIndex);
        if(strcmp(data_type,"str") != 0){
            printf("Data Type mismatch\n");
            return -1;
        }
        unit.str1 = retval(str1, colIndex);
        return compareStringByOp(unit.str1, unit.str2, unit.operation);
    }
    else if(unit.str2 == NULL){
        int colIndex = getColIndex(table_name, unit.col2);
        if (colIndex == -1) {
            printf("Column not found\n");
            return -1;
        }
        char *data_type = getType(table_name, colIndex);
        if(strcmp(data_type,"str") != 0){
            printf("Data Type mismatch\n");
            return -1;
        }
        unit.str2 = retval(str1, colIndex);
        return compareStringByOp(unit.str1, unit.str2, unit.operation);
    }
    else {
        int colIndex1 = getColIndex(unit.table1, unit.col1);
        int colIndex2 = getColIndex(unit.table2, unit.col2);
        if (colIndex1 == -1) {
            printf("Column %s not found in table %s\n", unit.col1, unit.table1);
            return -1;
        }
        if (colIndex2 == -1) {
            printf("Column %s not found in table %s\n", unit.col2, unit.table2);
            return -1;
        }
        unit.val1 = atoi(retval(str1, colIndex1));
        unit.val2 = atoi(retval(str1, colIndex2));
        return compareByOp(unit.val1, unit.val2, unit.operation);
    }
    return -1;    
}

int select_compute_condition(struct or_list condition, char *str, char* table_name){
    and_list* temp = condition.head;
    int result = 0;
    
    while(temp!=NULL){
        and_entry* temp2 = temp->head;
        int val = 1;
        while(temp2!=NULL){
            char str_copy[1000];
            memset(str_copy, 0, 1000);
            sprintf(str_copy, "%s", str);
            int ret = select_comparator(*temp2, str_copy, table_name);
            if(ret == -1){
                return -1;
            }
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

int equi_comparator(struct and_entry unit, char *str1, char *str2, char *table1, char *table2) {
    if (unit.int2_fnd) { // col op INT
        int colIndex = getColIndex(unit.table1, unit.col1);
        if (colIndex == -1) {
            printf("Column not found\n");
            return -1;
        }
        unit.val1 = atoi(retval(str1, colIndex));
        return compareByOp(unit.val1, unit.val2, unit.operation);
    }
    else { // col op col
        int colIndex1 = getColIndex(unit.table1, unit.col1);
        int colIndex2 = getColIndex(unit.table2, unit.col2);
        if (colIndex1 == -1) {
            printf("Column %s not found in table %s\n", unit.col1, unit.table1);
            return -1;
        }
        if (colIndex2 == -1) {
            printf("Column %s not found in table %s\n", unit.col2, unit.table2);
            return -1;
        }
        if (strcmp(unit.table1, table1) == 0)
            unit.val1 = atoi(retval(str1, colIndex1));
        else 
            unit.val1 = atoi(retval(str2, colIndex1));

        if (strcmp(unit.table2, table2) == 0)
            unit.val2 = atoi(retval(str2, colIndex2));
        else 
            unit.val2 = atoi(retval(str1, colIndex2));

        return compareByOp(unit.val1, unit.val2, unit.operation);
    }
    return -1;    
}

int equi_compute_condition(struct or_list condition, char *str1, char *str2, char *table1, char *table2){
    and_list* temp = condition.head;
    int result = 0;
    
    while(temp!=NULL){
        and_entry* temp2 = temp->head;
        int val = 1;
        while(temp2!=NULL){
            char str_copy1[1000];
            memset(str_copy1, 0, 1000);
            sprintf(str_copy1, "%s", str1);
            char str_copy2[1000];
            memset(str_copy2, 0, 1000);
            sprintf(str_copy2, "%s", str2);
            int ret = equi_comparator(*temp2, str_copy1, str_copy2, table1, table2);
            if(ret == -1){
                return -1;
            }
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

int associateTable(char *table1, char *table2, struct or_list *conditions) {
    and_list *temp = conditions->head;
    while(temp != NULL) {
        and_entry* temp2 = temp->head;
        while (temp2 != NULL) {
            if (temp2->int2_fnd) { // col op INT
                if (temp2->table1 == NULL) {
                    if (getColIndex(table1, temp2->col1) != -1) temp2->table1 = table1;
                    else if (getColIndex(table2, temp2->col1) != -1) temp2->table1 = table2;
                    else {
                        fprintf(stderr, "Column %s does not belong to %s or %s\n", temp2->col1, table1, table2);
                        return -1;
                    }
                }
                else {
                    if (strcmp(temp2->table1, table1) != 0 && strcmp(temp2->table1, table2) != 0) {
                        fprintf(stderr, "Column %s does not belong to %s or %s\n", temp2->col1, table1, table2);
                        return -1;
                    }
                    else if (getColIndex(temp2->table1, temp2->col1) == -1) {
                        fprintf(stderr, "Column %s does not belong to %s\n", temp2->col1, temp2->table1);
                        return -1;
                    }
                }
                char d1[50];
                sprintf(d1, "%s", getType(temp2->table1, getColIndex(temp2->table1, temp2->col1)));
                if (strcmp(d1, "int") != 0) {
                    fprintf(stderr, "%s is %s not INT\n", temp2->col1, d1);
                    return -1;
                }
            }
            else { // col op col
                if (temp2->table1 == NULL) {
                    if (getColIndex(table1, temp2->col1) != -1) temp2->table1 = table1;
                    else if (getColIndex(table2, temp2->col1) != -1) temp2->table1 = table2;
                    else {
                        fprintf(stderr, "Column %s does not belong to %s or %s\n", temp2->col1, table1, table2);
                        return -1;
                    }
                }
                else {
                    if (strcmp(temp2->table1, table1) != 0 && strcmp(temp2->table1, table2) != 0) {
                        fprintf(stderr, "Column %s does not belong to %s or %s\n", temp2->col1, table1, table2);
                        return -1;
                    }
                    else if (getColIndex(temp2->table1, temp2->col1) == -1) {
                        fprintf(stderr, "Column %s does not belong to %s\n", temp2->col1, temp2->table1);
                        return -1;
                    }
                }
                if (temp2->table2 == NULL) {
                    if (getColIndex(table1, temp2->col2) != -1) temp2->table2 = table1;
                    else if (getColIndex(table2, temp2->col2) != -1) temp2->table2 = table2;
                    else {
                        fprintf(stderr, "Column %s does not belong to %s or %s\n", temp2->col2, table1, table2);
                        return -1;
                    }
                }
                else {
                    if (strcmp(temp2->table2, table1)!=0 && strcmp(temp2->table2, table2) != 0) {
                        fprintf(stderr, "Column %s does not belong to %s or %s\n", temp2->col2, table1, table2);
                        return -1;
                    }
                    else if (getColIndex(temp2->table2, temp2->col2) == -1) {
                        fprintf(stderr, "Column %s does not belong to %s\n", temp2->col2, temp2->table2);
                        return -1;
                    }
                }
                char d1[50], d2[50];
                sprintf(d1, "%s", getType(temp2->table1, getColIndex(temp2->table1, temp2->col1)));
                sprintf(d2, "%s", getType(temp2->table2, getColIndex(temp2->table2, temp2->col2)));
                if (strcmp(d1, d2) != 0) {
                    fprintf(stderr, "Different data type %s %s\n", temp2->col1, temp2->col2);
                    return -1;
                }

            }
            temp2 = temp2->next_ptr;
        }
        temp = temp->next_ptr;
    }
    return 1;
}

void printEquiJoin(char *table1, char *table2, struct or_list *conditions) {
    char table1Name[200];
    memset(table1Name, 0, 200);
    sprintf(table1Name, "%s.csv", table1);
    char table2Name[200];
    memset(table2Name, 0, 200);
    sprintf(table2Name, "%s.csv", table2);

    FILE* file1 = fopen(table1Name,"r");
    FILE* file2 = fopen(table2Name,"r");

    char str1[1000];
    fgets(str1, 1000, file1);
    sscanf(str1, "%[^\n]s", str1);
    char *token1;
    const char *s = ",";
    token1 = strtok(str1, s);
    while (token1 != NULL) {
        printf( "%s.%s, ", table1, token1);
        token1 = strtok(NULL, s);        
    }
    char str2[1000];
    fgets(str2, 1000, file2);
    char *token2;
    token2 = strtok(str2, s);
    while (token2 != NULL) {
        printf( "%s.%s", table2, token2);
        token2 = strtok(NULL, s);
        if (token2 != NULL) printf(", ");        
    }
    fgets(str1, 1000, file1);
    fgets(str2, 1000, file2);
    // printf("%s", str1);
    // printf(",%s", str2);
    fclose(file2);
    while(fgets(str1, 1000, file1)) {
        sscanf(str1, "%[^\n]s", str1);

        file2 = fopen(table2Name,"r");
        fgets(str2, 1000, file2);
        fgets(str2, 1000, file2);
        while (fgets(str2, 1000, file2)) {
            if (equi_compute_condition(*conditions, str1, str2, table1, table2)) {
                printf("%s", str1);
                printf(",%s", str2);
            };
        } 
        fclose(file2);     
    }
    fclose(file1);
}

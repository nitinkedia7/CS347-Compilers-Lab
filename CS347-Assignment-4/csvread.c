#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int checkTableName(char* tablename){
    FILE* file = fopen("tablenames.txt","r");
    char str[1000];
    const char s[2] = ",";
    fgets(str, 1000, file);
    char *token;
    sscanf(str, "%[^\n]s", str);
    token = strtok(str, s);
    char table[200];
    memset(table, 0, 200);
    sprintf(table, "%s.csv", tablename);
    // strcat(tablename,".csv");
    while( token != NULL ) {
        // printf( "%s ", token );
        if(strcmp(token,table)==0){
            return 1;
        }
        token = strtok(NULL, s);         
    }
    fclose(file);
    return 0;
}

void printColumns(char list[100][100], int vals, char* table){
    char tableName[100];
    memset(tableName, 0, 100);
    sprintf(tableName, "%s.csv", table);

    FILE* file = fopen(tableName,"r");
    char str[1000];
    char str2[1000];
    int arr[100];
    int count=0;
    memset(arr,0,100*sizeof(arr[0]));
    const char s[2] = ",";
    fgets(str, 1000, file);
    sscanf(str, "%[^\n]s", str);
    char *token;
    strcpy(str2,str);
    token = strtok(str, s);
    int j=0;
    while( token != NULL ) {
        // printf( "%s ", token );
        for(int i=0;i<vals;i++){
            if(strcmp(list[i],token)==0){
                count++;
                arr[j]++;
            }
        }
        token = strtok(NULL, s);       
        j++;  
    }
    // printf("vals %d count %d\n", vals, count);
    if(count != vals){
        printf("Error: Column with requested name does not exist\n");
        return;
    }
    token = strtok(str2, s);
    j=0;
    while( token != NULL ) {
        if(arr[j]){
            printf( "%s ", token );
        }
        token = strtok(NULL, s);       
        j++;  
    }
    printf("\n");
    fgets(str, 1000, file);
    while(fgets(str, 1000, file)){
        int j=0;
        char *token;
        sscanf(str, "%[^\n]s", str);
        token = strtok(str, s);
        while( token != NULL ) {
            if(arr[j]){
                printf( "%s ", token );
            }
            token = strtok(NULL, s);
            j++;
        }
        printf("\n");
    }
    fclose(file);
}

void printCartesianProducts(char *table1, char *table2) {
    char table1Name[200];
    memset(table1Name, 0, 200);
    sprintf(table1Name, "%s.csv", table1);
    char table2Name[200];
    memset(table2Name, 0, 200);
    sprintf(table2Name, "%s.csv", table2);
    int a = checkTableName(table1);
    int b = checkTableName(table2);
    if (a == 0) {
        fprintf(stderr, "Table %s not present\n", table1Name);
        return;
    }
    else if (b == 0) {
        fprintf(stderr, "Table %s not present\n", table2Name);
        return;
    }
    // both files present
    FILE* file1 = fopen(table1Name,"r");
    FILE* file2 = fopen(table2Name,"r");

    char str1[1000];
    fgets(str1, 1000, file1);
    sscanf(str1, "%[^\n]s", str1);
    char *token1;
    const char *s = ",";
    token1 = strtok(str1, s);
    while( token1 != NULL ) {
        printf( "%s.%s, ", table1, token1);
        token1 = strtok(NULL, s);        
    }
    char str2[1000];
    fgets(str2, 1000, file2);
    char *token2;
    token2 = strtok(str2, s);
    while( token2 != NULL ) {
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
            printf("%s", str1);
            printf(",%s", str2);
        } 
        fclose(file2);     
    }
    fclose(file1);
}

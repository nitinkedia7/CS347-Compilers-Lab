#include <stdio.h>
#include <stdlib.h>
#include "linkedList.h"

typedef enum {INTEGER, FLOATING} eletype;
typedef enum {SIMPLE, ARRAY} type;
typedef enum {PARAMAETER, VARIABLE} tag;

typedef struct {
    char* name;
    int type;
    int eletype;
    int tag;
    int scope;
    linkedList* dimlist; // cube[x][y][z] => (x -> y -> z)     
} typerec; 

struct funcEntry{
    char* name;
    eletype rettype;
    // typerec* parameter_ptr;
    // typerec* variable_ptr;
    int numOfParam;
    linkedList* variable_ptr;
    linkedList* parameter_ptr;
}; 

struct funcName{
    char* name;
    linkedList* parameter_ptr;
};

typerec* createTyperec() {
    return (typerec*)malloc(sizeof(typerec));
}

// vector<func_name_table> funcList;
// vector<typerec> symTab;

// void patchDataType(int type, vector<typerec> &varList, int scope){
//     for(typerec &it:varList){
//         it.scope = scope;
//         it.type = type;
//     }
// }

// void insertSymTab(vector<typerec> &varList){
//     for(typerec it:varList){

//     }
// }/ }
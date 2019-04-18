#pragma once
#include <bits/stdc++.h>
using namespace std;

enum eletype {INTEGER, FLOATING, NULLVOID};
enum type {SIMPLE, ARRAY};
enum tag{PARAMAETER, VARIABLE};

struct typeRecord {
    string name;
    int type;
    int eleType;
    int tag;
    int scope;
    vector<int> dimlist; // cube[x][y][z] => (x -> y -> z)     
}; 

struct funcEntry {
    string name;
    eletype returnType;
    int numOfParam;
    vector <typeRecord*> variableList;
    vector <typeRecord*> parameterList;
}; 

void patchDataType(int type, vector<typeRecord*> &typeRecordList, int scope);
void insertSymTab(vector<typeRecord*> &typeRecordList, funcEntry* activeFuncPtr);
void insertParamTab(vector<typeRecord*> &typeRecordList, funcEntry* activeFuncPtr);
void deleteVarList(funcEntry* activeFuncPtr, int scope);
void searchFunc(funcEntry* activeFuncPtr,vector<funcEntry*> &funcEntryRecord,int &found);
void searchVariable(string name, funcEntry* activeFuncPtr, int &found, typeRecord *&vn);
void searchParam(string name, vector<typeRecord*> &parameterList, int &found);
void addFunction(funcEntry* activeFuncPtr, vector<funcEntry*> &funcEntryRecord);
void printList(vector<funcEntry*> &funcEntryRecord);
void printFunction(funcEntry* &activeFuncPtr);

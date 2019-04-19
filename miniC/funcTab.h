#pragma once
#include <bits/stdc++.h>
using namespace std;

enum eletype {INTEGER, FLOATING, NULLVOID, BOOLEAN, ERRORTYPE};
enum varType {SIMPLE, ARRAY};
enum Tag{PARAMAETER, VARIABLE};

class resgisterSet{
private:
    vector<int> tempRegister;
public:
    resgisterSet(){
        tempRegister.clear();
        for(int i=0; i<10; i++){
            tempRegister.push_back(i);
        }
    }
    string getRegister();
    void freeRegister(string s);
}

struct expression{
    eletype type;
    string* variableName;
};

struct stmt {
    vector<int> *nextList;
    vector<int> *continueList;
    vector<int> *breakList;
};

struct whileexp {
    int begin;
    vector<int> *falseList;
}

struct typeRecord {
    string name;
    varType type;
    eletype eleType;
    Tag tag;
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

void patchDataType(eletype type, vector<typeRecord*> &typeRecordList, int scope);
void insertSymTab(vector<typeRecord*> &typeRecordList, funcEntry* activeFuncPtr);
void insertParamTab(vector<typeRecord*> &typeRecordList, funcEntry* activeFuncPtr);
void deleteVarList(funcEntry* activeFuncPtr, int scope);
void searchFunc(funcEntry* activeFuncPtr,vector<funcEntry*> &funcEntryRecord,int &found);
void compareFunc(funcEntry* &activeFuncPtr,vector<funcEntry*> &funcEntryRecord,int &found);
void searchVariable(string name, funcEntry* activeFuncPtr, int &found, typeRecord *&vn);
void searchParam(string name, vector<typeRecord*> &parameterList, int &found, typeRecord *&pn);
void addFunction(funcEntry* activeFuncPtr, vector<funcEntry*> &funcEntryRecord);
void printList(vector<funcEntry*> &funcEntryRecord);
void printFunction(funcEntry* &activeFuncPtr);
bool arithmeticCompatible(eletype type1, eletype type2);
eletype compareTypes(eletype type1, eletype type2);

int gen(vector<string> &, string ,int &);
void backpatch(vector<int> *, int, vector<string> &);
//vector<int> *, funcIns, string, 
void merge(vector<int> *, vector<int> *);
#include <bits/stdc++.h>
using namespace std;

enum eletype {INTEGER, FLOATING, NULLVOID, BOOLEAN, ERRORTYPE};
enum varType {SIMPLE, ARRAY};
enum Tag{PARAMAETER, VARIABLE};

struct typeRecord {
    string name;
    eletype eleType;
    int scope;
    int varOffset;
}; 

struct funcEntry {
    string name;
    eletype returnType;
    int numOfParam;
    int functionOffset;
    vector <typeRecord*> variableList;
    vector <typeRecord*> parameterList;
}; 

string eletypeMapper(eletype a);
void readSymbolTable();
int eletypeIntMapper(eletype a);
int getOffset(string functionName, string variableName, int internalOffset);
void printVector(vector<funcEntry> &functionList);
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
int eletypeIntMapper(eletype a);
eletype getEleType(string x);

void readSymbolTable(vector<funcEntry> &functionList);
int getOffset(vector<funcEntry> &functionList, string functionName, string variableName, int internalOffset);
int getFunctionOffset(vector<funcEntry> &functionList, string functionName);
void printVector(vector<funcEntry> &functionList);
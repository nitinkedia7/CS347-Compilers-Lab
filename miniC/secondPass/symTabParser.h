#include <iostream>
#include <vector>
#include <stack>
#include <stdio.h>
#include <fstream>
using namespace std;

enum eletype {INTEGER, FLOATING, NULLVOID, BOOLEAN, ERRORTYPE};
enum varType {SIMPLE, ARRAY};
enum Tag {PARAMAETER, VARIABLE};

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

int getParamOffset(vector<funcEntry> &functionList, string functionName);
void readSymbolTable(vector<funcEntry> &functionList, vector<typeRecord> &globalVariables);
int getOffset(vector<funcEntry> &functionList, vector<typeRecord> &globalVariables, string functionName, string variableName, int internalOffset, bool &isGlobal);
int getFunctionOffset(vector<funcEntry> &functionList, string functionName);
void printVector(vector<funcEntry> &functionList);
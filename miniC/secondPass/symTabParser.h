#include <iostream>
#include <vector>
#include <stack>
#include <stdio.h>
#include <fstream>
#include <utility>
using namespace std;

#define RST   "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"

#define FRED(x) KRED x RST
#define FGRN(x) KGRN x RST
#define FYEL(x) KYEL x RST
#define FBLU(x) KBLU x RST
#define FMAG(x) KMAG x RST
#define FCYN(x) KCYN x RST
#define FWHT(x) KWHT x RST

#define BOLD(x) "\x1B[1m" x RST
#define UNDL(x) "\x1B[4m" x RST

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
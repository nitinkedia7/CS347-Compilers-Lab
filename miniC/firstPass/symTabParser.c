#include "symTabParser.h"

string eletypeMapper(eletype a){
    switch(a){
        case INTEGER   : return "int";
        case FLOATING  : return "float";
        case NULLVOID  : return "void";
        case BOOLEAN   : return "bool";
        case ERRORTYPE : return "error";
    }
}

int eletypeIntMapper(eletype a){
    switch(a){
        case INTEGER   : return 0;
        case FLOATING  : return 1;
        case NULLVOID  : return 2;
        case BOOLEAN   : return 3;
        case ERRORTYPE : return 4;
        default : return 999;
    }
}

int getOffset(string functionName, string variableName, int internalOffset){
    for(auto it : functionList){
        if(it.name == functionName){
            for (auto it2 : it.variableList){
                if(it2->name == variableName){
                    int offset = it.functionOffset - 4*( internalOffset + 1) - it2->varOffset;
                    return offset; 
                }
            }
            for (auto it2: it.parameterList){
                if(it2->name == variableName){
                    int offset = it.functionOffset + 4*(it.numOfParam - internalOffset - 1) - it2->varOffset;
                    return offset; 
                }
            }
        }
    }   
    cout << "Variable " << variableName << " not found in " << functionName << endl;
    return -1;
}

void printVector(vector<funcEntry> &functionList){
    for(auto funcRecord : functionList){
        cout << "$$" << endl;
        cout << "_" << funcRecord.name << " " << eletypeMapper(funcRecord.returnType) << " ";
        cout << funcRecord.numOfParam << " " << funcRecord.functionOffset << endl;
        cout << "$1" << endl;
        for(auto varRecord : funcRecord.parameterList){
            cout <<varRecord->name << " " << eletypeIntMapper(varRecord->eleType) << " " ;
            cout << varRecord->scope << " " << varRecord->varOffset << endl;
        }
        cout << "$2 " << funcRecord.variableList.size() << endl;
        for(auto varRecord : funcRecord.variableList){
            cout <<varRecord->name << " " << eletypeIntMapper(varRecord->eleType) << " " ;
            cout << varRecord->scope << " " << varRecord->varOffset << endl;
        }
    }
}

void readSymbolTable(){
    ifstream myfile;
    myfile.open ("symtab.txt");
    string a;
    while(myfile >> a){
        if(a=="$$"){
            // cout<<"pp "<<a<<endl;
            funcEntry p;
            myfile >> p.name;
            string x;
            myfile >> x;
            p.returnType = getEleType(x);
            myfile >> p.numOfParam;
            myfile >> p.functionOffset;
            myfile >> x;
            (p.parameterList).resize(p.numOfParam);
            for(int i=0;i<p.numOfParam;i++){
                p.parameterList[i] = new typeRecord;
                myfile >> (p.parameterList[i])->name;
                string t;
                myfile >> t;
                (p.parameterList[i])->eleType= getEleType(t);
                myfile >> (p.parameterList[i])->scope;
                myfile >> (p.parameterList[i])->varOffset; 
            }
            myfile >> x;
            int z;
            myfile >> z;
            p.variableList.resize(z);
            for(int i=0;i<z;i++){
                p.variableList[i] = new typeRecord;
                myfile >> (p.variableList[i])->name;
                string t;
                myfile >> t;
                (p.variableList[i])->eleType= getEleType(t);
                myfile >> (p.variableList[i])->scope;
                myfile >> (p.variableList[i])->varOffset;
            }
            functionList.push_back(p);
        }
    }
}
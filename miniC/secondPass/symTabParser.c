#include "symTabParser.h"

string eletypeMapper(eletype a){
    switch(a){
        case INTEGER   : return "int";
        case FLOATING  : return "float";
        case NULLVOID  : return "void";
        case BOOLEAN   : return "bool";
        case ERRORTYPE : return "error";
        default: return "default";
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
eletype getEleType(string x){
    if(x=="0")
        return INTEGER;
    if(x=="1")
        return FLOATING;
    if(x=="2")
        return NULLVOID;
    return ERRORTYPE;
}
int getOffset(vector<funcEntry> &functionList, vector<typeRecord> &globalVariables, string functionName, string variableName, int internalOffset, bool &isGlobal){
    isGlobal = false;
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
    for(auto it : globalVariables){
        if(it.name == variableName){
            isGlobal = true;
            return 0;
        }
    }
    cout << "Variable " << variableName << " not found in " << functionName << endl;
    return -1;
}

int getFunctionOffset(vector<funcEntry> &functionList,string functionName){
    for(auto it : functionList){
        if(it.name == functionName){
            return it.functionOffset;
        }
    }
    return -1;
}

void printVector(vector<funcEntry> &functionprintList){
    for(auto funcRecord : functionprintList){
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

void readSymbolTable(vector<funcEntry> &functionList, vector<typeRecord> &globalVariables){
    ifstream myfile;
    myfile.open ("../firstPass/output/symtab.txt");
    string a;
    bool isGlobal = false;
    while(myfile >> a){
        if(a=="$$"){
            // cout<<"pp "<<a<<endl;
            funcEntry p;
            myfile >> p.name;
            if(p.name == "GLOBAL"){
                isGlobal = true;
            }
            else{
                isGlobal = false;
            }
            string x;
            myfile >> x;
            p.returnType = getEleType(x);
            myfile >> p.numOfParam;
            myfile >> p.functionOffset;
            myfile >> x;
            if(isGlobal){
                // globalVariables.insert(globalVariables.end(), p.parameterList.begin(), p.parameterList.end());
                for(int i=0;i<p.numOfParam;i++){
                    typeRecord newType;
                    string eleType;
                    myfile >> newType.name;
                    myfile >> eleType;
                    newType.eleType = getEleType(eleType);
                    
                    myfile >> newType.scope;
                    myfile >> newType.varOffset;
                    globalVariables.push_back(newType);
                }
                for(auto it : globalVariables){
                    cout << "Global Variable Name : "<< it.name << endl;
                }
            }
            else{
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
            if(!isGlobal){
                functionList.push_back(p);
            }
        }
    }
}

int getParamOffset(vector<funcEntry> &functionList, string functionName){
    for(auto it : functionList){
        if(it.name == functionName){
            return 4*(it.numOfParam);
        }
    } 
    return 0;
}


#include "funcTab.h"

void patchDataType(eletype eleType, vector<typeRecord*> &typeRecordList, int scope){
    for (typeRecord* &it:typeRecordList) {
        it->scope = scope;
        it->eleType = eleType;
    }
    return;
}

void insertSymTab(vector<typeRecord*> &typeRecordList, funcEntry* activeFuncPtr) {
    activeFuncPtr->variableList.insert(activeFuncPtr->variableList.end(), typeRecordList.begin(), typeRecordList.end());
    return;
}

void insertParamTab(vector<typeRecord*> &typeRecordList, funcEntry* activeFuncPtr) {
    activeFuncPtr->parameterList.insert(activeFuncPtr->parameterList.end(), typeRecordList.begin(), typeRecordList.end());
    activeFuncPtr->numOfParam+=typeRecordList.size();
}

void deleteVarList(funcEntry* activeFuncPtr, int scope){
    vector <typeRecord*> variableList;
    for(auto it:activeFuncPtr->variableList){
        if(it->scope==scope){
            it->isValid = false;
        }
        // if(it->scope!=scope){
        //     variableList.push_back(it);
        // } else {
        //     free(it);
        // }
    }
    // activeFuncPtr->variableList.swap(variableList);
}

void searchVariable(string name, funcEntry* activeFuncPtr, int &found, typeRecord *&vn, int scope) {
    vector<typeRecord*>::reverse_iterator i;
    bool flag=false;
    for (i = activeFuncPtr->variableList.rbegin(); i != activeFuncPtr->variableList.rend(); ++i) {
        if (name == (*i)->name && (*i)->scope==scope) {
            // found = 1;
            vn = *i;
            flag=true;
            // return;
        }
    }
    if(flag){
        found=1;
        return;
    }
    found = 0;
    vn = NULL;
    return;
}

void searchCallVariable(string name, funcEntry* activeFuncPtr, int &found, typeRecord *&vn) {
    vector<typeRecord*>::reverse_iterator i;
    bool flag=false;
    int sc=0;
    for (i = activeFuncPtr->variableList.rbegin(); i != activeFuncPtr->variableList.rend(); ++i) {
        if (name == (*i)->name && (*i)->isValid) {
            // found = 1;
            if(sc<(*i)->scope){
                sc=(*i)->scope;
                vn = *i;
            }
            flag=true;
            // return;
        }
    }
    if(flag){
        found=1;
        return;
    }
    found = 0;
    vn = NULL;
    return;
}

// void insertVariable(string)

void searchParam(string name, vector<typeRecord*> &parameterList, int &found, typeRecord *&pn) {
    vector<typeRecord*> :: reverse_iterator i;
    for (i = parameterList.rbegin(); i != parameterList.rend(); ++i){
        if(name == (*i)->name){
            found = 1;
            pn = (*i);
            return;
        }
    }
    found = 0;
    pn = NULL;
    return;
}

void searchFunc(funcEntry* activeFuncPtr, vector<funcEntry*> &funcEntryRecord, int &found){
    for(auto it:funcEntryRecord){
        if(it->name == activeFuncPtr->name && it->returnType == activeFuncPtr->returnType && it->numOfParam == activeFuncPtr->numOfParam){
            int flag=1;
            for(int i=0;i<it->numOfParam;i++){
                if((it->parameterList[i])->eleType != activeFuncPtr->parameterList[i]->eleType){
                    found=-1;
                    flag=0;
                    break;
                }
            }
            if(flag == 1){
                found=1;
                return;
            } 
        }
    }
    if (found != -1) found=0;
    return;    
}

void compareFunc(funcEntry* &activeFuncPtr, vector<funcEntry*> &funcEntryRecord, int &found){
    for(auto it:funcEntryRecord){
        if(it->name == activeFuncPtr->name  && it->numOfParam == activeFuncPtr->numOfParam){
            int flag=1;
            for(int i=0;i<it->numOfParam;i++){
                if((it->parameterList[i])->eleType != activeFuncPtr->parameterList[i]->eleType){
                    found=-1;
                    flag=0;
                    break;
                }
            }
            if(flag == 1){
                found=1;
                activeFuncPtr->returnType = it->returnType;
                return;
            } 
        }
    }
    if (found != -1) found=0;
    return;    
}

void printList(vector<funcEntry*> &funcEntryRecord){
    
    for(auto it:funcEntryRecord){
        cout<<"Function Entry: "<<(it->name)<<endl;
        cout<<"Printing Parameter List"<<endl;
        for(auto it2:it->parameterList){
            cout<<(it2->name)<<" "<<(it2->eleType)<<endl;
        }
        cout<<"Printing Variable List"<<endl;
        for(auto it2:it->parameterList){
            cout<<(it2->name)<<" "<<(it2->eleType)<<endl;
        } 
    }
}

void printFunction(funcEntry* &activeFuncPtr){
    
        cout<<"Function Entry: --"<<(activeFuncPtr->name)<<"--"<<endl;
        cout<<"Printing Parameter List"<<endl;
        for(auto it2:activeFuncPtr->parameterList){
            cout<<(it2->name)<<" "<<(it2->eleType)<<endl;
        }
        cout<<"Printing Variable List"<<endl;
        for(auto it2:activeFuncPtr->variableList){
            cout<<(it2->name)<<" "<<(it2->eleType)<<endl;
        } 
}

void addFunction(funcEntry* activeFuncPtr, vector<funcEntry*> &funcEntryRecord){
    funcEntryRecord.push_back(activeFuncPtr);
}

bool arithmeticCompatible(eletype type1, eletype type2) {
    if ((type1 == INTEGER || type1 == FLOATING)
        && (type2 == INTEGER || type2 == FLOATING)) return true;
    return false;
}

eletype compareTypes(eletype type1, eletype type2) {
    if (type1 == INTEGER && type2 == INTEGER) {
        return INTEGER;
    }
    else if (type1 == FLOATING && type2 == FLOATING) {
        return FLOATING;
    }
    else if (type1 == INTEGER && type2 == FLOATING) {
        return FLOATING;
    }
    else if (type1 == FLOATING && type2 == INTEGER) {
        return FLOATING;
    }
    else return NULLVOID;
}

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
    }
}

int varTypeMapper(varType a){
    switch(a){
        case SIMPLE : return 0;
        case ARRAY  : return 1;
    }
}

int TagMapper(Tag a){
    switch(a){
        case PARAMAETER : return 0;
        case VARIABLE   : return 1;
    }
}

void populateOffsets(vector<funcEntry*> &funcEntryRecord){
    int offset;
    for(auto &funcRecord : funcEntryRecord){
        offset = 0;
        for(auto &paramRecord : funcRecord->parameterList){
            paramRecord->varOffset = offset;
            offset += 4;
        }
        // offset += 80;
        offset = 0;
        offset += 48;
        for(auto &varRecord : funcRecord->variableList){
            varRecord->varOffset = offset;
            offset += 4*(varRecord->maxDimlistOffset);
        }
        funcRecord->functionOffset = offset;
    }
    printSymbolTable(funcEntryRecord);
}

void printSymbolTable(vector<funcEntry*> &funcEntryRecord){
    ofstream symbolTable;
    symbolTable.open("symtab.txt");
    for(auto &funcRecord : funcEntryRecord){
        symbolTable << "$$" << endl;
        symbolTable << "_" << funcRecord->name << " " << eletypeMapper(funcRecord->returnType) << " ";
        symbolTable << funcRecord->numOfParam << " " << funcRecord->functionOffset << endl;
        symbolTable << "$1" << endl;
        for(auto &varRecord : funcRecord->parameterList){
            symbolTable << "_" << varRecord->name << "_" << eletypeMapper(varRecord->eleType) << "_" << varRecord->scope << " " << eletypeIntMapper(varRecord->eleType) << " " ;
            symbolTable << varRecord->scope << " " << varRecord->varOffset << endl;
        }
        symbolTable << "$2 " << funcRecord->variableList.size() << endl;
        for(auto &varRecord : funcRecord->variableList){
            symbolTable << "_" << varRecord->name << "_" << eletypeMapper(varRecord->eleType) << "_" << varRecord->scope << " " << eletypeIntMapper(varRecord->eleType) << " " ;
            symbolTable << varRecord->scope << " " << varRecord->varOffset << endl;
        }
    }
    symbolTable.close();
}

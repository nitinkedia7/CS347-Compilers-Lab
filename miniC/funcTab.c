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
        if(it->scope!=scope){
            variableList.push_back(it);
        } else {
            free(it);
        }
    }
    activeFuncPtr->variableList.swap(variableList);
}

void searchVariable(string name, funcEntry* activeFuncPtr, int &found, typeRecord *&vn) {
    vector<typeRecord*>::reverse_iterator i;
    for (i = activeFuncPtr->variableList.rbegin(); i != activeFuncPtr->variableList.rend(); ++i) {
        if (name == (*i)->name) {
            found = 1;
            vn = *i;
            return;
        }
    }
    found = 0;
    vn = NULL;
    return;
}

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
    if(found != -1)
        found=0;
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
    if(found != -1)
        found=0;
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

int gen(vector<string> &functionInstruction, string instruction, int &nextQuad){
    functionInstruction.push_back(instruction);
    nextQuad++;
    return (int)(functionInstruction.size());
}

void backpatch(vector<int> *lineNumbers, int labelNumber, vector<string> &functionInstruction){
    if(lineNumbers == NULL){
        cout << "Given line numbers for "<<labelNumber<<" is NULL"<<endl;
        return;
    }
    string statement;
    for(auto it : (*lineNumbers)){
        statement = functionInstruction[*it];
        statement += to_string(labelNumber);
        functionInstruction[*it] = statement;
    }
}

void merge(vector<int> *receiver, vector<int> *donor) {
    receiver->insert(receiver->end(), donor->begin(), donor->end());
    donor->clear();
    return;
}

string registerSet::getRegister(){
    if(tempRegister.size()){
        cout<<"Exceeded maximum temporary registers"<<endl;
    }
    string reg = "T0";
    int x = tempRegister[tempRegister.size()];
    s[1] = itoa(x);
    tempRegister.pop_back();
    return reg;
}

void registerSet::freeRegister(string s){
    char c = s[1];
    int x = atoi(c);
    for(auto it:tempRegister){
        if(it==x){
            cout<<"Register already free"<<endl;
        }
    }
    tempRegister.push_back(x);
}


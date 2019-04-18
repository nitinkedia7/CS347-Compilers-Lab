#include "funcTab.h"

void patchDataType(int eleType, vector<typeRecord*> &typeRecordList, int scope){
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
    found=0;
    return;    
}

void printList(vector<funcEntry*> &funcEntryRecord){
    
    for(auto it:funcEntryRecord){
        cout<<"Function Entry: "<<(it->name)<<endl;
        cout<<"Printing Parameter List"<<endl;
        for(auto it2:it->parameterList){
            cout<<(it2->name)<<" "<<(it2->type)<<endl;
        }
        cout<<"Printing Variable List"<<endl;
        for(auto it2:it->parameterList){
            cout<<(it2->name)<<" "<<(it2->type)<<endl;
        } 
    }
}

void printFunction(funcEntry* &activeFuncPtr){
    
        cout<<"Function Entry: "<<(activeFuncPtr->name)<<endl;
        cout<<"Printing Parameter List"<<endl;
        for(auto it2:activeFuncPtr->parameterList){
            cout<<(it2->name)<<" "<<(it2->type)<<endl;
        }
        cout<<"Printing Variable List"<<endl;
        for(auto it2:activeFuncPtr->variableList){
            cout<<(it2->name)<<" "<<(it2->type)<<endl;
        } 
}

void addFunction(funcEntry* activeFuncPtr, vector<funcEntry*> &funcEntryRecord){
    funcEntryRecord.push_back(activeFuncPtr);
}

bool arithmeticCompatible(int type1, int type2) {
    if ((type1 == INTEGER || type1 == FLOATING)
        && (type2 == INTEGER || type2 == FLOATING)) return true;
    return false;
}

int compareTypes(int type1, int type2) {
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


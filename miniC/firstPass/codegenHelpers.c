#include "codegenHelpers.h"

string registerSet::getRegister() {
    string reg = "";
    if (tempRegister.size()==0) {
        cout<<"Exceeded maximum temporary registers"<<endl;
        return reg;
    }
    reg += "T";
    int x = tempRegister[tempRegister.size()-1];
    reg += to_string(x);
    tempRegister.pop_back();
    return reg;
}

string registerSet::getFloatRegister() {
    string reg = "";
    if (floatRegister.size()==0) {
        cout<<"Exceeded maximum temporary registers"<<endl;
        return reg;
    }
    reg += "F";
    int x = floatRegister[floatRegister.size()-1];
    reg += to_string(x);
    floatRegister.pop_back();
    return reg;
}


void registerSet::freeRegister(string s){
    if(s[0]=='F'){
        s[0] = '0';
        int x = stoi(s);
        for(auto it : floatRegister){
            if(it==x){
                cout<<"Float Register already free"<<s<<endl;
                return;
            }
        }
        // cout<<"FLoat Register Freed "<< s <<endl;
        floatRegister.push_back(x);
    } else if(s[0] == 'T'){
        s[0] = '0';
        int x = stoi(s);
        for(auto it:tempRegister){
            if(it==x){
                cout<<"Int Register already free"<<s<<endl;
                return;
            }
        }
        // cout<<"Int Register Freed "<< s <<endl;
        tempRegister.push_back(x);
    } else {
        cout << "Not a Temp Variable : " << s << endl;
    }
}

void gen(vector<string> &functionInstruction, string instruction, int &nextQuad){
    functionInstruction.push_back(instruction);
    nextQuad++;
    // cout << instruction << endl;
    return;
}

void backpatch(vector<int> *&lineNumbers, int labelNumber, vector<string> &functionInstruction){
    if(lineNumbers == NULL){
        cout << "Given line numbers for "<<labelNumber<<" is NULL"<<endl;
        return;
    }
    string statement;
    for(int it : (*lineNumbers)){
        // statement = functionInstruction[it];        // statement +=("L"+ to_string(labelNumber));
        functionInstruction[it] += (to_string(labelNumber));
    }
    lineNumbers->clear();
}

void merge(vector<int> *&receiver, vector<int> *&donor) {
    if(donor==NULL || receiver == NULL){
        // cout<<"Conitnued because vector empty"<<endl;
        return;
    }
    for(int i:(*donor)){
        receiver->push_back(i);
    }
    donor->clear();
    return;
}

void mergeSwitch(vector<pair<string,int>> *&receiver,vector<pair<string,int>> *&donor) {
    if(donor==NULL || receiver == NULL){
        // cout<<"Conitnued because vector empty"<<endl;
        return;
    }
    for(auto i:(*donor)){
        receiver->push_back(i);
    }
    donor->clear();
    return;
}
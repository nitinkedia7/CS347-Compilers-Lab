#include "codegenHelpers.h"

string registerSet::getRegister() {
    if (tempRegister.size()==0) {
        cout<<"Exceeded maximum temporary registers"<<endl;
    }
    string reg = "T";
    int x = tempRegister[tempRegister.size()];
    reg += to_string(x);
    tempRegister.pop_back();
    return reg;
}


string registerSet::getFloatRegister() {
    if (tempRegister.size()==0) {
        cout<<"Exceeded maximum temporary registers"<<endl;
    }
    string reg = "F";
    int x = tempRegister[tempRegister.size()];
    reg += to_string(x);
    tempRegister.pop_back();
    return reg;
}

void registerSet::freeRegister(string s){
    if(s[0]=='F'){
        // char c = s[1];
        // s++;
        s[0] = '0';
        int x = stoi(s);
        for(auto it:tempRegister){
            if(it==x){
                cout<<"Register already free"<<endl;
            }
        }
        floatRegister.push_back(x);
    } else {
        // char c = s[1];
        // s++;
        s[0] = '0';
        int x = stoi(s);
        for(auto it:tempRegister){
            if(it==x){
                cout<<"Register already free"<<endl;
            }
        }
        tempRegister.push_back(x);
    }   
}

void gen(vector<string> &functionInstruction, string instruction, int &nextQuad){
    functionInstruction.push_back(instruction);
    nextQuad++;
    return;
}

void backpatch(vector<int> *lineNumbers, int labelNumber, vector<string> &functionInstruction){
    if(lineNumbers == NULL){
        cout << "Given line numbers for "<<labelNumber<<" is NULL"<<endl;
        return;
    }
    string statement;
    for(int it : (*lineNumbers)){
        // statement = functionInstruction[it];        // statement +=("L"+ to_string(labelNumber));
        functionInstruction[it] += ("L"+ to_string(labelNumber));
    }
    lineNumbers->clear();
}

void merge(vector<int> *receiver, vector<int> *donor) {
    receiver->insert(receiver->end(), donor->begin(), donor->end());
    donor->clear();
    return;
}
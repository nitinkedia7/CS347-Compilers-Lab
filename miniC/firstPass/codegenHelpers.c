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
    ofstream tempfile;
    if(s[0]=='F'){
        s[0] = '0';
        int x = stoi(s);
        for(auto it : floatRegister){
            if(it==x){
                tempfile.open("tempInter.txt", ios::app);
                cout<<"Float Register already free"<<s<<endl;
                tempfile.close();
                return;
            }
        }
        tempfile.open("tempInter.txt", ios::app);
        cout<<"FLoat Register Freed "<< s <<endl;
        tempfile.close();
        floatRegister.push_back(x);
    } else if(s[0] == 'T'){
        s[0] = '0';
        int x = stoi(s);
        for(auto it:tempRegister){
            if(it==x){
                tempfile.open("tempInter.txt", ios::app);
                cout<<"Int Register already free"<<s<<endl;
                tempfile.close();
                return;
            }
        }
        tempfile.open("tempInter.txt", ios::app);
        cout<<"Int Register Freed "<< s <<endl;
        tempfile.close();
        tempRegister.push_back(x);
    } else {
        cout << "Not a Temp Variable : " << s << endl;
    }
}

void gen(vector<string> &functionInstruction, string instruction, int &nextQuad){
    functionInstruction.push_back(instruction);
    nextQuad++;
    ofstream tempfile;
    tempfile.open("tempInter.txt", ios::app);
    cout<<instruction<<endl;
    tempfile.close();
    // cout<<instruction<<endl;
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
    // cout<<"Here1"<<endl;
    // vector<int> s;
    // cout<<(donor->size());
    for(int i:(*donor)){
        // cout<<"pushed into reciever"<<endl;
        receiver->push_back(i);
    }
    donor->clear();
    return;
}
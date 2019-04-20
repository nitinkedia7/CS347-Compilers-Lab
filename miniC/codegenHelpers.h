#pragma once
#include <bits/stdc++.h>
using namespace std;

class registerSet {
private:
    vector<int> tempRegister;
    vector<int> floatRegister;
public:
    registerSet(){
        tempRegister.clear();
        for(int i=0; i<10; i++){
            tempRegister.push_back(i);
        }
        floatRegister.clear();
        for(int i=0; i<32; i++){
            floatRegister.push_back(i);
        }
    }
    string getRegister();
    string getFloatRegister();
    void freeRegister(string s);
};

void gen(vector<string> &, string ,int &);
void backpatch(vector<int> *, int, vector<string> &);
void merge(vector<int> *, vector<int> *);
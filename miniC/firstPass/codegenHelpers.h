#pragma once
#include <iostream>
#include <vector>
#include <stack>
#include <stdio.h>
// #include <algorithm>
#include <utility>
#include <fstream>
using namespace std;


class registerSet {
private:
    vector<int> tempRegister;
    vector<int> floatRegister;
public:
    registerSet(){
        tempRegister.clear();
        for(int i=9; i>=0; i--){
            tempRegister.push_back(i);
        }
        floatRegister.clear();
        for(int i=10; i>=0; i--){
            if(i==0||i==12){
                continue;
            }
            floatRegister.push_back(i);
        }
    }
    string getRegister();
    string getFloatRegister();
    void freeRegister(string s);
};


void gen(vector<string> &, string ,int &);
void backpatch(vector<int> *&, int, vector<string> &);
void merge(vector<int> *&, vector<int> *&);
void mergeSwitch(vector<pair<string,int>> *&receiver,vector<pair<string,int>> *&donor); 

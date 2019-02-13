#include <bits/stdc++.h> 
using namespace std; 

int a = 1 ; class Ass 
{ 
    // Access specifier 
    public: 
  
    // Data Members 
    string geekname; 
    Ass () {
        this->geekname = "ABC";
    }
    Ass (string);
    // Member Functions() 
    void printname() 
    { 
       cout << "ASS is: " << geekname << endl; 
    } 
}; 

/* this is the
main purpose of
doing this */

Ass :: Ass (string name){
    this->geekname = name;
}

class Bss
{ 
    /* Access specifier 
    public: 
    */
    // Data Members 
    public : 
    string newname; 
    Bss () {
        this->newname = "ABC";
    }
    // Member Functions() 
    void printname() 
    { 
       cout << "BSS is: " << newname << endl; 
    } 
}; 

class Css
{ 
    // Access specifier 
    public: 
  
    // Data Members 
    int p;
    string cssname; 
    Css(int, string);
    // Member Functions() 
    void printname() 
    { 
       cout << "CSS is: " << cssname << " // " << p <<endl; 
    } 
}; 

Css::Css(int p, string s){
    this->cssname = s;
    this->p = p;
}

/*
class Dss
{ 
    // Access specifier 
    public: 
  
    // Data Members 
    int p;
    string cssname; 
    
    // Member Functions() 
    void printname() 
    { 
       cout << "CSS is: " << geekname << " " << p <<endl; 
    } 
}; 
*/

int main() { 
  
    // Declare an object of class geeks 
    Ass *obj1=new Ass(); 
    Bss* obj2 ; Css * obj3(3,"DD"); /*
    Ass obj4;
    */
    obj1->printname/* dfsdf */(); 
    obj2->printname(); 
    obj3->printname(); 
    cout<<"shvv\"//vbdrbdfbf\"";
    cout<<"/*asafas*/   ";
    cout<<"//\""<<endl; // "dadhfvkshfk"djbvdsjbv
    char a='/';
    return 0; 
} 
#include<iostream> 
using namespace std; 

class Complex { 
private: 
	int real, imag; 
public: 
	Complex(int r = 0, int i =0) {real = r; imag = i;} 
	
	// This is automatically called when '+' is used with 
	// between two Complex objects 
	Complex operator + (Complex const &obj) { 
		Complex res; 
		res.real = real + obj.real; 
		res.imag = imag + obj.imag; 
		return res; 
	} 
	void print() { cout << real << " + i" << imag << endl; } 
}; 

class Array {
public:
  int& operator[] (unsigned i) { if (i > 99) error(); return data[i]; }
  char*operator - (int i) {
      char ***t;
      ***t = 5;
      return t;
    }
private:
  int data[100];
};

int main() 
{ 
	Complex c1(10, 5), c2(2, 4); 
	Complex c3 = c1 + c2; // An example call to "operator+" 
	c3.print(); 
    Array a;
    a[10] = 42;
    a[12] += a[13];
} 

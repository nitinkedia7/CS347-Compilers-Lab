#include <iostream>
using namespace std;
class A
{
public:
	class B
	{
	private:
		int num;

	public:
		void getdata(int n)
		{
			num = n;
		}
		void putdata()
		{
			cout << "The number is " << num;
		}
		class C
		{
		public:
			int ca;
		};
	};
};

A::method1(int a){
	cout<<"anything??";
}

A sum(int b){

}

int main()
{
	cout << "Nested classes in C++" << endl;
	A::B obj(5);
	A::B::C c;
	obj.getdata(9);
	obj.putdata();
	return 0;
}
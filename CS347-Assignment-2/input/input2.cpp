// circtor.cpp
// circles use constructor for initialization
#include “msoftcon.h” // for graphics functions
////////////////////////////////////////////////////////////////
class circle //graphics circle
{
  protected:
    int xCo, yCo; //coordinates of center
    int radius;
    color fillcolor;  //color
    fstyle fillstyle; //fill pattern
  public:
    //constructor
    circle(int x, int y, int r, color fc, fstyle fs) : xCo(x), yCo(y), radius(r), fillcolor(fc), fillstyle(fs)
    {
    }
    void draw() //draws the circle
    {
        set_color(fillcolor);          //set color
        set_fill_style(fillstyle);     //set fill
        draw_circle(xCo, yCo, radius); //draw solid circle
    }
};
////////////////////////////////////////////////////////////////
int main()
{
    init_graphics(); //initialize graphics system
    //create circles
    circle *c1(15, 7, 5, cBLUE, X_FILL);
    circle c2(41, 12, 7, cRED, O_FILL);
    circle *c3(65, 18, 4, cGREEN, MEDIUM_FILL);
    c1.draw(); //draw circles
    c2.draw();
    c3.draw();
    set_cursor_pos(1, 25); //lower left corner
    return 0;
}

class Foo
{
  private:
    int data;

  public:
    Foo() : data(0) //constructor (same name as class)
    {
    }
    ~Foo() //destructor (same name with tilde)
    {
    }
};

// englcon.cpp
// constructors, adds objects using member function
#include <iostream>
using namespace std;
////////////////////////////////////////////////////////////////
class Distance //English Distance class
{
  private:
    int feet;
    float inches;

  public: //constructor (no args)
    Distance() : feet(0), inches(0.0)
    {
    }
    //constructor (two args)
    Distance(int ft, float in) : feet(ft), inches(in)
    {
    }
    void getdist() //get length from user
    {
        cout << “\nEnter feet : “;
        cin >> feet;
        cout << “Enter inches : “;
        cin >> inches;
    }
    void showdist() //display distance
    {
        cout << feet << “\’-” << inches << ‘\”’;
    }
    void add_dist(Distance, Distance); //declaration
};
//--------------------------------------------------------------
//add lengths d2 and d3
void Distance::add_dist(Distance d2, Distance d3)
{
    inches = d2.inches + d3.inches; //add the inches
    feet = 0;                       //(for possible carry)
    if (inches >= 12.0)             //if total exceeds 12.0,
    {                               //then decrease inches
        inches -= 12.0;             //by 12.0 and
        feet++;                     //increase feet
    }                               //by 1
    feet += d2.feet + d3.feet;      //add the feet
}
////////////////////////////////////////////////////////////////
int main()
{
    Distance dist1, dist3;        //define two lengths
    Distance dist2(11, 6.25);     //define and initialize dist2
    dist1.getdist();              //get dist1 from user
    dist3.add_dist(dist1, dist2); //dist3 = dist1 + dist2
    //display all lengths
    cout << “\ndist1 = “;
    dist1.showdist();
    cout << “\ndist2 = “;
    dist2.showdist();
    cout << “\ndist3 = “;
    dist3.showdist();
    cout << endl;
    return 0;
}

// counten.cpp
// inheritance with Counter class
#include <iostream>
using namespace std;
////////////////////////////////////////////////////////////////
class Counter //base class
{
  protected:            //NOTE: not private
    unsigned int count; //count
  public:
    Counter() : count(0) //no-arg constructor
    {
    }
    Counter(int c) : count(c) //1-arg constructor
    {
    }
    unsigned int get_count() const //return count
    {
        return count;
    }
    Counter operator++() //incr count (prefix)
    {
        return Counter(++count);
    }
};
////////////////////////////////////////////////////////////////
class CountDn : public Counter //derived class
{
  public:
    Counter operator--() //decr count (prefix)
    {
        return Counter(--count);
    }
};
////////////////////////////////////////////////////////////////
int main()
{
    CountDn c1; //class CountDn
    CountDn c2(100);
    cout << “\nc1 =” << c1.get_count(); //display
    cout << “\nc2 =” << c2.get_count(); //display
    ++c1;
    ++c1;
    ++c1;                               //increment c1
    cout << “\nc1 =” << c1.get_count(); //display it
    --c2;
    --c2;                               //decrement c2
    cout << “\nc2 =” << c2.get_count(); //display it
    CountDn c3 = --c2;                  //create c3 from c2
    cout << “\nc3 =” << c3.get_count(); //display c3 Distance dist2(11, 6.25);  
    cout << endl;
    return 0;
}
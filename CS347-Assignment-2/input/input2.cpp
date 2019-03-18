    #include <msoftcon.h>     
class circle   {
  protected:
    int xCo, yCo;       int radius;
    color fillcolor;        fstyle fillstyle;     public:
          circle(int x, int y, int r, color fc, fstyle fs);
    void draw()       {
        set_color(fillcolor);                    set_fill_style(fillstyle);               draw_circle(xCo, yCo, radius);       }
};
circle  ::  circle(int x, int y, int r, color fc, fstyle fs) : xCo(x), yCo(y), radius(r), fillcolor(fc), fillstyle(fs)
    {
    }
  int main()
{
    init_graphics();             circle *c1(15, 7, 5, cBLUE, X_FILL);
    circle c2(41, 12, 7, cRED, O_FILL);
    circle *c3(65, 18, 4, cGREEN, MEDIUM_FILL);
    c1.draw();       c2.draw();
    c3.draw();
    set_cursor_pos(1, 25);       return 0;
}

class Foo
{
  private:
    int data;

  public:
    Foo() : data(0)       {
    }
    ~Foo()       {
    }
};

    #include <iostream>
using namespace std;
  class Distance   {
  private:
    int feet;
    float inches;

  public:       Distance() : feet(0), inches(0.0)
    {
    }
          Distance(int ft, float in) : feet(ft), inches(in)
    {
    }
    void getdist()       {
        cout << "\nEnter feet : ";
        cin >> feet;
        cout << "Enter inches : ";
        cin >> inches;
    }
    void showdist()       {
        cout << feet <<"\’-" << inches ;
    }
    void add_dist(Distance, Distance);   };
    void Distance::add_dist(Distance d2, Distance d3)
{
    inches = d2.inches + d3.inches;       feet = 0;                             if (inches >= 12.0)                   {                                         inches -= 12.0;                       feet++;                           }                                     feet += d2.feet + d3.feet;        }
  int main()
{
    Distance dist1, dist3;              Distance dist2(11, 6.25);           dist1.getdist();                    dist3.add_dist(dist1, dist2);             cout << "\ndist1 = ";
    dist1.showdist();
    cout << "\ndist2 = ";
    dist2.showdist();
    cout << "\ndist3 = ";
    dist3.showdist();
    cout << endl;
    return 0;
}

    #include <iostream>
using namespace std;
  class Counter   {
  protected:                  unsigned int count;     public:
    Counter() : count(0) {} Counter(int c) : count(c) {}
    unsigned int get_count() const       {
        return count;
    }
    Counter operator++()       {
        return Counter(++count);
    }
};
  class CountDn : public Counter   {
  public:
    Counter operator--()       {
        return Counter(--count);
    }
};
  int main()
{
    CountDn c1;       CountDn c2(100);
    cout << "\nc1 =" << c1.get_count();       cout << "\nc2 =" << c2.get_count();       ++c1;
    ++c1;
    ++c1;                                     cout << "\nc1 =" << c1.get_count();       --c2;
    --c2;                                     cout << "\nc2 =" << c2.get_count();       CountDn c3 = --c2, c4;                        cout << "\nc3 =" << c3.get_count();       cout << endl;
    return 0;
}
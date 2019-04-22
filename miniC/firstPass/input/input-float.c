float area(int radius) {
    float pi;
    pi = 3.14159265;
    float a;
    a = pi * radius;
    a = a * radius;
    return a;
}

int main() {
    float areaval;
    int s;
    read s;
    areaval = area(s);
    print areaval;
    return 0;
}
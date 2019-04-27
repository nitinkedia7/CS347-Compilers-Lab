int sum(int a, int b, int c, int d, int e, int f) {
    int s;
    s = 0;
    s = s + a;
    s = s + b;
    s = s + c;
    s = s + d;
    s = s + e;
    s = s + f;
    return s;
}

int main() {
    int s,y; 
    s = 0;
    s = sum(s+1, s+2, s+3, s+4, s+5, sum(1,2,3,4,5,6));
    y = sum(1,2,3,4,5,6);
    print s;
    print y;
    return 0;
}
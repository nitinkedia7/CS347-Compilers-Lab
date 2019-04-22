int main() {
    int a, b, c;
    a = 1;
    b = 1;
    c = 1;
    if (a && b || c) {
        a = 2;
        b = 2;
        c = 2;
    }
    print a;
    print b;
    print c;
    return 0;
}
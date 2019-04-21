int gcd(int a, int c, int b) {
    int e, d;
    c = a;
    d = b;
    float e;
    float f;
    if (a < b) {
        c = c + d;
    }
    if (b == 0) {
        return gcd(a,b,a);
    }
    return a;
}

int main() {
    int x;
    x = gcd(10, 2, 1);
    return 0;
}
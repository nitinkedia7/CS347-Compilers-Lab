int sum(int a, int b, int c, int d, int e, int f) {
    int s;
    s = 0;
    s = s + a;
    s = s + b;
    s = s + c;
    s = s + d;
    s = s + e;
    return s;
}

int main() {
    return sum(1, 2, 3, 4, 5, 6);
}
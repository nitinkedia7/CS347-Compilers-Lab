int sum(int a, int b) {
    int s;
    s = 0;
    s = s + a;
    s = s + b;
    return s;
}

int main() {
    int s; 
    s = 0;
    read s;
    s = sum(s+1, sum(1,2));
    print s;
    return 0;
}
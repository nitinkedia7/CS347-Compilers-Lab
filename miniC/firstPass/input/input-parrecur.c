int sum(int n) {
    if (n == 0) {
        return 0;
    }
    else {
        return n+sum(n-1);
    }
}
int main() {
    int i;
    read i;
    int x = sum(sum(i));
    print x;
}
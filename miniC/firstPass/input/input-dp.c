int main() {
    int n;
    read n;
    int A[100];
    A[0] = 1;
    A[1] = 1;
    int i;
    for (i = 2; i < n; i++) {
        A[i] = A[i-1] + A[i-2];
    }
    print A[n-1];
    return 0;
}
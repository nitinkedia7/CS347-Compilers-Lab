int main() {
    int n;
    read n;
    int A[100];
    int i;
    int j;
    for (i = 0; i < n; i++) {
        read A[i];
    }
    for (i = 0; i < n; i++) {
        for (j = 1; j < n-i; j++) {
            if (A[j-1] > A[j]) {
                int temp ;
                temp = A[j];
                A[j] = A[j-1];
                A[j-1] = temp;
            }   
        }
    }
    for (i = 0; i < n; i++) {
        print A[i];
    }
    return 0;
}
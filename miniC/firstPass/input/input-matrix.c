int main() {
    int A[5][5], B[5][5], s;
    {
        int i;
        for (i = 0; i < 5; i++) {
            int j;
            for (j = 0; j < 5; j++) {
                if (i == j) {
                    A[i][j] = i+j;
                    B[i][j] = i+j;
                }
            }
        }
    }
    {
        int i;
        for (i = 0; i < 5; i++) {
            int j;
            for (j = 0; j < 5; j++) {
                s = 0;
                int k;
                for (k = 0; k < 5; k++) {
                    s = s + A[i][k] * B[k][j];
                }
            }
        }
    } 
    print s;
}
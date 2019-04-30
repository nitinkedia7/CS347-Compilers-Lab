int main() {
    float A[5][5], B[5][5], s;
    s = 0;
    {
        int i;
        for (i = 0; i < 5; i++) {
            int j;
            for (j = 0; j < 5; j++) {
                if (i==j) {
                    A[i][j] = i+j;
                    B[i][j] = i+j;
                }
                else {
                    A[i][j] = 0;
                    B[i][j] = 0;
                }
            }
        }
    }
    {
        int i;
        for (i = 0; i < 5; i++) {
            int j;
            for (j = 0; j < 5; j++) {
                int k;
                for (k = 0; k < 5; k++) {
                    s = s + A[i][k] * B[k][j];
                }
            }
        }
    } 
    print s;
}
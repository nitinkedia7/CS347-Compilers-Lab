int main() {
    int s;
    s = 0;
    int i;
    int c;
    c=0;
    for (i = 0; i < 10; i++) {
        int j;
        for (j = 0; j < 3; j++) {
            s = s + i;
            if((i + j) % 3 == 0 ){
                c++;
                if(c%3==0|| c-3 > 0)
                {
                    c = c + 2;
                }
            }
        }
    }
    print s;
    print i;
    print c;
    return 0;
}
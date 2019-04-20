int main() {
    int a, b, c;
    float d, e[5][10][15];
    a = b = 1;
    e[1][2][3] = a;
    c = e[1][2][3] - e[1][2][3];
    d = 2 * ++c;
    return 1; 
}


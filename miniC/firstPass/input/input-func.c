int gcd(int a, int b){
    if(b==0){
        return a;
    } else {
        return gcd(b, a%b);
    }
}

int main() {
    int a, b;
    a = -45;
    b = 90;
    int c;
    c = -a;
    c=b-a;
    c=b+a;
    c = gcd(-a, b);
    return 1; 
}
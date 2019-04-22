int gcd(int a, int b){
    if(b==0){
        return a;
    }
    else {
        return gcd(b, a%b);
    }
}

int lcm(int a, int b) {
    int p;
    p = (a / gcd(a, b)) * b;
    return p;
}

int main() {
    int a, b;
    a = 10;
    b = 5;
    read a;
    read b;
    {
        int a, b;
        a = 12;
        b = 4;
        read a;
        read b;
        int c;
        c = lcm(a, b);
        print c;
    }
    int c;
    c = lcm(a, b);
    print c;
    return 1; 
}
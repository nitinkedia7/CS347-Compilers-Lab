int fact(int n){
    if(n <= 0) {
        return 1;
    }
    return n*fact(n-1);
}

int main(){
    int n,f;
    n=3;
    read n;
    f=fact(n);
    print f;
    return 0;
}
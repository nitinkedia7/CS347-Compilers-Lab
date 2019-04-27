float a;
float foo(){
    float c;
    c = a+1;
    return c;
}

int main(){
    read a;
    float b = foo();
    print b;
    print a;
    return 0;
}
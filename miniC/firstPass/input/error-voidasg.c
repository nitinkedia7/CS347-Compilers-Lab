void foo(){
    int a =1;
    return;
}

int main(){
    int a =5;
    a = foo();
    a= a * foo();
    a= a / foo();
    a= a % foo();
    if (1 && foo() || foo()) {
        int b = 1;
    }   

    return foo();
}
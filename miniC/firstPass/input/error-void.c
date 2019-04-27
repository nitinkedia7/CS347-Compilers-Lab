void foo(int a) {
    a = 0;
    return;
}

int main() {
    int bar;
    bar = foo(1);
    return 0;
}
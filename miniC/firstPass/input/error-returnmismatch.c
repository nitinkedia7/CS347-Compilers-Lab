float fib(int n) {
    if (n <= 2) {
        return;
    }
    return fib(n-1) + fib(n-2);
}

int main() {
   float f;
   int n;
   read n;
   f = fib(n);
   print f;
   return 0;
}
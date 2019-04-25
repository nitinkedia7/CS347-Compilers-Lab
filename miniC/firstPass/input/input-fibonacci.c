int fib(int n) {
    if (n <= 2) {
        return 1;
    }
    return fib(n-1) + fib(n-2);
}

int main() {
   int f;
   int n;
   read n;
   f = fib(n);
   print f;
   return 0;
}
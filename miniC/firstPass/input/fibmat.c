int fib(int n) { 
    int F[2][2];
    F[0][0] = 1;
    F[0][1] = 1;
    F[1][0] = 1;
    F[1][1] = 0; 
    int M[2][2];
    M[0][0] = 1;
    M[0][1] = 1;
    M[1][0] = 1;
    M[1][1] = 0;
    if (n == 0){
        return 0; 
    }
    int i;  
    
    for (i = 2; i <= n; i += 1){
        int x =  F[0][0]*M[0][0] + F[0][1]*M[1][0]; 
        int y =  F[0][0]*M[0][1] + F[0][1]*M[1][1]; 
        int z =  F[1][0]*M[0][0] + F[1][1]*M[1][0]; 
        int w =  F[1][0]*M[0][1] + F[1][1]*M[1][1]; 
        
        F[0][0] = x; 
        F[0][1] = y; 
        F[1][0] = z; 
        F[1][1] = w;
    } 
    return F[0][0]; 
} 

int main(){ 
    int n, i = 0, a; 
    read n;
    for(i=0; i<n; ++i){
        a = fib(i);
        print a;
    }
    return 0; 
} 
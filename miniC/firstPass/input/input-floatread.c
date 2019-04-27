int min(int a, int b){
    if(a < b){
        return a;
    }
    return b;
}


int main(){
    float arr[10];
    int n;
    read n;
    if(n <= 0){
        return 0;
    }
    int i = min(n,10)-1;
    while(i--){
        read arr[i];
    }
    i = min(n,10) - 1;
    while(i--){
        print arr[i];
    }
    return 0;
}
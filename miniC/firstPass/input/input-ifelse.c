int main(){
    int a;
    a = 3;
    int f;
    f = 0;
    int b;
    b = a++ || f==0;
    if(a++ || f==0 ){
        f++;
    }
    if(a <= 3 && (f != 2)){
        f++;
        int q=2;
    }
    else{
        int q=1;
        q++;
        f--;
    }
    if(1){
        f++;
    }
    if(a < 3 && ((f = 9) || (b >= 4))){
        if(f >1){
            f++;
        }
        else{
            if(a>2){
                if(f<1){
                    a++;
                }
                else{
                    a--;
                }
            }
            f--;
        }
    }
    print a;
    print b;
    print f;
}
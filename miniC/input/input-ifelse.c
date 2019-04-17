int main(){
    int a = 3;
    int f =0;
    int b=4;
    if(a++ || f==0 ){
        f++;
    }
    if(a <= 3 && (f != 2)){
        f++;
    }
    else{
        f--;
    }
    if(a < 3 && ((f = 2) || (b >= 4))){
        if(f >1){
            f++;
        }
        else{
            f--;
        }
    }
    if(1){
        f++;
    }
}
int main(){
    int a,b;
    int c;
    c = 5;
    read a;
    read b;
    switch(a+b){
        case 1:{
            int c=1;
        }
            break;
        case 0:
            break;
        default:
            c=2;
    }

    switch(a+b){
        case 1: a=2;break;
        case 2: b=1;
        case 3: a= 3;break;
        default: b =1 ;
    }
    print a;
    print b;
    print c;
    return 0;
}
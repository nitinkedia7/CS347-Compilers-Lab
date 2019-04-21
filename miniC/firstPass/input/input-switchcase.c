int main(){
    int a=1,b;
    int c;
    switch(a=b=3&&0){
        case 1:{
            int c=1;
        }
            break;
        case 0:
            break;
        default:
            c=2;
    }
    return 0;

    switch(a+b){
        case 1: a=2;break;
        case 2: b=1;
        case 3: a= 3;break;
        default: b =1 ;
    }
}
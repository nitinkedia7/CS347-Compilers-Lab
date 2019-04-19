#include <stdio.h>

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
            int c=2;
    }
    return 0;

    switch(a+b){
        case 1: printf("case 1\n");break;
        case 2: printf("case 2\n");break;
        case 3: printf("case 1\n");break;
        default: printf("default\n");break;
    }
}
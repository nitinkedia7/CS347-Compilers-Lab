int main(){
    int a,b;
    int c;
    c = 5;
    read a;
    read b;
    switch(a+b){
        case 0:       
            switch (a){
                case 1: b = 2;
                        break;
                case 2: b = 3;
                        break;
                default : b = 0;
            }
            break;
        case 1:
            switch (b){
                case 1: a = 2;
                        break;
                case 2: a = 3;
                        break;
                default : a = 0;
            }
            break;
    }
    print a;
    print b;
    print c;

       return 0;
}
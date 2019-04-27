float a[10];

float reader(int x){
    read a[x];
}

int main(){
    int i;
    for(i=0; i<4; i++){
        reader(i);
    }
    for(i=0; i<4; i++){
        print a[i];
    }
    return 0;
}
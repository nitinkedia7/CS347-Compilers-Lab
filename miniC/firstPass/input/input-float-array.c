int main(){
    float a[10][20];
    int i, j; 
    for(i=0; i<10; i++){
        for(j=0; j<20; j++){
            a[i][j] = j/2.0;
        }
    }
    for(i=0; i<10; i++){
        for(j=0; j<20; j++){
            print a[i][j];
        }
    }
}
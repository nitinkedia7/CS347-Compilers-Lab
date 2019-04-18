#include "linkedList.h"

typedef struct {
    char* name;
    int type;
    int eletype;
    int tag;
    int scope;
    
    // vector<int> dimlist;

}typerec; 

int main(){
    linkedList* list = createList();
    typerec* newRec = (typerec*)malloc(sizeof(typerec));
    newRec->type = 0;
    for(int i=0; i<10; i++){
        newRec->type++;
        push_back(list, newRec, sizeof(typerec));
    }
    Node* temp = list->head;
    while(temp!=NULL){
        printf("%d\n", ((typerec*)temp->data)->type);
        temp = temp->next;
    }
}

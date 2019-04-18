#include "linkedList.h"

linkedList* createList() {
    linkedList* temp = (linkedList*)malloc(sizeof(linkedList));
    temp->head = NULL;
    temp->end = NULL;
    return temp;
}

void push_back(struct linkedList *list, void *newData, int size) { 
    Node* newNode = (Node*)malloc(sizeof(Node)); 
  
    newNode->data = malloc(size); 
    newNode->next = NULL; 
    memcpy(newNode->data, newData, size);

    if ((list)->head == NULL) {
        (list)->head = (list)->end = newNode;
        return;
    } 
    (list)->end->next = newNode;
    (list)->end = newNode;
}


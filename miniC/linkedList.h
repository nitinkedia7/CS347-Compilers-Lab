#include <stdio.h> 
#include <stdlib.h>
#include <string.h>

typedef struct Node{
    void *data;
    struct Node* next;
} Node;

typedef struct linkedList{
    Node* head;
    Node* end; 
} linkedList;

linkedList* createList();
void push_back(struct linkedList *list, void *newData, int size);
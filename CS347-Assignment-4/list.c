#include "list.h"

and_list join_and_list(struct and_list cond2, struct and_entry expr){
    and_entry* new_elem = malloc(sizeof(and_entry));
    memcpy(new_elem, &expr, sizeof (and_entry));
    cond2.end->next_ptr = new_elem;

    cond2.end = new_elem;
    return cond2;
}

or_list join_or_list(struct or_list condition, struct and_list cond2){
    and_list* new_elem = malloc(sizeof(and_list));
    memcpy(new_elem, &cond2, sizeof (and_list));
    condition.end->next_ptr = new_elem;
    condition.end = new_elem;
    return condition;
}

void print_list(struct or_list condition){
    and_list* temp = condition.head;
    while(temp!=NULL){
        and_entry* temp2 = temp->head;
        while(temp2!=NULL){
            if(temp2->col1!=NULL){
                printf("%s ; ", temp2->col1);
            } else {
                printf("%s ; ", temp2->col2);
            }
            temp2 = temp2->next_ptr;
            
        }
        printf("\n");
        temp = temp->next_ptr;
    }
}

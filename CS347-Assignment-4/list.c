#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct and_entry{
    char *table1, *table2, *col1, *col2;
    int val1, val2;
    char *str1, *str2;
    int operation, int1_fnd, int2_fnd;
    struct and_entry* next_ptr;
} and_entry;

typedef struct or_list {
    and_entry* head;
    and_entry* end;
} or_list;

or_list* join_list(struct or_list cond2, struct and_entry expr){
    cond2.end->next_ptr = &expr;
    cond2.end = &expr;
}


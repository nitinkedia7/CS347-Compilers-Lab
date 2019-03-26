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

typedef struct and_list {
    and_entry* head;
    and_entry* end;
    struct and_list* next_ptr;
} and_list;

typedef struct or_list {
    and_list* head;
    and_list* end;
} or_list;

and_list join_and_list(struct and_list, struct and_entry);
or_list join_or_list(struct or_list, struct and_list);
void print_list(struct or_list);
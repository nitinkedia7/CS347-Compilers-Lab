#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "list.h"

int complement(int);
int getColIndex(char *, char *);
char *retval(char *, int);
char *getType(char *, int);
int select_comparator(struct and_entry, char *, char *);
int select_compute_condition(struct or_list, char *, char *);
int equi_comparator(struct and_entry, char *, char *, char *, char *);
int equi_compute_condition(struct or_list, char *, char *, char *, char *);
int associateTable(char *, char *, struct or_list *);
void printEquiJoin(char *, char *, struct or_list *);
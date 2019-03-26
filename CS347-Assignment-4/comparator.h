#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "list.h"

void populate(char *);
int getColIndex(char *);
char *retval(char *, int);
int comparator(struct and_entry, char *);
int compute_condition(struct or_list, char *);
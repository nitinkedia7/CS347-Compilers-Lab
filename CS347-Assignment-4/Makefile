mainsSQL:	mainsSQL.l mainsSQL.y list.c comparator.c
		bison -d mainsSQL.y
		flex mainsSQL.l
		gcc -o $@ mainsSQL.tab.c lex.yy.c list.c comparator.c -lfl
		
clean:	mainsSQL mainsSQL.tab.c mainsSQL.tab.h lex.yy.c
		rm mainsSQL mainsSQL.tab.c mainsSQL.tab.h lex.yy.c
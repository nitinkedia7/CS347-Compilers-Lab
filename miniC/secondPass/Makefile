inter:	inter.l inter.y
	bison -dv inter.y
	flex inter.l
	g++ -o $@ inter.tab.c lex.yy.c
clean:	inter inter.tab.c inter.tab.h lex.yy.c
	rm inter inter.tab.c inter.tab.h lex.yy.c
inter:	inter.l inter.y symTabParser.c
	bison -d inter.y
	flex inter.l
	g++ -o $@ inter.tab.c lex.yy.c symTabParser.c
clean:	inter inter.tab.c inter.tab.h lex.yy.c
	rm inter inter.tab.c inter.tab.h lex.yy.c
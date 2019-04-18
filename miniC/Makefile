miniC:	miniC.l miniC.y funcTab.h
	bison -d miniC.y
	flex miniC.l
	g++ -o $@ miniC.tab.c lex.yy.c funcTab.c
clean:	miniC miniC.tab.c miniC.tab.h lex.yy.c
	rm miniC miniC.tab.c miniC.tab.h lex.yy.c
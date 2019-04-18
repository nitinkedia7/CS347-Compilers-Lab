miniC:	miniC.l miniC.y functab.h linkedList.c
	bison -d miniC.y
	flex miniC.l
	gcc -o $@ lex.yy.c miniC.tab.c linkedList.c -lfl

clean:	miniC miniC.tab.c miniC.tab.h miniC.output lex.yy.c
	rm miniC miniC.tab.c miniC.tab.h miniC.output lex.yy.c
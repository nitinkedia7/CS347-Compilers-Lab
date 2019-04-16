miniC:	miniC.l miniC.y
	bison -d miniC.y
	flex miniC.l
	gcc -o $@ miniC.tab.c lex.yy.c -lfl
clean:	miniC miniC.tab.c miniC.tab.h lex.yy.c
	rm miniC miniC.tab.c miniC.tab.h lex.yy.c
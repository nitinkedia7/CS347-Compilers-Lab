miniC:	miniC.l miniC.y
	bison -vd miniC.y
	flex miniC.l
	gcc -o $@ miniC.tab.c lex.yy.c -lfl
clean:	miniC miniC.tab.c miniC.tab.h miniC.output lex.yy.c
	rm miniC miniC.tab.c miniC.tab.h miniC.output lex.yy.c
main:	main.lex
	flex main.lex
	gcc lex.yy.c
	touch intermediate.txt

clean: lex.yy.c a.out intermediate.txt
	rm lex.yy.c a.out intermediate.txt

%token INTEGER VARIABLE REGISTER
%left '+' '-'
%left '*' '/'

%{
    #include<stdio.h>
    int yylex(void);
    void yyerror(char *);
    int sym[26];
	int reg[10];
%}


%%

program:
        program statement '\n'
        |
        ;
        
statement:
        expr                    {printf("%d\n", $1);}
        | VARIABLE '=' expr     {sym[$1] = $3;}
		| REGISTER '=' expr		{reg[$1] = $3;}
        ;
        
expr:
        INTEGER       
		| REGISTER				{$$ = reg[$1];}
        | VARIABLE              {$$ = sym[$1];}
        | expr '+' expr         {$$ = $1 + $3;}
        | expr '-' expr         {$$ = $1 - $3;}
        | expr '*' expr         {$$ = $1 * $3;}
        | expr '/' expr         {$$ = $1 / $3;}
        | '(' expr ')'          {$$ = $2;}
        ;
      
%%

void yyerror(char *s){
    fprintf(stderr, "%s\n", s);
}

int main(void){
    yyparse();
    return 0;
}
        
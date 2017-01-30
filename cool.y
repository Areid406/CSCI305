/*
 *  cool.y
 *             
 * Names: Alex Reid & Max Austin
 * Users: areid & maustin
 * Date: 12/05/2016
 * 
 *
 *  Parser definition for the COOL language.
 *  The parser consumes the output of lexer and does the syntactic analysis. 
 * The main analysis flow is as following. The parsing starts from program.
 * A program is composed of several classes, where each class may have one 
 * or more features. There are two types of features, attributes and methods. 
 * "Expression" is used as a sub-element for these two types. 
 * Expressions have several different forms as listed in Figure 1 in
 * Cool Manual. 

 * We completed all types of all non-terminals 
 * (classes, features, formals, expressions, & cases) 
 * List is different in that it is a sequence of non-terminals.
 * This comes in handy in constructing parse trees, such as class_list, 
 * feature_list, formal_list, etc. 
 * The call for nil_Features() is handled above in the class rules. 
 * We constructed lists using a recursive method:
 *
 *   feature_list : /* empty */
 *	{ $$ = nil_Features(); }
 *	| feature
 *	{ $$ = single_Features($1); }
 *	| feature_list feature
 *	{ $$ = append_Features($1, single_Features($2));}
 *	;	
 *
 * Let can be a complicated kind of expression.  Because it can 
 * have an optional assign expression and can be nested, we used a recursive
 * method to implement it:
 *	let
 *  : OBJECTID ':' TYPEID IN expression
 *   { $$ = let($1, $3, no_expr(), $5); }
 *  | OBJECTID ':' TYPEID ASSIGN expression IN expression
 *   { $$ = let($1, $3, $5, $7); }
 *   | OBJECTID ':' TYPEID ',' let
 *   { $$ = let($1, $3, no_expr(), $5); }
 *   | OBJECTID ':' TYPEID ASSIGN expression ',' let
 *   { $$ = let($1, $3, $5, $7); }
 *   | error let
 *   { }
 *   ;
 *
 * (PRECEDENCE)						 
 * According to the cool manul, the precedence of infix binary and prefix unary
 * operations, from highest to lowest, is given by:
 *  . 
 *  @ 
 *  ~
 *  isvoid
 *  * /
 *  + -
 *  <= <  =
 *  not
 *  <-  
 *   These operations are all left associative, except for ASSIGN, LET, and IN.
 *   Also we cannot have more than 1 '<' '<=' '=' in a row:
 *	%right LET IN
 *   %right ASSIGN
 *   %left NOT
 *   %nonassoc LE '<' '='
 *   %left '-' '+'
 *   %left '*' '/'
 *   %left ISVOID
 *   %left '~'
 *   %left '@'
 *   %left '.'
 *	
 *  (ERROR HANDLING)
 *  We did error handling in class_list, feature_list, expression_semicolon_list, and let. 
 *  The basic idea is finding the border for each case:
 *  In class_list, we recover from { or ;
 *  In feature_list, we recover from ;
 *  In let, there are many keyword terminals.
 *  We recover by coming across the terminal that directly follows the error.
 *  In expression_semicolon_list, we handle the error by recovering from ;
 *
 *  (TESTING)
 *  To test, we updated bad.cl which contains some invalid Cool codes,
 *  like add errors in class declaration and following the class definition, 
 *  multiple errors inside a block and immediately after the block. 
 *  We found our parser can produce error messages and also recover smoothly 
 *  after errors were found.
 */
 
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"
  
  extern char *curr_filename;
  
  
  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
  for the location of tokens */
    
    extern int node_lineno;          /* set before constructing a tree node
    to whatever you want the line number
    for the tree node to be */
      
      
      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;
    
    
    #define SET_NODELOC(Current)  \
    node_lineno = Current;
    
    /* IMPORTANT NOTE ON LINE NUMBERS
    *********************************
    * The above definitions and macros cause every terminal in your grammar to 
    * have the line number supplied by the lexer. The only task you have to
    * implement for line numbers to work correctly, is to use SET_NODELOC()
    * before constructing any constructs from non-terminals in your grammar.
    * Example: Consider you are matching on the following very restrictive 
    * (fictional) construct that matches a plus between two integer constants. 
    * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):
    
    plus_consts	: INT_CONST '+' INT_CONST 
    
    * where INT_CONST is a terminal for an integer constant. Now, a correct
    * action for this rule that attaches the correct line number to plus_const
    * would look like the following:
    
    plus_consts	: INT_CONST '+' INT_CONST 
    {
      // Set the line number of the current non-terminal:
      // ***********************************************
      // You can access the line numbers of the i'th item with @i, just
      // like you acess the value of the i'th exporession with $i.
      //
      // Here, we choose the line number of the last INT_CONST (@3) as the
      // line number of the resulting expression (@$). You are free to pick
      // any reasonable line as the line number of non-terminals. If you 
      // omit the statement @$=..., bison has default rules for deciding which 
      // line number to use. Check the manual for details if you are interested.
      @$ = @3;
      
      
      // Observe that we call SET_NODELOC(@3); this will set the global variable
      // node_lineno to @3. Since the constructor call "plus" uses the value of 
      // this global, the plus node will now have the correct line number.
      SET_NODELOC(@3);
      
      // construct the result node:
      $$ = plus(int_const($1), int_const($3));
    }
    
    */
    
    
    
    void yyerror(char *s);        /*  defined below; called for each parse error */
    extern int yylex();           /*  the entry point to the lexer  */
    
    /************************************************************************/
    /*                DONT CHANGE ANYTHING IN THIS SECTION                  */
    
    Program ast_root;	      /* the result of the parse  */
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}
    
    /* A union of all the types that can be the result of parsing actions. */
    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      char *error_msg;
    }
    
    /* 
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.
    
    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276 
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279 
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283
    
    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/
    
    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison 
    documentation for details). */
    
    /* Declare types for the grammar's non-terminals. */
    %type <program> program
    %type <classes> class_list
    %type <class_> class

	
    /* You will want to change the following line. */
    %type <feature> feature
	%type <features> feature_list
	%type <feature> method
	%type <feature> attr
    %type <formal> formal
	%type <formals> formal_list
	%type <formals> optional_formal_list
	%type <expression> expression
	%type <expression> optional_assign
    %type <expression> lets
	%type <expressions> expression_list   
    %type <expressions> multi_expression
	%type <case_> case
	%type <cases> case_list

 
    /* Precedence declarations go here. */    
	%right ASSIGN
	%left NOT
	%nonassoc '<' '=' LE
	%left '+' '-'
    %left '*' '/'
	%left ISVOID
	%left '~'
	%left '@'
	%left '.'
	
    %%
    /* 
    Save the root of the abstract syntax tree in a global variable.
    */
	program	: class_list	{ @$ = @1; ast_root = program($1); }
    ;
    
	class_list
    : class			/* single class */
    { $$ = single_Classes($1); parse_results = $$; }    
    | class_list class	/* several classes */
    { $$ = append_Classes($1,single_Classes($2)); parse_results = $$; }
    ;
    
    /* If no parent is specified, the class inherits from the Object class. */
	class	: CLASS TYPEID '{' feature_list '}' ';'
    { $$ = class_($2,idtable.add_string("Object"),$4,stringtable.add_string(curr_filename)); }
    | CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'
    { $$ = class_($2,$4,$6,stringtable.add_string(curr_filename)); }
    | CLASS  TYPEID error '{'    
    | error ';'
    ;
    
    /* Feature list may be empty, but no empty features in list. */
	feature_list : /* empty */
	{ $$ = nil_Features(); }
	| feature
	{ $$ = single_Features($1); }
	| feature_list feature
	{ $$ = append_Features($1, single_Features($2));}
	;
	
	/*feature -> method | attr | error; */
	feature  :  method
	{ $$ =  $1;}
	| attr
	{ $$ =  $1;}
	| error ';'
	;
	 
	method : OBJECTID '(' optional_formal_list')' ':' TYPEID '{' expression '}' ';'
	 { $$ = method($1, $3, $6, $8); }
	 ;
	 
	attr : OBJECTID ':' TYPEID optional_assign ';'
	 { $$ = attr($1, $3, $4);}
	 ;
	 
	optional_formal_list : /*can be empty*/
	 { $$ = nil_Formals(); }
	 | formal_list
	 { $$ = $1;}
     | error
	 ;
     
	 /*formal_list cannot be empty*/
	formal_list : formal
	 { $$ = single_Formals($1);}
	 | formal_list ',' formal
	 { $$ = append_Formals($1, single_Formals($3));}	
     |  error  
	 ;
	 
	optional_assign : /*empty*/
	{ $$ = no_expr(); }
	| ASSIGN expression
	{ $$ = $2;}
	;
	 
	formal : OBJECTID ':' TYPEID
	{ $$ = formal($1, $3); }
	;
	 
	 
	/*case_list cannot be empty*/
	case_list : case
	{ $$ = single_Cases($1); }
	| case_list case
	{ $$ = append_Cases($1, single_Cases($2)); }
    | case error ESAC
	;
	 
	case : OBJECTID ':' TYPEID DARROW expression ';'
	{ $$ = branch($1, $3, $5);}
    | error ESAC
	;
	 
	lets : LET OBJECTID ':' TYPEID IN expression
    { $$ = let($2, $4, no_expr(), $6); }	
    | LET OBJECTID ':' TYPEID ASSIGN expression IN expression
    { $$ = let($2, $4, $6, $8); }
    | LET OBJECTID ':' TYPEID lets 
    { $$ = let($2, $4, no_expr(), $5); }
    | LET OBJECTID ':' TYPEID ASSIGN expression lets
    { $$ = let($2, $4, $6, $7);}
    | ',' OBJECTID ':' TYPEID IN expression
    { $$ = let($2, $4, no_expr(), $6); }
    | ',' OBJECTID ':' TYPEID ASSIGN expression IN expression
    { $$ = let($2, $4, $6, $8); }	 
	| ',' OBJECTID ':' TYPEID lets
	{ $$ = let($2, $4, no_expr(), $5); }
	| ',' OBJECTID ':' TYPEID ASSIGN expression lets
	{ $$ = let($2, $4, $6, $7); }
	| LET error IN expression
	| LET OBJECTID ':' error IN expression
	| LET OBJECTID ':' TYPEID error IN expression
	| LET OBJECTID ':' TYPEID ASSIGN error IN expression
	| LET OBJECTID ':' TYPEID ASSIGN expression IN error
	| ',' error IN expression
	| ',' OBJECTID ':' error IN expression
	| ',' OBJECTID ':' TYPEID error IN expression
	| ',' OBJECTID ':' TYPEID ASSIGN error IN expression
	| ',' OBJECTID ':' TYPEID ASSIGN expression IN error    
    ;
	 
	 
	/*expression_list cannot be empty, used for dispatch and static dispatch */
	expression_list : expression
	{ $$ = single_Expressions($1);}
	| expression_list ',' expression
	{ $$ = append_Expressions($1, single_Expressions($3));}
	;
     
	/*multi_expression cannot be empty, used for block of expressions */
	multi_expression : expression ';'
	{ $$ = single_Expressions($1);}
	| multi_expression expression ';'
	{ $$ = append_Expressions($1, single_Expressions($2));}
	| error ';'
	;
	 
	expression : OBJECTID ASSIGN expression
	{ $$ = assign($1, $3);} /*assignment*/
	/*dispatch*/
	| expression '.' OBJECTID '(' ')'
	{ $$ = dispatch($1, $3, nil_Expressions());}
	| expression '.' OBJECTID '(' expression_list ')'
	{ $$ = dispatch($1, $3, $5);}
	| OBJECTID '(' ')'
	{ $$ = dispatch( object(idtable.add_string("self")), $1, nil_Expressions());}
	| OBJECTID '(' expression_list ')'
	{ $$ = dispatch( object(idtable.add_string("self")), $1, $3);}	     	 
	 
    /*static dispatch*/
	| expression '@' TYPEID '.' OBJECTID '(' ')'
	{ $$ = static_dispatch($1, $3, $5, nil_Expressions());}
	| expression '@' TYPEID '.' OBJECTID '(' expression_list ')'
	{ $$ = static_dispatch($1, $3, $5, $7);}
     
    /*if-else condition*/
	| IF expression THEN expression ELSE expression FI
	{ $$= cond($2, $4, $6);}
	| IF error
	| IF expression THEN error
	| IF expression THEN expression ELSE error
	 
	/*while loop*/
	| WHILE expression LOOP expression POOL
	{ $$ = loop($2, $4);}
	
	/*block expressions*/
	| '{' multi_expression '}'
	{ $$ = block($2);}
	 
	/*let statements*/
	| lets
	{ $$ = $1;}
	 
	/*case statements*/
	| CASE expression OF case_list ESAC
	{ $$ = typcase($2, $4);}
	 
	| NEW TYPEID
	{ $$ = new_($2);}
	| ISVOID expression
	{ $$ = isvoid($2);}
	
	/*arithmetic operations*/
    | '~' expression 
    { $$ = neg($2);}
	| expression '+' expression
	{ $$ = plus($1, $3);}
	| expression '-' expression
	{ $$ = sub($1, $3); }
	| expression '*' expression
	{ $$ = mul($1, $3); }
    | expression '/' expression
    { $$ = divide($1, $3); }	
	
	 
	/*comparisons*/
	| expression '<' expression
	{ $$ = lt($1, $3);}
	| expression LE expression
	{ $$ = leq($1, $3);}
	| expression '=' expression
	{ $$ = eq($1, $3);}
	 
	| NOT expression
	{ $$ = comp($2);}
	| '(' expression ')'
	{ $$ = $2;}
	| OBJECTID
	{ $$ = object($1);}
	| INT_CONST
	{ $$ = int_const($1); }
	| STR_CONST
	{ $$ = string_const($1); }
	| BOOL_CONST
	{ $$ = bool_const($1); }
    | error 
     
    /* end of grammar */
	%%

	/* This function is called automatically when Bison detects a parse error. */
	void yyerror(char *s)
	{
	  extern int curr_lineno;

	  cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
	  << s << " at or near ";
	  print_cool_token(yychar);
	  cerr << endl;
	  omerrs++;

	  if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
	}


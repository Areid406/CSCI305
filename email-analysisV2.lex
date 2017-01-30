/*
 * Less-Simple Lexical Analyzer that recognizes Email Addresses, Phone Numbers, Zip Codes
 * F17 CSCI 305 Programming Languages - Lab 01
 * 2016-08-26
 * Alex Reid
 * Version 0.2
 *
 */

EMAIL	^([a-z0-9_\.-]+)@([a-z0-9_\.-]+)\.([a-z\.]{2,6})$

TOLLFREE ^(\((800|866|877|888)\))-([0-9]{3})-([0-9]{4})$

LONG ^([0-9]{3})-([0-9]{3})-([0-9]{4})$

LOCAL ^([0-9]{3})-([0-9]{4})$

ZIP4  ^([0-9]{5})-([0-9]{4})$

ZIP   ^([0-9]{5})$



%%

{EMAIL}    {
	        printf("Found an E-Mail Address: %s\n", yytext);
            }


{TOLLFREE} {
            printf("Found a Toll-Free U.S. Phone Number: %s\n", yytext);
           }            
           
{LONG}    {
            printf("Found a Long-Distance U.S. Phone Number: %s\n", yytext);
           }  
           
{LOCAL}    {
            printf("Found a Local U.S. Phone Number: %s\n", yytext);
           }                     
           
{ZIP4}     {
	        printf("Found a U.S. Zip Code: %s\n", yytext);
            }
 
{ZIP}      {
            printf("Found a U.S. Zip Code: %s\n", yytext);
            }           
            

%%

int main(int argc, char **argv) 
{
    ++argv, --argc; /* skip over program name */

    if (argc > 0)
       yyin = fopen(argv[1], "r");
    else
       yyin = stdin;

    yylex();
}

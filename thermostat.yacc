typedef enum {ON, OFF} bool;

#DEFINE TEMP_LO
#DEFINE TEMP_HI
#DEFINE HUMID_HI
#DEFINE HUMID_LO



heatcmd, humidcmd, ONSTATE, exitcmd tokens


heat_toggle:

HEATCMD

|

HEATCMD STATE
		heatState = ($2 == ONSTATE) ? ON : OFF;
		(void) printf(stuff) 
		
		

!#/bin/bash
# Use this to run I/O test cases
function query { 
    read LOGIC
    case $LOGIC in
	"Y" | "y")  LOGIC=0;;
	"N" | "n")  LOGIC=1;;    
	*        )  echo 'Invalid input.  Please enter "y" or "n"'
		    location ;;
    esac
}
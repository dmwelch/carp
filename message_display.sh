#!/bin/bash

#function message_display{
#############################################################
#       Output a string with a border                       #
#       Arguments:                                          #
#       1.      string                                      #
#############################################################
length=''
str=''
# exit status definitions
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

function string
{
        #####################################################
        #       Emulate the old BASIC function "string$"    #
        #       Arguments:                                  #
        #       1.      character                           #
        #       2.      length                              #
        #####################################################
        local string_length # local variable
        # Fatal error if required arguments are missing
        if [[ "$1" = "" || "$2" = "" ]]; then
                echo "message_display,string: INTERNAL ERROR - arguments not passed correctly"
                exit $EXIT_BUG # if arguments NOT passed to function, fatal error
        fi

        # Make sure that argument 2 is actually a number
        string_length=$(echo "$2" | awk '/^[0-9]*$/ { print $0 }')
        if [ -z "$string_length" ]; then
                echo "message_display,string: INTERNAL ERROR - argument must be a number"
                exit $EXIT_BUG
        fi

        # Make the string
        awk -v char=$1 -v len=$string_length '
        BEGIN {
                str = ""
                for (i=0; i < len; i++) {
                        str = str char
                }
                print str
        }'

}       # end of string

# Fatal error if required arguments are missing
if [ "$1" = "" ]; then
        echo "message_display: missing argument 1"
        exit $EXIT_FAILURE
fi

length=$(echo $1 | awk '{ print length($0) }')
str=$(string "-" $length)
if [[ $? -ne 0 ]]; then # If the function string exits in an abnormal way, kill program with error code
    echo $str
    exit $EXIT_ERROR
fi
echo ""
echo $str
echo $1
echo $str
echo ""
#!/bin/bash

###########################################################################
#
#	Shell program to generate a beeping alarm.
#
#	Copyright 2000-2002, William Shotts <bshotts@users.sourceforge.net>.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public License as
#	published by the Free Software Foundation; either version 2 of the
#	License, or (at your option) any later version. 
#
#	This program is distributed in the hope that it will be useful, but
#	WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#	General Public License for more details. 
#
#	This software is part of the LinuxCommand.org project, a site for
#	Linux education and advocacy devoted to helping users of legacy
#	operating systems migrate into the future.
#
#	You may contact the LinuxCommand.org project at:
#
#		http://www.linuxcommand.org
#
#	Description:
#
#	This program causes your computer to beep until you press the
#	enter key.  This is useful when placed after a long process to
#	alert the user that something requires his/her attention.  The
#	program will accept options to control the rate of beeping (the
#	default is 1 beep per second) and the prompting message.
#
#	Usage:
#
#		alarm [ -h | --help ] [-s seconds] [-m message]
#
#	Options:
#
#		-h, --help	Display this help message and exit.
#		-s  seconds     seconds between beeps
#		-m  message     message to display
#
#
#	Revisions:
#
#	04/02/2000	File created
#	04/02/2000	Completed first version (1.0.0)
#	02/17/2002	Cosmetic changes (1.0.1)
#
#	$Id: alarm,v 1.2 2002/02/18 14:18:38 bshotts Exp $
###########################################################################


###########################################################################
#	Constants
###########################################################################

PROGNAME=$(basename $0)
VERSION="1.0.1"
TEMP_FILE=/tmp/${PROGNAME}.$$


###########################################################################
#	Functions
###########################################################################


function clean_up
{

	#####	
	#	Function to remove temporary files and other housekeeping
	#	No arguments
	#####

	# Kill background process if it is still running
	
	if [ "$pid" != "" ]; then
		kill $pid
	fi
}


function graceful_exit
{
	#####
	#	Function called for a graceful exit
	#	No arguments
	#####

	clean_up
	exit
}


function error_exit 
{
	#####	
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	
	echo "${PROGNAME}: ${1:-"Unknown Error"}" >&2
	clean_up
	exit 1
}


function term_exit
{
	#####
	#	Function to perform exit if termination signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Terminated"
	clean_up
	exit
}


function int_exit
{
	#####
	#	Function to perform exit if interrupt signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Aborted by user"
	clean_up
	exit
}


function usage
{
	#####
	#	Function to display usage message (does not exit)
	#	No arguments
	#####

	echo "Usage: ${PROGNAME} [-h | --help] [-s seconds] [-m message]"
}


function helptext
{
	#####
	#	Function to display help message for program
	#	No arguments
	#####
	
	local tab=$(echo -en "\t\t")
		
	cat <<- -EOF-

	${PROGNAME} ver. ${VERSION}	
	This is a program to generate a beeping alarm.
	
	$(usage)
	
	Options:
	
	-h, --help	Display this help message and exit.
	-s  seconds     seconds between beeps
	-m  message     message to display
			
	
		
	-EOF-
}	


function check_seconds
{
	#####
	#	Verify that seconds is a number
	#	Returns number to stdout if seconds is a
	#	number, returns nothing otherwise.
	#	Arguments:
	#		1	number of seconds (required)
	#####

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then
		error_exit "check_seconds: missing argument 1"
	fi

	echo "$1" | awk '/^[0-9]*$/ { print $0 }'

}	# end of check_seconds


function string
{
	#####
	#	Emulate the old BASIC function "string$"
	#	Arguments:
	#	1.	character
	#	2.	length
	#####

	local length

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then
		error_exit "string: missing argument 1"
	fi

	if [ "$2" = "" ]; then
		error_exit "string: missing argument 2"
	fi

	# Make sure that argument 2 is actually a number

	length=$(echo "$2" | awk '/^[0-9]*$/ { print $0 }')
	if [ -z "$length" ]; then
		error_exit "string: argument must be a number"
	fi

	# Make the string

	awk -v char=$1 -v len=$length '

	BEGIN {
		str = ""
		for (i=0; i < len; i++) {
			str = str char
		}
		print str
	}'

}	# end of string


function message_display
{
	######
	#	Output a string with a border
	#	Arguments:
	#	1.	string
	#####

	local length str

	# Fatal error if required arguments are missing

	if [ "$1" = "" ]; then
		error_exit "message_border: missing argument 1"
	fi

	length=$(echo $1 | awk '{ print length($0) }')
	str=$(string "-" $length)
	echo $str
	echo $1
	echo $str

}	# end of message_border


###########################################################################
#	Program starts here
###########################################################################

# Trap TERM, HUP, and INT signals and properly exit

trap term_exit TERM HUP
trap int_exit INT

# Process command line arguments

if [ "$1" = "--help" ]; then
	helptext
	graceful_exit
fi

# Process arguments - edit to taste

seconds=1
message="${PROGNAME}: Press enter to continue "
pid=

while getopts ":hs:m:" opt; do
	case $opt in
		s )	seconds=$OPTARG
			if [ "$(check_seconds $seconds)" = "" ] ; then
				error_exit "seconds must be a number"
			fi ;;
		m )	message="${PROGNAME}: ${OPTARG} - Press Enter to continue" ;;
		h )	helptext
			graceful_exit ;;
		* )	usage
			exit 1
	esac
done

# Launch beeping sub-shell and put it in the background

( while true; do
	echo -en "\007"
	sleep $seconds
  done ) &

# Get process ID of sub-subshell

pid=$!

# Display prompt and wait for user to press enter key

message_display "$message"
read foo

# Now that key has been pressed, kill sub-shell

kill $pid

# All done - make pid empty so clean_up won't kill anything

pid=

graceful_exit


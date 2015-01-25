#!/bin/bash
############################################################################
# Script:       vrml2dat.sh                                                #
# Task:         Script to convert vrml mesh data from Paraview into dat    #
#               mesh file suitable for tecplot                             #
# Author:       David Welch                                                #
# Contact:      dmwelch@engineering.uiowa.edu                              #
# Date:         27 July, 2011                                              #
# Licence:      Copyright (C) 2011 David Welch                             #
#                                                                          #
# This program is free software: you can redistribute it and/or modify     #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation, either version 3 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    This program is distributed in the hope that it will be useful,       #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#                                                                          #
############################################################################
############################################################################
#                                                                          #
#                         global variables                                 #
#                                                                          #
############################################################################
SCRIPTNAME=$(basename ${0} .sh)

# Number of parameters needed (Edit line 55 logic)
NUMOFPARAMS=2

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

# variables for option switches with default values
VERBOSE="n"
OPTFILE=""
LICENSE="COPYING"

############################################################################
#                                                                          #
#                             functions                                    #
#                                                                          #
############################################################################
function usage {
    echo "Usage: ${SCRIPTNAME} [-h] [-v] [-c] [-i inputfile] [-o outputfile]" >&2
    [[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

function copyright {
        DIR=`find / -type d -name "name" 2>/dev/null`
        exec < "${DIR}/${LICENSE}"
        while read LINE ; do
                echo ${LINE}
        done
}

############################################################################
#                                                                          #
#                           main program                                   #
#                                                                          #
############################################################################

# the options -h for help should always be present. Options -v and
# -o are examples. -o needs a parameter, indicated by the colon ":"
# following in the getopts call
while getopts 'i:o:vhc' OPTION ; do
    case ${OPTION} in
                c)      copyright
                        ;;
        v)	VERBOSE=y
            ;;
        o)	OUTPUTFILE="${OPTARG}"
            ;;
        i)  INPUTFILE="${OPTARG}"
            ;;
        h)	usage ${EXIT_SUCCESS}
            ;;
        \?)	echo "unknown option \"-${OPTARG}\"." >&2
            usage ${EXIT_ERROR}
            ;;
        :)	echo "option \"-${OPTARG}\" requires an argument." >&2
            usage ${EXIT_ERROR}
            ;;
        *)	echo "Impossible error. parameter: ${OPTION}" >&2
            usage ${EXIT_BUG}
            ;;
    esac
done

# skip parsed options
shift $(( OPTIND - 1 ))

# if you want to check for a minimum or maximum number of arguments,
# do it here
case $# in
    2)  INPUTFILE="$1"; OUTPUTFILE="$2"
        ;;
    0)  ;; #flags -i and -o are used?  Check for them
    *)  echo "Wrong number of parameters" >&2
        usage ${EXIT_ERROR}
        ;;
esac

# loop through all arguments
# for ARG ; do
#     if [[ ${VERBOSE} = y ]] ; then
#         echo -n "argument: "
#     fi
#     echo ${ARG}
# done

if [[ ${VERBOSE} = y ]]; then
    # input is first argurment, output is second
    echo -e "Input file:\t$INPUTFILE"
    echo -e "Output file:\t$OUTPUTFILE"
fi

# We use sed to get the elements matrix (assumes it is the first element matrix in vrml file)
sed -n '/coordIndex/,/Transform/ {              # Between "coordIndex" and "Transform"
    /[0-9]/ p                                   # If the line contains a number, print it
    /Transform/ q }' <$INPUTFILE >/tmp/elements.txt # Quit at first instance of "Transform"
# We use awk to increment our elements matrix by one
awk -f ~/svn/uiowa/bash/incrementElements.awk /tmp/elements.txt
# We use sed to get the node matrix (assumes it is the first element matrix in vrml file)
sed -n '/\<point\>/,/coordIndex/ {              # Between "coordIndex" and "point"
    s/,//                                       # Replace all commas with nothing
    /[0-9]/ p                                   # If the line contains a number, print it
    /coordIndex/ q }' <$INPUTFILE >/tmp/nodes.txt # Quit at first instance of "coordIndex"
# Use wc (wordcount) to calculate the number of nodes and elements in the two temp files
NODECOUNT=`wc -w /tmp/nodes.txt`;       NODECOUNT=$(( ${NODECOUNT%%" /tmp/nodes.txt"}/3))
ELEMENTCOUNT=`wc -w /tmp/elements.txt`; ELEMENTCOUNT=$(( ${ELEMENTCOUNT%%" /tmp/elements.txt"}/3))
echo $INPUTFILE $NODECOUNT $ELEMENTCOUNT
# Write out .dat header
echo "VARIABLES = X,Y,Z
ZONE N=$NODECOUNT,E=$ELEMENTCOUNT,F=FEPOINT,ET=TRIANGLE" 1>/tmp/datHeader.txt
# Add the files together and now you have a tecplot file!
cat /tmp/datHeader.txt /tmp/nodes.txt /tmp/elements.txt 1>$OUTPUTFILE

#Optional: I want to have a .mat file as well
dat2mat.sh $OUTPUTFILE

exit ${EXIT_SUCCESS}
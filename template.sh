#!/bin/bash
############################################################################
# Script:	template.sh                                                #
# Task:	Template for creating own scripts. Already contains                #
#		basic elements (usage-funkcion, parsing of commandline     #
#		options with getopts and predefined variables)             #
# Author:       Author                                                     #
# Contact:      Contact info                                               #
# Date:         dd Mmm, 20YY                                               #
# Licence:      Copyright (C) 20YY Author                                  #
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
#    along with this program.  If not, see <http://www.gnu.org/licenses/>. #                #                                                                          #
############################################################################
############################################################################
#                                                                          #
#                         global variables                                 #
#                                                                          #
############################################################################
SCRIPTNAME=$(basename ${0} .sh)

# Number of parameters needed (Edit line 55 logic)
NUMOFPARAMS=1

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
	echo "Usage: ${SCRIPTNAME} [-h] [-v] [-c] [-o arg] file ..." >&2
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
while getopts ':o:vhc' OPTION ; do
	case ${OPTION} in
        c)  copyright
            ;;
	    v)	VERBOSE="y"
			;;
		o)	OPTFILE="${OPTARG}"
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
if (( $# -ne $NUMOFPARAMS )) ; then
	echo "Wrong number of parameters" >&2
	usage ${EXIT_ERROR}
fi

# loop through all arguments
for ARG ; do
	if [[ ${VERBOSE} == "y" ]] ; then
		echo -n "argument: "
	fi
	echo ${ARG}
done

exit ${EXIT_SUCCESS}

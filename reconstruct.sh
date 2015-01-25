#!/bin/bash
############################################################################
# Script:	reconstruct.sh                                             #
# Task:	        This script searches for files ending in _segm.vti and     #
#		passes the batch of them through a meshing and centerline  #
#		analysis.  Other methods will be implemented in future     #
#               This can be run as a stand-alone program.                  #
# Author:       Dave Welch                                                 #
# Contact:      david.m.welch@gmail.com                                    #
# Date:         10 Feb, 2010                                               #
# Licence:      Copyright (C) 2010 David M. Welch                          #
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
NUMOFPARAMS=0

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
                c)      copyright
                        ;;
		v)	VERBOSE=y
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
if [[ $# -ne $NUMOFPARAMS ]] ; then
	echo "Wrong number of parameters" >&2
	usage ${EXIT_ERROR}
fi

# loop through all arguments
for ARG ; do
	if [[ ${VERBOSE} = y ]] ; then
		echo -n "argument: "
	fi
	echo ${ARG}
done
if [[ -z ${PATIENTPATH} ]] ; then
        . get_patient_path.sh
        # Needed on BIOMOST000
        #export PYTHONPATH=/usr/css/opt/vmtk-0.8/lib:/usr/css/opt/vmtk-0.8/lib/vmtk:/usr/css/opt/vtk-5.4.2/lib64/python2.6/site-packages
        #export LD_LIBRARY_PATH=/usr/css/opt/vtk-5.4.2/lib/vtk-5.4:/usr/css/opt/InsightToolkit-3.16.0/lib/InsightToolkit:/usr/css/opt/vmtk-0.8/lib:/usr/css/opt/vmtk-0.8/lib/vmtk
fi

INPUT=`zenity --file-selection --filename=$PATIENTPATH/ --title="Select segm file to mesh"`
# Manasi wants Tecplot ASAP here!
###vmtkmarchingcubes -ifile ${INPUT} --pipe vmtksurfacesubdivision -method loop -ofile ${INPUT%%segm.vti}mesh.vtp --pipe vmtksurfacetomesh --pipe vmtkmeshscaling -scale 0.1 --pipe vmtkmeshwriter -f tecplot -ofile ${INPUT%%segm.vti}mesh.dat # Write tecplot file in cgs units, not in mm, that is C^2continuous

vmtkmarchingcubes -ifile ${INPUT} --pipe vmtksurfacetriangle -pipe vmtksurfacewriter -f tecplot -ofile ${INPUT%%.vti}.dat # Tecplot files need .dat extention, but no interior manipulations

# # #Automatically cut ends by identifying endpoints to centerlines
# # # vmtksurfacereader -ifile ${INPUT%%segm.vti}mesh.vtp --pipe vmtkcenterlines  -ofile ${INPUT%%segm.vti}ctrlines.vtp --pipe vmtkendpointextractor --pipe vmtkbranchclipper --pipe vmtksurfaceconnectivity -cleanoutput 1 --pipe vmtkrenderer --pipe vmtksurfaceviewer -opacity 0.25 --pipe vmtksurfaceviewer -i @vmtkcenterlines.voronoidiagram -array MaximumInscribedSphereRadius --pipe vmtksurfaceviewer -i @vmtkcenterlines.o --pipe vmtksurfacewriter -ofile ${INPUT%%segm.vti}clip.vtp # Did we get them all?
# # # `zenity --question --width=150 --title="Automated Clipping" --text="Did this clip the surface accurately?" --ok-label="_Yes" --cancel-label="_No"`
# # # case $? in
# # #     0)      ;;
# # # -1 | 1)
# # #             vmtksurfacereader -ifile ${INPUT%%segm.vti}clip.vtp --pipe vmtkbranchclipper -ofile ${INPUT%%segm.vti}clip.vtp --pipe vmtksurfacereader --pipe vmtkcenterlines -seedselector openprofiles -ofile ${INPUT%%segm.vti}ctrlines.vtp --pipe vmtkrenderer --pipe vmtksurfaceviewer -opacity 0.25 --pipe vmtksurfaceviewer -i @vmtkcenterlines.voronoidiagram -array MaximumInscribedSphereRadius --pipe vmtksurfaceviewer -i @vmtkcenterlines.o ;;
# # # esac
# # #
# # # # Add flow extensions
# # # vmtksurfacereader -ifile ${INPUT%%segm.vti}clip.vtp --pipe vmtkcenterlines -seedselector openprofiles --pipe vmtkflowextensions -adaptivelength 1 -extensionratio 20 -normalestimationratio 1 -interactive 0 --pipe vmtksurfacewriter -ofile ${INPUT%%segm.vti}flow.vtp --pipe vmtksurfacetomesh --pipe vmtkmeshscaling -scale 0.1 --pipe vmtkmeshwriter -f tecplot -ofile ${INPUT%%segm.vti}flow_mesh.dat

tecplot ${INPUT%%segm.vti}mesh.dat
exit ${EXIT_SUCCESS}

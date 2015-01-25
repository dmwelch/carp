#!/bin/bash
############################################################################
# Script:	CARP.sh                                                        #
# Task:		Moves user through a VMTK segmentation session with            #
#		    explicit branch processes                                      #
# Requirements:                                                            #
#           Eye of Gnome image viewer                                      #
#		    image file ".C_o_W.png"                                        #
#		    VMTK                                                           #
#           message_display.sh                                             #
#           get_dicom_path.sh                                              #
#           get_location,sh                                                #
#           get_patient_path.sh                                            #
#           get_dicom_path.sh                                              #
############################################################################
#                         global variables                                 #
############################################################################

SCRIPTNAME=$(basename ${0} .sh)
# Zenity variables
TITLE="CARP v1.0"
WIDTH=325
# Number of parameters needed (Edit line 55 logic)
NUMOFPARAMS=0
# Code testing parameters
DEBUGFILENAMES=1 # Zero=ON
DEBUGCOUNT=0
# exit status definitions
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10
# variables for option switches with default values
VERBOSE="n"
OPTFOLDER=""
# variables for aneurysm segmentation
NOW=""
FILENAME=""
LOGIC=""
INITIAL=""
PICPATH="/var/tmp/dmwelch/uiowa/bash"
PICFILE=".CoW.png"
PATIENTPATH=""
PATIENT_NUM=""
DICOMPATH=""
TYPE=""
LEVEL=""
MESSAGE=""
AIRLEVEL=""
BONELEVEL=""
LEVELTYPE=""
ANEURYSM_NUM=1
ANEURYSM=1 #Equals false unless needed
############################################################################
#                             functions                                    #
############################################################################
function usage {
    echo "Usage: ${SCRIPTNAME} [-h] [-v] [-i] [-o folder]" >&2
    [[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

function debug {
    if [[ $DEBUGFILENAMES -eq 0 ]] ; then
        echo "${DEBUGCOUNT} -> $1"
        DEBUGCOUNT=$(( ${DEBUGCOUNT} + 1 ))
    fi
}

function interest_volume {
    zenity --question --width=$WIDTH --title=${TITLE} --text="Create a new VOI?" --ok-label="_Yes" --cancel-label="_No"
    case $? in
        0) # If creating a new VOI, get the location to name correctly
            . get_location.sh  ;;
        1) # If using an old VOI, select it from a list
            FILENAME=`zenity --width=$WIDTH --title=${TITLE} --filename=${PATIENTPATH}/ --file-selection --title="Select VOI to use"`
            FILENAME=`basename ${FILENAME%%'.vti'}` #Strip off folder information
            . message_display.sh "Showing VOI selected. Type \"q\" in render window to proceed"
            vmtkimagereader -ifile ${PATIENTPATH}/${FILENAME}.vti --pipe vmtkimageviewer # Show user the voi they choose
            debug $FILENAME ;;
        -1)
            exit ${EXIT_FAILURE} ;;
    esac
}

function create_sigmoid {
    zenity --width=$WIDTH --title="${TITLE}" --question --text="Does this VOI need $1 corrections?" --ok-label="_Yes" --cancel-label="_No"
        case $? in
            0)
                create_feature ;;
       -1 | 1)
                ;;
            *)
                echo $? ; exit ${EXIT_BUG}
        esac
}

function air_feature {
    LEVEL=`zenity --entry --title="${TITLE}" --width=$WIDTH --text="Enter the value for air" --cancel-label="_Done"`
    while [[ $? -eq 0 ]] ; do
        AIRLEVEL=$LEVEL; . message_display.sh "Displaying potential air feature"
        vmtkimagereader -ifile ${PATIENTPATH}/${FILENAME}.vti --pipe vmtkmarchingcubes -l ${AIRLEVEL} --pipe vmtkrenderer --pipe vmtkimageviewer --pipe vmtksurfaceviewer
        LEVEL=`zenity --entry --title="${TITLE}" --width=$WIDTH --text="Enter the value for air" --cancel-label="_Done"`
    done
    LEVEL=$AIRLEVEL #Needed b/c last zenity call in while loop erases value for LEVEL!
}

function bone_feature {
    LEVEL=`zenity --entry --title="${TITLE}" --width=$WIDTH --text="Enter the value for bone" --cancel-label="_Done"`
    while [[ $? -eq 0 ]] ; do
        BONELEVEL=$LEVEL; . message_display.sh "Displaying potential bone feature"
        vmtkimagereader -ifile ${PATIENTPATH}/${FILENAME}.vti --pipe vmtkmarchingcubes -ifile ${PATIENTPATH}/${FILENAME}.vti -l ${BONELEVEL} --pipe vmtkrenderer --pipe vmtkimageviewer --pipe vmtksurfaceviewer
        LEVEL=`zenity --entry --title="${TITLE}" --width=$WIDTH --text="Enter the value for bone" --cancel-label="_Done"`
    done
    LEVEL=$BONELEVEL #Needed b/c last zenity call in while loop erases value for LEVEL!
}

function create_feature {
    zenity --question --width=$WIDTH --title=${TITLE} --text="Is there already a(n) ${TYPE} file?" --ok-label="_Yes" --cancel-label="_No"
    case $? in
        0) # Already a file
            LEVEL=`zenity --file-selection --title="${TITLE}: Select ${TYPE} file" --filename="${PATIENTPATH}/"`
            case $? in
                0)
                    ;;
                1)
                    echo "No file selected."
                    . quit.sh ;;
                -1)
                    echo 'Zenity has caused an error!' # Something happened with zenity
                    exit ${EXIT_ERROR} ;;
                *)
                    echo $? ; exit ${EXIT_BUG}
            esac
            # Removes front and back from filename, leaving only LEVEL value
            LEVEL=${LEVEL%%.vti}
            LEVEL=${LEVEL##*${FILENAME}_${TYPE}_}
            # Now we need to pass the level value to the correct container variable
            if [[ ${TYPE} == 'air' ]]; then
                AIRLEVEL=${LEVEL}
            elif [[ ${TYPE} == 'bone' ]]; then
                BONELEVEL=${LEVEL}
            else
                echo "Error assigning level values"; exit ${EXIT_BUG}
            fi
            ;;
        1) # No file
                ${TYPE}_feature
                if [[ ! -f ${PATIENTPATH}/${FILENAME}_${TYPE}_${LEVEL}_lvlset.vti ]] ; then
                    . message_display.sh    "Create the feature correction now.  Select \"isosurface\"'\n'
                                            for the segmentation method and enter the value you have'\n'
                                            previously decided upon. Evolve at 300 0 0 1."
                    vmtklevelsetsegmentation -ifile ${PATIENTPATH}/${FILENAME}.vti -ofeatureimagefile ${PATIENTPATH}/${FILENAME}_${TYPE}_${LEVEL}.vti -ofile ${PATIENTPATH}/${FILENAME}_${TYPE}_${LEVEL}_lvlset.vti
                    vmtkimagefeaturecorrection -ifile ${PATIENTPATH}/${FILENAME}_${TYPE}_${LEVEL}.vti -levelsetsfile ${PATIENTPATH}/${FILENAME}_${TYPE}_${LEVEL}_lvlset.vti -scalefrominput 0 -ofile ${PATIENTPATH}/${FILENAME}_${TYPE}_sigmoid.vti
                fi ;;
    esac
}

function image_feature {
    vmtkimagecompose -ifile ${PATIENTPATH}/${FILENAME}_bone_${BONELEVEL}_lvlset.vti -i2file ${PATIENTPATH}/${FILENAME}_air_${AIRLEVEL}_lvlset.vti -negatei2 1 -ofile ${PATIENTPATH}/${FILENAME}_both_lvlset.vti
    vmtkimagefeaturecorrection -ifile ${PATIENTPATH}/${FILENAME}_bone_${BONELEVEL}.vti -levelsetsfile ${PATIENTPATH}/${FILENAME}_both_lvlset.vti -scalefrominput 0 -ofile ${PATIENTPATH}/${FILENAME}_both_sigmoid.vti
}

function segment {
    if [[ -f ${PATIENTPATH}/${NEWFILENAME}_initial.vti ]] ; then # IS initial file
        if [[ ! -f ${PATIENTPATH}/${FILENAME}_bone_sigmoid.vti && ! -f ${PATIENTPATH}/${FILENAME}_air_sigmoid.vti ]] ; then # NO sigmoid file
            vmtklevelsetsegmentation -ifile ${PATIENTPATH}/${FILENAME}.vti -initiallevelsetsfile ${PATIENTPATH}/${NEWFILENAME}_initial.vti -ofile ${PATIENTPATH}/${NEWFILENAME}_segm.vti
        else # IS initial & has sigmoid(s)
            if [[ -f ${PATIENTPATH}/${FILENAME}_bone_sigmoid.vti && -f ${PATIENTPATH}/${FILENAME}_air_sigmoid.vti ]] ; then
                if [[ ! $AIRLEVEL == "" && ! $BONELEVEL == "" ]]; then
                    image_feature
                    . message_display.sh "Both air and bone corrections detected" ; LEVELTYPE="both"
                fi
            else
                if [[ -f ${PATIENTPATH}/${FILENAME}_bone_sigmoid.vti ]] ; then
                    . message_display.sh "Only bone correction detected" ; LEVELTYPE="bone"
                else
                    . message_display.sh "Only air correction detected" ; LEVELTYPE="air"
                fi
            fi
            vmtklevelsetsegmentation -ifile ${PATIENTPATH}/${FILENAME}.vti -featureimagefile ${PATIENTPATH}/${FILENAME}_${LEVELTYPE}_sigmoid.vti -initiallevelsetsfile ${PATIENTPATH}/${NEWFILENAME}_initial.vti -ofile ${PATIENTPATH}/${NEWFILENAME}_segm.vti
        fi
    else # NO initial file
         if [[  ! -f ${PATIENTPATH}/${FILENAME}_bone_sigmoid.vti && ! -f ${PATIENTPATH}/${FILENAME}_air_sigmoid.vti ]] ; then # NO sigmoid file
            vmtkimageinitialization -ifile ${PATIENTPATH}/${FILENAME}.vti -olevelsetsfile ${PATIENTPATH}/${NEWFILENAME}_initial.vti
            vmtklevelsetsegmentation -ifile ${PATIENTPATH}/${FILENAME}.vti -initiallevelsetsfile ${PATIENTPATH}/${NEWFILENAME}_initial.vti -ofile ${PATIENTPATH}/${NEWFILENAME}_segm.vti
        else # NO initial & has sigmoid(s)
            if [[ -f ${PATIENTPATH}/${FILENAME}_bone_sigmoid.vti && -f ${PATIENTPATH}/${FILENAME}_air_sigmoid.vti ]] ; then
                image_feature
                . message_display.sh "Both air and bone corrections detected" ; LEVELTYPE="both"
            else
                if [[ -f ${PATIENTPATH}/${FILENAME}_bone_sigmoid.vti ]] ; then
                    . message_display.sh "Only bone correction detected" ; LEVELTYPE="bone"
                else
                    . message_display.sh "Only air correction detected" ; LEVELTYPE="air"
                fi
            fi
            vmtkimageinitialization -ifile ${PATIENTPATH}/${FILENAME}.vti -olevelsetsfile ${PATIENTPATH}/${NEWFILENAME}_initial.vti
            vmtklevelsetsegmentation -ifile ${PATIENTPATH}/${FILENAME}.vti -initiallevelsetsfile ${PATIENTPATH}/${NEWFILENAME}_initial.vti -featureimagefile ${PATIENTPATH}/${FILENAME}_${LEVELTYPE}_sigmoid.vti -ofile ${PATIENTPATH}/${NEWFILENAME}_segm.vti
        fi
    fi
    REPLY=""
    . message_display.sh    "Please record the evolution smoothing parameters
                            you used and the vessels they were applied to:
                            Type \"q\" or \"Q\" to quit"
    while [[ ! $REPLY == "q" && ! $REPLY == "Q" ]]; do
        read ;
        if  [[ ! $REPLY == "q" && ! $REPLY == "Q" ]]; then
            echo "Level set evolution parameters for ${NEWFILENAME}: ${REPLY} on " `date` 1>>${PATIENTPATH}/params${ANEURYSM_NUM}
        fi
    done
}

function combine {
    VESSEL=`zenity --file-selection --filename=$PATIENTPATH/ --title="${TITLE}: Select vessel file"`; VESSEL=${VESSEL%%'.vti'}
    ANEURYSM=`zenity --file-selection --filename=$PATIENTPATH/ --title="${TITLE}: Select aneurysm file"`; ANEURYSM=${ANEURYSM%%'.vti'}
    vmtkimagecompose -ifile ${VESSEL}.vti -i2file ${ANEURYSM}.vti -operation min -ofile ${PATIENTPATH}/${FILENAME}_combined_segm.vti --pipe vmtkmarchingcubes -i @vmtkimagecompose.o --pipe vmtksurfaceviewer
    vmtkimagereslice -spacing 0.25 0.25 0.25 -ifile ${VESSEL}.vti -ofile ${VESSEL}_sub.vti
    vmtkimagereslice -spacing 0.25 0.25 0.25 -ifile ${ANEURYSM}.vti -ofile ${ANEURYSM}_sub.vti
    YESNO=1
    while [[ ! $YESNO == 0 ]] ; do
        SHIFT=`zenity --entry --title="${TITLE}" --width=$WIDTH --text="Enter the value to shrink (0-1)"`
        case $? in
            0)
                vmtkimageshiftscale -ifile ${VESSEL}_sub.vti -shift $SHIFT -ofile ${VESSEL}_sub_shrinked.vti
                vmtkimageshiftscale -ifile ${ANEURYSM}_sub.vti -shift $SHIFT -ofile ${ANEURYSM}_sub_shrinked.vti
                vmtkimagecompose -ifile ${VESSEL}_sub_shrinked.vti -i2file ${ANEURYSM}_sub_shrinked.vti -operation min -ofile ${PATIENTPATH}/${FILENAME}_combined_segm.vti  --pipe vmtkmarchingcubes -i @vmtkimagecompose.o --pipe vmtksurfaceviewer
                zenity --question --title="$TITLE" --text="Is this satisfactory?" --ok-label="_Yes" --cancel-label="_No"
                YESNO=$?;;
         -1|1)
                . quit.sh ;;
            *)
                ;;
        esac
    done
    echo "Shift scale value is ${SHIFT} for ${FILENAME}_segm.vtp on " `date` 1>>${PATIENTPATH}/params${ANEURYSM_NUM}
}
###########################################################################
#                         main program                                    #
###########################################################################
# the options -h for help should always be present. Options -v and
# -o are examples. -o needs a parameter, indicated by the colon ":"
# following in the getopts call
while getopts ':o:vh' OPTION ; do
    case ${OPTION} in
        v)  VERBOSE=y ;;
        o)  OPTFOLDER="${OPTARG}" ;;
        i)  INITIAL=y ;; #This is the first segmentation and the dicom folder needs read
        h)  usage ${EXIT_SUCCESS} ;;
       \?)  echo "unknown option \"-${OPTARG}\"." >&2 ; usage ${EXIT_ERROR} ;;
        :)  echo "option \"-${OPTARG}\" requires an argument." >&2 ; usage ${EXIT_ERROR} ;;
        *)  echo "Impossible error. parameter: ${OPTION}" >&2 ; usage ${EXIT_BUG} ;;
    esac
done
# skip parsed options
shift $(( OPTIND - 1 ))
# if you want to check for a minimum or maximum number of arguments, do it here
if [[ $# -lt $NUMOFPARAMS ]] ; then
    echo 'Wrong number of parameters' >&2
    usage ${EXIT_ERROR} ; exit
fi
# loop through all arguments
for ARG ; do
    if [[ ${VERBOSE} = y ]] ; then
        echo -n 'argument: '
    fi
    echo ${ARG}
done
    # Needed on BIOMOST000
    #export PYTHONPATH=/usr/css/opt/vmtk-0.8/lib:/usr/css/opt/vmtk-0.8/lib/vmtk:/usr/css/opt/vtk-5.4.2/lib64/python2.6/site-packages
    #export LD_LIBRARY_PATH=/usr/css/opt/vtk-5.4.2/lib/vtk-5.4:/usr/css/opt/InsightToolkit-3.16.0/lib/InsightToolkit:/usr/css/opt/vmtk-0.8/lib:/usr/css/opt/vmtk-0.8/lib/vmtk
NOW=`date`
xhost +local:$USER
###########################################################################
#   The filename is used as a description of the content of the file so   #
#   we carefully construct the filename based on the patient number, the  #
#   aneurysm location, the stage of segmentation, and possibly the user   #
#   and date.                                                             #
#   The function 'get_patient_path.sh' prompts the user to enter the      #
#   patient number and returns the global variables PATIENT_NUM &         #
#   PATIENTPATH.                                                          #
#   'aneurysm_num.sh' has user select the location and side of the        #
#   aneurysm and appends that to the filename.  The aneurysms are numbered#
#   by alphabetical order.  Users should segment in that order to maintain#
#   file coherence.                                                       #
#   'get_dicom_path.sh' loads the dicom data IF IT HAS NOT ALREADY BEEN   #
#   READ- the function seaches for a file named "..._all.vti" and if not  #
#   present, it produces it.                                              #
###########################################################################
. get_patient_path.sh; FILENAME=$PATIENT_NUM; debug $FILENAME
. aneurysm_num.sh
. get_dicom_path.sh
###########################################################################
#  For multiple aneurysms, loop the script to do them all in one session  #
#  This is the master control of the program: it controls the flow of the #
#  script and makes branching between tasks easier to follow and edit.    #
###########################################################################
COUNT=1
while [[ $COUNT -le $ANEURYSM_NUM ]] ; do
# Loop following code or ask to select which to do
    FILENAME="${PATIENT_NUM}_${COUNT}"; debug $FILENAME
    interest_volume # Create a volume of interest for this anatomy
    zenity --width=$WIDTH --title="${TITLE}" --question --text="Would you like to segment this VOI?" --ok-label="_Yes" --cancel-label="_No"
    case $? in
        0)  # If yes, are there air or bone corrections needed?
            TYPE="air"; create_sigmoid $TYPE;
            TYPE="bone"; create_sigmoid $TYPE;
            for NEWFILENAME in "${FILENAME}_vessel" "${FILENAME}_aneurysm"; do #Sets NEWFILENAME variable during loop
                debug $NEWFILENAME
                if [[ -f ${PATIENTPATH}/${NEWFILENAME}_segm.vti ]]; then # This has a previous completed segmentation
                    zenity --width=$WIDTH --title="${TITLE}" --question --text="Would you like to use the existing segmented model\n for $NEWFILENAME?" --ok-label="_Yes" --cancel-label="_No"
                    case $? in
                        0)
                            . message_display.sh "Examine this previous model for ommissions. Type \"q\" in render window to proceed"
                            vmtkimagereader -ifile ${PATIENTPATH}/${NEWFILENAME}_segm.vti --pipe vmtkmarchingcubes -l 0.0 --pipe vmtkrenderer --pipe vmtkimagereader -ifile ${PATIENTPATH}/${FILENAME}.vti --pipe vmtkimageviewer --pipe vmtksurfaceviewer # Show model to user and proceed
                            ;;
                        1)
                            segment # If there is a previous model but we want to make a new one...
                            ;;
                    esac
                else
                    segment # If there is no previous model, make one...
                fi
            done
            combine
            ;;
   -1 | 1)
            ;; # No, do nothing
    esac
    zenity --width=$WIDTH --title="${TITLE}" --question --text="Would you like to mesh a segmentation?" --ok-label="_Yes" --cancel-label="_No"
    case $? in
        0)
            . reconstruct.sh ;;
        *)  # We either don't want to mesh OR we only have a VOI and no surface
            ;;
    esac
    if [[ ${FILENAME} == *CoW* ]] ; then
        echo "Renaming CoW files"
        for ii in `find . -name "CoW" -type f`; do
            mv $ii "${ii%"_${COUNT}_"*}_${ii##*"_${COUNT}_"}"
        done
        COUNT=${COUNT}; # Don't advance the count for CoW
    else
        COUNT=${COUNT}+1;
    fi
    FILENAME=$PATIENT_NUM; debug $FILENAME # Reset the filename
done
exit ${EXIT_SUCCESS}
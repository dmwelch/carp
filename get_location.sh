#!/bin/bash

function get_side {
        `zenity --question --width=150 --title="VOI Orientation" --text="Which side of the patient is it on?" --ok-label="_Right" --cancel-label="_Left"` # Potential bug: Clicking "Close" will signal a choice of "Right"
        case $? in
                0)  FILENAME=${FILENAME}_right ;;
                1)  FILENAME=${FILENAME}_left ;;
               -1)  echo "Exiting..." ; . quit.sh;;
        esac
}

function userGUI {
        CHOICE1=`zenity --list --width=500 --height=400 --title="${TITLE}: Aneurysm Location" --list --radiolist --column="Aneurysms" --column="Location" --column="Code" --hide-column=3 FALSE "Anterior Cerebral Artery" 1 FALSE "Anterior Communicating Artery" 2 FALSE "Basilar" 3 FALSE "Circle of Willis" 4 FALSE "Interior Carotid Artery" 5 FALSE "Middle Cerebral Artery" 6 FALSE "Ophthalmic Artery" 7 FALSE "Posterior Cerebral Artery" 8 FALSE "Posterior Communicating Artery" 9 FALSE "Other" 10 --print-column 3 `

        case $? in
                0)  ;;
           -1 | 1)  echo "Exiting..." ; . quit.sh;;
        esac

        case $CHOICE1 in
                1)  FILENAME=${FILENAME}_ACA   ; get_side;;
                2)  FILENAME=${FILENAME}_AComm ;; # No 'side'
                3)  FILENAME=${FILENAME}_Bslar ;; # No 'side'
                4)  FILENAME=${FILENAME%%'_'*}_CoW  ;; # No 'side' and remove the numeral
                5)  FILENAME=${FILENAME}_ICA   ; get_side;;
                6)  FILENAME=${FILENAME}_MCA   ; get_side;;
                7)  FILENAME=${FILENAME}_Ophth ; get_side;;
                8)  FILENAME=${FILENAME}_PCA   ; get_side;;
                9)  FILENAME=${FILENAME}_PComm ; get_side;;
               10)  LOCATION=`zenity --entry --title="${TITLE}" --text="Enter VOI location:" --entry-text "location"`
		    case $? in
			     0)  FILENAME=${FILENAME}_${LOCATION} ;;
			-1 | 1)  echo "No location entered" ; . get_location.sh ;;
		    esac
		    ;;
        esac
}
###########################################################################
#                                                                                                                                                                                       #
#                                                                       main program                                                                                              #
#                                                                                                                                                                                       #
###########################################################################
if [ -e "${PICPATH}/${PICFILE}" ] ; then
        ( `eog -f "${PICPATH}/${PICFILE}"` | userGUI ) # Displays help image simultaneously with zenity GUI
        wait # Do not proceed until picture is closed
else
        userGUI
fi
zenity --width=$WIDTH --title="${TITLE}" --info --text='Selecting VOI.  Press "i" to initiate VOI selector.'
vmtkimagevoiselector -ifile ${PATIENTPATH}/${PATIENT_NUM}_all.vti -ofile ${PATIENTPATH}/${FILENAME}.vti --pipe vmtkimagemipviewer -display 0 -ofile ${PATIENTPATH}/${FILENAME}_mip.vti # Set display to 1 to show MIPS during runtime

if [[ $DEBUGFILENAMES -eq 0 ]] ; then
        echo "${DEBUGCOUNT} -> ${FILENAME}" ; DEBUGCOUNT=$(( ${DEBUGCOUNT} + 1 ))
fi
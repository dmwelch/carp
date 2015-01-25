#!/bin/bash
#function get_patient_path
PATIENT_NUM=0
########################################################################
if [[ $TITLE = "" ]] ; then
        TITLE="Patient Data"
fi
PATIENTPATH=`zenity --file-selection --directory --title="${TITLE}: Select destination folder" --filename="/media/"`
case $? in
        0)      ;;
        1)      echo "No path selected."
                . quit.sh ;;
       -1)      echo 'Zenity has caused an error!' # Something happened with zenity
                exit ${EXIT_ERROR} ;;
        *)      echo $? ; exit ${EXIT_BUG}
esac

while [[ $PATIENT_NUM -lt 1001 || $PATIENT_NUM -ge 4000 || $PATIENT_NUM%1000 -eq 0 ]] ; do # -.10 will break out of the while loop!  Need to investigate!
       if [[ $PATIENT_NUM == Train* || $PATIENT_NUM == test ]]; then # If this is a training set, name the files Train...
            break
       fi
       PATIENT_NUM=`zenity --entry --title="${TITLE}" --width=200 --text="Enter the patient ID _number:" --entry-text "####"`
        case $? in
	        0)      ;;
		1)      echo "No patient number given."
                        . quit.sh ;;
               -1)      echo 'Zenity has caused an error!' # Something happened with zenity
		        exit ${EXIT_ERROR} ;;
                *)      echo $? ; exit ${EXIT_BUG}
	esac
done

#!/bin/bash

PATIENTPATH=~/BIOMOST/VasMechLab/NIH/initial/1005/CD1
PATIENT_NUM=1005
DICOMPATH=$PATIENTPATH/Jul_02_2008/0781/0787/Series3/

if [[ ! -e ${PATIENTPATH}/${PATIENT_NUM}_all.vti && $DICOMPATH == "" ]] ; then
        DICOMPATH=`zenity --filename="${PATIENTPATH}" --file-selection --directory --title="${TITLE}: Select dicom folder (in \"DICOM\" if it exists)"`
                case $? in
                        0)      ;;
                        1)      echo "No file selected. Exiting..." ; . quit.sh ;;
                       -1)      echo 'Zenity has caused an error!' # Something happened with zenity
                                 exit ${EXIT_ERROR} ;;
                        *)      echo $? ; exit ${EXIT_BUG} ;;
                esac
fi
echo "MADE IT HERE!"

for jj in `ls $DICOMPATH` ; do
        #DUMP=`basename $jj`
	echo $jj
        #echo ${jj} 1> ${PATIENTPATH}/${DUMP}dump.txt
        
        case $? in
                0)
                        gdcmraw -i ${DICOMPATH}/${jj} -o ${PATIENTPATH}/temp.txt -t 0008,0060 2>${PATIENTPATH}/temp.txt 
			MODALITY=`cat ${PATIENTPATH}/temp.txt`
        
                        if [[ ${MODALITY} == *DERIVED* ]] ; then
                                break #Skip processing this file and move to another
                        fi 
                        # For ToF, sometimes it is not explicitly given
                        if [[ $MODALITY == MR ]] ; then
				gdcmraw -i ${DICOMPATH}/${jj} -o ${PATIENTPATH}/temp.txt -t 0040,0254 2>${PATIENTPATH}/temp.txt 
                                ISTOF=`cat ${PATIENTPATH}/temp.txt`
                                if [[ $ISTOF = *[MRA*W/O*CONTRAST]* ]] ; then
                                        MODALITY=MRToF ; echo "Modality is >>>>> $MODALITY"
                                        break ; break ; break
                                fi
                        fi
			echo "Modality >>> $MODALITY"
                       	rm ${PATIENTPATH}/temp.txt
                        ;;
                *)     # gdcmraw fails
                        CHOICE1=`zenity --list --width=150 --height=300 --title="Choose modality" --radiolist --column="Type" --column="Modality" FALSE DSA FALSE CT FALSE CTA FALSE MR FALSE MRA FALSE MRToF FALSE Other --print-column 2`
                        case $? in
                                0)      ;;
                          -1 | 1)      echo "Exiting..." ; . quit.sh;;
                        esac
                        
                        case $CHOICE1 in
                                "DSA")          
                                                zenity --error --text='Not enough dimensions!  Exiting now' ; exit ${EXIT_FAILURE} ;; # DSA
                        "CT" | "MR")      
                                                zenity --error --text='Modality needs contrast!  Exiting now' ; exit ${EXIT_FAILURE} ;; # CT or MR
                                "CTA")      
						MODALITY=CTA ;;
                                "MRA")      
						MODALITY=MRA ;;
                             "MRToF")
						MODALITY=MRToF ;;
                                "Other")     
                                                zenity --error --text='Unknown modality!  Exiting now.' ;  exit ${EXIT_FAILURE} ;;
                        esac  
                        ;;
        esac
done

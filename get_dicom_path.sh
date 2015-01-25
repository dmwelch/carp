#!/bin/bash

if [[ ! -f ${PATIENTPATH}/${PATIENT_NUM}_all.vti ]] ; then # If dicom folder hasn't been created as .vti
    `mipav -inputDIR $PATIENTPATH`
    DICOMPATH=`zenity --filename="${PATIENTPATH}/*" --file-selection --directory --title="${TITLE}: Select dicom folder"`
    case $? in
        0)
            echo $DICOMPATH ;;
        1)
            echo "No file selected. Exiting..." ; . quit.sh ;;
       -1)
            echo 'Zenity has caused an error!' # Something happened with zenity
            exit ${EXIT_ERROR} ;;
        *)
            echo $? ; exit ${EXIT_BUG} ;;
    esac

    if [[ ! -f ${PATIENTPATH}/DICOMDIR ]] ; then
            `gdcmgendir -r -i ${DICOMPATH} -o ${PATIENTPATH}DICOMDIR 2>/dev/null`
            case $? in
                    0)
                        ;;
                    *)
                        for j in `ls ${DICOMPATH}/*`; do
                            `gdcmconv -V --raw --force -i $j -o ${PATIENTPATH}/DICOM/$j 2>/dev/null`
                            if [[ $? -ne 0 ]] ; then
                                break
                            fi
                        done
                        `gdcmgendir -r -i ${PATIENTPATH}/DICOM -o ${PATIENTPATH}DICOMDIR 2>/dev/null`
                        case $? in
                            0)
                                DICOMPATH="${PATIENTPATH}/DICOM" ;;
                            *)
                                echo "Could not create DICOMDIR" #Failed twice to create DICOMDIR file
                                rm -rf ${PATIENTPATH}/DICOM ;; # Remove DICOM folder created above
                        esac ;;
            esac
    fi

        vmtkimagereader -f dicom -d $DICOMPATH --pipe vmtkimagewriter -ofile ${PATIENTPATH}/${FILENAME}_all.vti
fi

#!/bin/bash
. get_patient_path.sh

VESSEL=`zenity --file-selection --filename="${PATIENTPATH}/" --title="${TITLE}: Select vessel file"`
ANEURYSM=`zenity --file-selection --filename="${PATIENTPATH}/" --title="${TITLE}: Select aneurysm file"`

VESSEL=${VESSEL%%'.vti'} ; ANEURYSM=${ANEURYSM%%'.vti'}; FILENAME=${VESSEL%%'_vessel.vti'}

vmtkimagecompose -ifile ${VESSEL}.vti -i2file $ANEURYSM.vti -operation min -ofile ${FILENAME}_segm.vti
vmtkimagereslice -spacing 0.25 0.25 0.25 -ifile ${VESSEL}.vti -ofile ${VESSEL}_sub.vti
vmtkimagereslice -spacing 0.25 0.25 0.25 -ifile ${ANEURYSM}.vti -ofile ${ANEURYSM}_sub.vti

YESNO=1
while [[ ! $YESNO == 0 ]] ; do
    SHIFT=`zenity --entry --title="${TITLE}" --text="Enter the value to shrink"`

    vmtkimageshiftscale -ifile ${VESSEL}_sub.vti -shift ${SHIFT} -ofile ${VESSEL}_sub_shrinked.vti
    vmtkimageshiftscale -ifile ${ANEURYSM}_sub.vti -shift ${SHIFT} -ofile ${ANEURYSM}_sub_shrinked.vti

    vmtkimagecompose -ifile ${VESSEL}_sub_shrinked.vti -i2file ${ANEURYSM}_sub_shrinked.vti -operation min -ofile ${FILENAME}_segm.vti  --pipe vmtkmarchingcubes -i @vmtkimagecompose.o --pipe vmtksurfaceviewer
    
    `zenity --question --title="$TITLE" --text="Is this satisfactory?" --ok-label="_Yes" --cancel-label="_No"`
    YESNO=$?
done
echo "Shift scale value is ${SHIFT} for ${FILENAME}_segm.vtp\n $DATE" 1< ${PATIENTPATH}/shiftscale.txt

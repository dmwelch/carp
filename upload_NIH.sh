#!/bin/bash
############################################################################
# Script:	upload_NIH.sh                                              #
# Task:	To have user select dataset from patient CD, copy selecetd data to #
#		server, and output DICOM technical information to database #
#		spreadsheet                                                #
# Requires:     get_patient_path.sh, quit.sh                               #
#		zenity                                                     #
#               GDCM                                                       #
#               OpenOffice                                                 #
#		MIPAV Dicom Viewer                                         #
############################################################################

############################################################################
#                                                                          #
#                         global variables                                 #
#                                                                          #
############################################################################

SCRIPTNAME=$(basename ${0} .sh)
TITLE="BioMOST NIH"
WIDTH=325
# Number of parameters needed (Edit line 55 logic)
NUMOFPARAMS=0
# exit status definitions
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10
# variables for option switches with default values
VERBOSE="n"
OPTFOLDER=""
#variables for this application
PATIENTPATH=""
PATIENT_NUM=""
HPTID=""
# MIPAVPATH="/root/mipav" Unneeded on BIOMOST
DICOMDIR=""
GETDICOMDIR=1
SERVERPATH="${HOME}/BIOMOST/VasMechLab/NIH"
COPYFOLDERS=""
NOW=""
############################################################################
#                                                                          #
#                             functions                                    #
#                                                                          #
############################################################################
function usage {
	echo "Usage: ${SCRIPTNAME} [-h] [-v] [-o arg] file ..." >&2
	[[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

function quit {
	echo 'Application terminated by user' ; exit ${EXIT_SUCCESS}
}

function read_media {
	# Get patient ID and CD number
	CDNUM=`zenity --list --title="${TITLE}: What CD number is this?" --list --radiolist --column="" --column="CD Number" TRUE 1 FALSE 2 FALSE 3 FALSE 4 FALSE 5 --print-column 2`

	zenity --question --text="What patient scan is this?" --ok-label="Interest" --cancel-label="Archival"
	case $? in
		0) 	TEMP="${SERVERPATH}/initial/${PATIENT_NUM}"
			copy_files ${PATIENT_PATH}
			database_info ${TEMP}/CD${CDNUM}/ # Yes, this is initial
			TEMP="${SERVERPATH}/followup/${PATIENT_NUM}"
			copy_CD ;;

		1) 	TEMP="${SERVERPATH}/followup/${PATIENT_NUM}"
			copy_CD ;; # No, this is a follow up

		*) 	echo "Terminating process" ; exit ${EXIT_ERROR} ;; # Something went wrong
	esac

}

function copy_files {

	echo "*****Making files******"
	mkdir -vpm 777 ${TEMP}/CD${CDNUM} # make directory and parents as needed

	( `zenity --info --title="${TITLE}" --text="In MIPAV, do the following:\n1) File->DICOM->DICOMDIR Browser (if it exists)\n\n2) File->DICOM->DICOM Browser\n\n3) Select interest images in DICOM Browser\n\n4) Create AVI file named Series# and save to ${TEMP}/CD$CDNUM"` | `mipav -inputdir "${PATIENTPATH}"` )

	DICOMDIRFILE=`find $PATIENTPATH -name DICOMDIR -type f` #; echo "DICOMDIR -> ${DICOMDIR}"
	if [[ $DICOMDIRFILE = "" ]] ; then # No dicomdir found

		gdcmgendir -r -i ${PATIENTPATH} -o ${TEMP}/CD${CDNUM}/DICOMDIR
		case $? in
			0)  echo "DICOMDIR created by Grassroots DICOM on $NOW by $USER" 1>${TEMP}/CD${CDNUM}/dicomdir.txt ;;
			1)  echo "DICOMDIR could NOT be created by Grassroots DICOM on $NOW by $USER" 1>${TEMP}/CD${CDNUM}/dicomdir.txt ;;
		esac

	else
		 rsync $DICOMDIRFILE ${TEMP}/CD${CDNUM}/DICOMDIR
	fi

	# The problem here is that when we copy read-only file tree to the server, it remains read-only and the copy biffs it trying to write more files into a read-only system.  We need to create the file tree, making each level write-enabled and THEN copy the files over.
	INITIALSCANS=0
	while [[ $INITIALSCANS = 0 ]] ; do
		COPYFOLDER=`zenity --file-selection --directory --title="${TITLE}: Select ONE DICOM folder to copy" --filename="${PATIENTPATH}/"`
		case $? in
			0)
				echo "*****Making files******"
				echo $COPYFOLDER
				SERVERCD="${TEMP}/CD${CDNUM}/${COPYFOLDER##*'/media/'}" ; echo $SERVERCD
				mkdir -vpm 777 ${SERVERCD}
				# Copy all the files in this folder and output errors to a file
				rsync -r $COPYFOLDER/* ${SERVERCD} 2>${TEMP}/CD${CDNUM}/rsync_errors.txt
				echo "*********Done**********"
				SERIES0=0 # Initial series
				READFOLDER=$SERVERCD
				for jj in `ls -R ${SERVERCD}` ; do
					# echo "This is jj: "$jj
					if [[ ! -d $READFOLDER/$jj ]] ; then
						gdcmraw -i ${READFOLDER}/${jj} -o ${TEMP}/CD${CDNUM}/temp.txt -t 0008,0008
						IMAGETYPE=`cat ${TEMP}/CD${CDNUM}/temp.txt`
						gdcmraw -i ${READFOLDER}/${jj} -o ${TEMP}/CD${CDNUM}/temp.txt -t 0020,0011
						SERIES1=`cat ${TEMP}/CD${CDNUM}/temp.txt` #; echo $SERIES1
						#echo $jj $SERIES $IMAGETYPE
						if [[ $SERIES0 -ne $SERIES1 ]] ; then
						# we've encountered a new series
							if [[ ! -d ${READFOLDER}/Series${SERIES1} ]] ; then
								mkdir ${READFOLDER}/Series${SERIES1}
							fi
							mv ${READFOLDER}/${jj} ${READFOLDER}/Series${SERIES1}/${jj}
						fi
					else
						READFOLDER="$READFOLDER/$jj"
					fi
				done
				chmod 777 -R ${SERVERCD}
				echo "Data added on $NOW by $USER" 1> ${TEMP}/CD${CDNUM}/entry.txt
				;;

		   -1 | 1)  	zenity --error --text="No folder selected!"
				exit ${EXIT_FAILURE} ;;
		esac
		`zenity --question --text="Is there another folder you would like to select as an initial scan?" --ok-label="_Yes" --cancel-label="_No" --title=$TITLE`
		case $? in
			0)
				INITIALSCANS=0 ;; # Keep going
			*)
				INITIALSCANS=1 ;; # Break out
		esac
	done
}

function copy_CD {
	echo "*****Making files******"
	mkdir -vpm 777 ${TEMP}/CD${CDNUM} # make directory CD1, or CD2, etc. and parents as needed

	DICOMDIRFILE=`find $PATIENTPATH -name DICOMDIR -type f` # Look for the DICOMDIR file on the media
	if [[ ! -f $DICOMDIRFILE ]] ; then # No dicomdir found
		gdcmgendir -r -i ${PATIENTPATH} -o ${TEMP}/CD${CDNUM}/DICOMDIR # Try to generate one using GDCM
		case $? in
			0) # Success!
                echo "DICOMDIR created by Grassroots DICOM on $NOW by $USER" 1>${TEMP}/CD${CDNUM}/dicomdir.txt
			    GETDICOMDIR=0 ;;  # Set flag ON
			1)  # Failure :(
                echo "DICOMDIR could NOT be created by Grassroots DICOM on $NOW by $USER" 1>${TEMP}/CD${CDNUM}/dicomdir.txt
                GETDICOMDIR=1;;  # Set flag OFF
		esac
	else # Found a dicomdir file
		 rsync $DICOMDIRFILE ${TEMP}/CD${CDNUM}/DICOMDIR 2>${TEMP}/CD${CDNUM}/rsync_errors.txt # Copy to server
	fi
	COPYFOLDERS=`zenity --file-selection --multiple --directory --title="${TITLE}: Select DICOM folder(s) to copy" --filename="${PATIENTPATH}/"`
	case $? in
		0)
			(
			COUNT=0
			NUMOFFOLDERS= `ls -1 $COPYFOLDERS | wc -l`
			while [[ ! ${COPYFOLDERS} = ${COPYFOLDERS%'|'*} ]] ; do

				CURRENT=${COPYFOLDERS##*'|'}
				#echo "<-- $CURRENT"
				COPYFOLDERS=${COPYFOLDERS%'|'*}
				#echo "--> $COPYFOLDERS"
				mkdir -vpm 777 ${TEMP}/CD${CDNUM}/${CURRENT##*'/media/'}/
				rsync -r $CURRENT/* ${TEMP}/CD${CDNUM}/${PATIENTPATH##'/media/'}/${CURRENT##*"${PATIENTPATH}/"} 2>>${TEMP}/CD${CDNUM}/rsync_errors.txt
				echo "scale=2; (( $COUNT/$NUMOFFOLDERS ))" | bc
            done
			) # | ( zenity --progress --title="Processing DICOM Files" --text="Getting scan information..." --percentage=0 )
			# Copy the last folder in the set
			mkdir -vpm 777 ${TEMP}/CD${CDNUM}/${PATIENTPATH##'/media/'}/${COPYFOLDERS##*"${PATIENTPATH}/"}
			rsync -r $COPYFOLDERS/* ${TEMP}/CD${CDNUM}/${PATIENTPATH##'/media/'}/${COPYFOLDERS##*"${PATIENTPATH}/"} 2>>${TEMP}/CD${CDNUM}/rsync_errors.txt
			#echo ${TEMP}/CD${CDNUM}/${PATIENTPATH##'/media/'}/${COPYFOLDERS##*"${PATIENTPATH}/"}
			echo "*********Done**********"
			echo "Data added on $NOW by $USER" 1> ${TEMP}/CD${CDNUM}/entry.txt
			;;

	   -1 | 1)  	zenity --error --text="No folder selected!\nQuiting now..."
			exit ${EXIT_FAILURE} ;;
	esac

}

function database_info {
	SCANFOLDER=`zenity --file-selection --directory --title="${TITLE}: Select DICOM folder you want information on" --filename="${1}/"`
	case $? in
		0)  ;;
	   -1 | 1)  zenity --error --text="No folder selected!"
		exit ${EXIT_FAILURE};;
	esac
	echo ${SCANFOLDER} 1>${1}/dicomdump.txt
	echo "IMAGETYPE;PATIENT_NUM;HSPTL;HPTID;CDNUM;SCANFOLDER;ANGIO;MOD;PROCDATE;;SSPACE;STHICK;SRES;XPSPACE;YPSPACE;;;;ROWS;COLS;;;SERIES;;;ZPOS" 1> ${1}/scan.csv
	SERIES=0 # Initial series
    NUMOFFILES= `ls -1 $SCANFOLDER | wc -l`
    COUNT=0
	(
    for jj in `ls $SCANFOLDER` ; do
        let COUNT=$COUNT + 1
		gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0008,0008 2>${1}/temp.txt
		IMAGETYPE=`cat ${1}/temp.txt`
		gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0020,0011 2>${1}/temp.txt
		SERIES=`cat ${1}/temp.txt`
		if [[ $IMAGETYPE = *DERIVED* ]] ; then
			echo "File $jj is a derived image and is removed\n" 1>>${1}/dicomdump.txt
			rm ${SCANFOLDER}/${jj}
		else
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0008,0012 2>${1}/temp.txt
			CREDATE=`cat ${1}/temp.txt`
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0008,0060 2>${1}/temp.txt
			MOD=`cat ${1}/temp.txt`
			if [[ ${MOD} == *DERIVED* ]] ; then
                                break #Skip processing this file and move to another
                        fi
                        # For ToF, sometimes it is not explicitly given
                        if [[ $MOD == MR ]] ; then
				gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0040,0254 2>${1}/temp.txt
                                ISTOF=`cat ${1}/temp.txt`
                                if [[ $ISTOF = *[MRA*W/O*CONTRAST]* ]] ; then
                                        MOD=MRToF ; echo "Modality is >>>>> $MOD"
                                fi
                        fi
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0018,0015 2>${1}/temp.txt
			ANAT=`cat ${1}/temp.txt`
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0018,0025 2>${1}/temp.txt
			ANGIO=`cat ${1}/temp.txt`
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0018,0050 2>${1}/temp.txt
			STHICK=`cat ${1}/temp.txt`
                        if [[ $STHICK = Cannot* ]] ; then # No thickness information found (helical CT)
                                STHICK="Not found"
                        fi
            gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0020,0032 2>${1}/temp.txt # For helical CT, slice spacing and thickness need to be explicitly computed from patient position
            PATPOS=`cat ${1}/temp.txt`
            ZPOS=${PATPOS##*'\'}
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0028,0010 2>${1}/temp.txt
			ROWS=`cat ${1}/temp.txt`
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0028,0011 2>${1}/temp.txt
			COLS=`cat ${1}/temp.txt`
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0028,0030 2>${1}/temp.txt
			PSPACE=`cat ${1}/temp.txt`
			XPSPACE=${PSPACE%%'\'*} ; YPSPACE=${PSPACE##*'\'}
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0028,0106 2>${1}/temp.txt
			LOWPIX=`cat ${1}/temp.txt`
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0028,0107 2>${1}/temp.txt
			HIGHPIX=`cat ${1}/temp.txt`
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0032,1060 2>${1}/temp.txt
			DESCRP=`cat ${1}/temp.txt`
                        if [[ $DESCRP = Cannot* ]] ; then # Description tag is not found
                               gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0008,1030 2>${1}/temp.txt
                               DESCRP=`cat ${1}/temp.txt`
                        fi
			gdcmraw -i ${SCANFOLDER}/${jj} -o ${1}/temp.txt -t 0040,0244 2>${1}/temp.txt
			PROCDATE=`cat ${1}/temp.txt`

			echo "$IMAGETYPE;$PATIENT_NUM;$HSPTL;$HPTID;$CDNUM;${SCANFOLDER};$ANGIO;$MOD;$PROCDATE;;$SSPACE;$STHICK;$SRES;$XPSPACE;$YPSPACE;;;;$ROWS;$COLS;;;$SERIES;;;$ZPOS" 1>> ${1}/scan.csv
		fi
        echo "scale=2; (( $COUNT/$NUMOFFILES ))" | bc
	done
    ) | ( zenity --progress --title="Processing DICOM Files" --text="Getting scan information..." --percentage=0 )
	echo ";$PATIENT_NUM;$HSPTL;$HPTID;$CDNUM;${SCANFOLDER};$ANGIO;$MOD;$PROCDATE;;$SSPACE;$STHICK;$SRES;$XPSPACE;$YPSPACE;;;;$ROWS;$COLS;;;$SERIES;;;" 1>> /nfs/drive00/local/vol00/d/dmwelch/BIOMOST/VasMechLab/NIH/info.csv
}

############################################################################
#                                                                          #
#                           main program                                   #
#                                                                          #
############################################################################

# the options -h for help should always be present. Options -v and
# -o are examples. -o needs a parameter, indicated by the colon ":"
# following in the getopts call
while getopts ':o:vh' OPTION ; do
        case ${OPTION} in
                v)  VERBOSE=y ;;
                o)  OPTFOLDER="${OPTARG}" ;;
                i)  INITIAL=y ;;
                h)  usage ${EXIT_SUCCESS} ;;
               \?)  echo "unknown option \"-${OPTARG}\"." >&2 ; usage ${EXIT_ERROR} ;;
                :)  echo "option \"-${OPTARG}\" requires an argument." >&2 ; usage ${EXIT_ERROR} ;;
                *)  echo "Impossible error. parameter: ${OPTION}" >&2 ; usage ${EXIT_BUG} ;;
        esac
done

# skip parsed options
shift $(( OPTIND - 1 ))

# if you want to check for a minimum or maximum number of arguments,
# do it here
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
NOW=`date`
WHEREAREYOU=$PWD

xhost +local:$USER  # Make zenity available to X

ifs=$IFS
IFS='
' # New divisor is 'newline'

. get_patient_path.sh
case $PATIENT_NUM in
	1[0-9][0-9][0-9])  HSPTL="TJH" ; HPTID=1 ;;
	3[0-9][0-9][0-9])  HSPTL="MGH" ; HPTID=2 ;;
	2[0-9][0-9][0-9])  HSPTL="PSU" ; HPTID=3 ;;
		         *)  echo "Error in hopital code"
		              exit ${EXIT_ERROR} ;;
esac

read_media

cd $WHEREAREYOU
IFS=$ifs

exit ${EXIT_SUCCESS}

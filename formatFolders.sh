#!/bin/bash
# Script to remove spaces from folder names
NUMOFPARAMS=2
FORMAT=""
REOPT=""
# exit status definitions
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

function usage {
    echo "Usage: ${0} [-h] [-s] [-c] [-b] [directory]" >&2
    echo "   -h   Displays this message"
    echo "   -s   Remove spaces and replace with underscores (recursive)"
    echo "   -c   Replace all capital letters with lowercase (recursive)"
    echo "   -b   Same as using both -s and -c"
    [[ ${#} -eq 1 ]] && exit ${1} || exit ${EXIT_FAILURE}
}

if [[ ! $# -eq $NUMOFPARAMS ]] ; then
        echo 'Wrong number of parameters' >&2
        usage ${EXIT_ERROR} ; exit
fi

while getopts 'csb' OPTION ; do
    case ${OPTION} in
        b)  FORMAT=3 # replace both spaces and caps
            ;;
        c)  FORMAT=2 # replace caps
            ;;
        s)  FORMAT=1 # replace spaces
            ;;
        h)  usage ${EXIT_SUCCESS}
            ;;
        \?) echo "unknown option \"-${OPTARG}\"." >&2
            usage ${EXIT_ERROR}
            ;;
        :)  echo "option \"-${OPTARG}\" requires an argument." >&2
            usage ${EXIT_ERROR}
            ;;
        *)  echo "Impossible error. parameter: ${OPTION}" >&2
            usage ${EXIT_BUG}
            ;;
    esac
done

if [ -n "$2" ]; then
  if [ -d "$2" ]; then
    cd "$2"
  else
    echo invalid directory
    exit
  fi
fi

for i in *; do
  OLDNAME="$i"
  case ${FORMAT} in
        1) NEWNAME=`echo "$i" | tr ' ' '_' | sed s/_-_/-/g`
            REOPT="s" # This is for the recursion
            ;;
        2) NEWNAME=`echo "$i"  | tr '[:upper:]' '[:lower:]' | sed s/_-_/-/g`
            REOPT="c" # This is for the recursion
            ;;
        3) NEWNAME=`echo "$i" | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | sed s/_-_/-/g`
            REOPT="b" # This is for the recursion
            ;;
  esac
  if [ "$NEWNAME" != "$OLDNAME" ]; then
    TMPNAME="$i"_tmp
    mv -v -- "$OLDNAME" "$NEWNAME"
    #echo mv -v -- "$TMPNAME" "$NEWNAME"
  fi
  
  if [ -d "$NEWNAME" ]; then
    echo Recursing lowercase for directory "$NEWNAME"
    $0 "-$REOPT" "$NEWNAME" # Recursion happens here
  fi
done
#!/bin/bash

ANEURYSM_NUM=`zenity --list --title="${TITLE}:How many aneurysms?" --list --radiolist --column="Aneurysms" --column="Number" TRUE 1 FALSE 2 FALSE 3 FALSE 4 FALSE 5 FALSE 6 FALSE 7 FALSE 8 FALSE 9 --print-column 2`
# Recursion loop needed for multiple aneurysm cases
case $? in
        0)      ;;
        1)      ANEURYSM_NUM=1 ;; # All patients have at least ONE aneurysm
        -1)      echo 'Zenity has caused an error!' # Something happened with zenity
                exit ${EXIT_ERROR} ;;
esac

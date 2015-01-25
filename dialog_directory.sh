#!/bin/sh
# Lists the contents of a directory
dialog --title "Dialog input box" \
   --inputbox "Input directory:" 8 40 `pwd`\
   2>/tmp/dialog.ans # default value can be changed at runtime using the backspace key to delete and regular letter keys to write. The final value is printed by dialog on STDERR. In order to use it from the shell script, it must first be redirected to a file.
if [ $? = 1 ]; then # if cancel...
   clear
   exit 0
fi
ANS=`cat /tmp/dialog.ans`
if 
ls -al $ANS > /tmp/dialog.ans
dialog --no-shadow \
   --title "listing of"$ANS \
   --textbox /tmp/dialog.ans 25 78
clear
rm -f /tmp/dialog.ans # don't litter !
exit 0

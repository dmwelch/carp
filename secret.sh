#!/bin/bash

#secret.sh

#Requirements:
# Zenity
# mkpasswd (?)
# python

#a script to open up a private folder, where permissions are
#set to "None", giving the logged in user and original owner of the folder
#read / write access.

#this works (under xubuntu and with thunar) when there are no other thunar
#windows open. Otherwise the permissions will be reset again - annoying.
#Would be good to know how to resolve this.

#this can work with any chosen password, it doesn't have to be a user,
#but the folder must be owned by the user.
#Use the command in the TESTPASS variable to generate hash strings, and
#youcan make up your own salt string

#please use your own hash string and salt string as these are examples only,
#for testing, the password is "blob" (no quotes), but may not give the same
#results on your machine?

#echoing of variables have been commented out, but uncomment them if you need to debug/test

################################################## ######################

#USER VARIABLES
#hash copied from /etc/shadow for "chosen user"
USERFILE='$6$C.mVN/YoHpZBiqXP$GixDRYVzGOHYbbk8QaufQphivYEH9vx9nWlF4aoPDpUczJ/hN/mL43YAbuNQURXHkR3D5nrNvIqqhR/63yqLe0'
#"the salt" - as you will see this is the set of characters between the second and third $ in the above string
USERSALT='C.mVN/YoHpZBiqXP'
#secret folder that the logged in user owns, change accordingly, use a ./hidden file for additional secrecy
SECRET='/etc/dansguardian'
#file manager choice, e.g nautilus, thunar, pcmanfm, mc. If you install a second file manager,
#you can use this instead of your normal one to access the secret folder
FM=/usr/bin/nautilus

#SCRIPT

#suggests closing all other file manager windows before running the script
zenity --info --title="Secret Folder Script" --text="You May Need To Close All Other File Manager Windows Before Proceeding"

#pops up a zenity dialog asking for your chosen users password
PASS=`zenity --entry --title="Secret Folder" --text="Enter your _password:" --entry-text "password" --hide-text`

#converts the plain text password given in the dialog to a sha-512 encrypted hash
TESTPASS=$(python -c "import crypt, getpass, pwd; print crypt.crypt('$PASS', '\$6\$"$USERSALT"\$')")

#echo "file manager $FM"
#echo "folder $SECRET"
#echo "pass $PASS"
#echo "salt $USERSALT"
#echo "hash $USERFILE"
#echo "testpass $TESTPASS"

#do the two hashes match?
if [ ! "$USERFILE" = "$TESTPASS" ]

then
#if they don't match, pop up a dialog to say you don 't have access
zenity --info --title="Secret Folder" --text="Sorry, No Access To Secret Folder"

else
#if they do match, give read / write permissions to your folder and ...
chmod -R 777 "$SECRET"
#open up the folder - change fm to thunar or nautilus or pcmanfm if that's what you use
"$FM" "$SECRET"

#when the fm window is closed, resets the permissions to "None"
#allow some sleep time to let thunar shut down
#echo "sleeping"
sleep 5
#echo "File Manager Closed"
#reset permissions
chmod -R 000 "$SECRET" 2>dev>null
#echo "Permissions Reset"

fi

################################################## ###################### 

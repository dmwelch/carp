!#/bin/bash/

echo 'Enter home dir:' # Do not end with a backslash
read home

echo 'Enter folder name:' # Do not begin with a backslash
read folder
NEWFOLDER="$home/$folder"
echo $NEWFOLDER '-> folder to create'

cd $home # Guarantees that home dir exists BEFORE creating folder
mkdir $folder

echo 'Done'
`cd $NEWFOLDER`

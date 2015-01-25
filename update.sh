!#/bin/bash
TOOL=""
echo "What toolkit would you like to update?"
select TOOL in "vmtk" "itk" "vtk"

BUILD="build-${TOOL}"
pushd "/usr/lib/${TOOL}"

echo `rm -rf ${TOOL}*`
if [[ $TOOL = vmtk ]] ; then
	`sudo svn co https://vmtk.svn.sourceforge.net/svnroot/vmtk vmtk`
fi

cd $BUILD
echo `rm -rf *`
`sudo ccmake ../${TOOL}`
`sudo make`
`sudo make install`


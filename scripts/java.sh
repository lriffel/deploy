#!/bin/bash

WorkingDir=$1
GIT_LOC=$2

function try {
    "$@"
    local status=$?
    
    if [ $status -ne 0 ]; then  
        echo "Error with command: $1 $2 $3 $4 $5" >&2 
        exit $status
    fi
    return $status
}


vCount=0
mkdir -p /home/oracle/testlib/
for vFile in `grep "\.jar" ${WorkingDir}/temp/allfiles.lst | grep "_JAVA"` ; do
	if [ $vCount == 0 ] ; then
		echo "Deploying Jar Files..."
	fi
	vCount=$((vCount+1))
	cp ${vFile} /home/oracle/testlib/.
	echo "Successfully placed ${GIT_LOC}/${vFile}."
done

vCount=0
for vFile in `grep "\.java" ${WorkingDir}/temp/allfiles.lst | grep "_JAVA"` ; do
   if [ $vCount == 0 ] ; then
      echo "Deploying Java..."
   fi
   vCount=$((vCount+1))
   cp ${vFile} ${WorkingDir}/temp/
   echo "Successful placed ${GIT_LOC}/${vFile}."
done

# The folder is specifically added here to the compile classpath so that a bounce of APPS
# doesn't have to happen until after the deployment completes.
if [ $vCount != 0 ] ; then
   try javac -d $JAVA_TOP -cp /home/oracle/testlib/*:$CLASSPATH ${WorkingDir}/temp/*.java
   try chmod -R 777 $JAVA_TOP/xx*
   rm -f ${WorkingDir}/temp/*.java
   echo "Deployed $vCount Java files."
fi

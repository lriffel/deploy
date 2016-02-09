#!/bin/bash
#Deploys Workflow

AppsPassword=$1
WorkingDir=$2
GIT_LOC=$3

function ProcessWFT {
   WFLOAD apps/$AppsPassword 0 Y $1 ${GIT_LOC}/${file}
   if [ "$?" = "0" ] ; then
      echo "Successful uploading ${file}."
   else
      echo "FAILED uploading ${file}."
   fi
   cat *.log
   rm -f *.log
}

#echo "Deploying Workflow."

for file in `grep "\.wft" ${WorkingDir}/temp/files.lst | grep "_WFT/UPLOAD"` ; do
   ProcessWFT UPLOAD
done

for file in `grep "\.wft" ${WorkingDir}/temp/files.lst | grep "_WFT/FORCE"` ; do
   ProcessWFT FORCE
done

for file in `grep "\.wft" ${WorkingDir}/temp/files.lst | grep "_WFT/UPGRADE"` ; do
   ProcessWFT UPGRADE
done

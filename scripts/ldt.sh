#!/bin/bash

AppsPassword=$1
WorkingDir=$2
GIT_LOC=$3

function ProcessLDT {
   echo "GIT_LOC: ${GIT_LOC}"
   LCT=`grep LDRCONFIG ${GIT_LOC}/${file} | cut -d'"' -f 2 | cut -d' ' -f 1`
   echo "LCT: $LCT"
   LCTPath="$FND_TOP/patch/115/import"
   if [ ! -f "$LCTPath/$LCT" ] ; then
      echo "LCT does not exist in FND_TOP, so we'll look elsewhere."
      LCTPath=`find $APPL_TOP -name $LCT -print -quit 2>/dev/null`
      LCTPath=`dirname $LCTPath`      
   fi 
   echo "FNDLOAD apps/XXXX O Y UPLOAD $LCTPath/$LCT ${GIT_LOC}/$file CUSTOM_MODE=FORCE"
   if [[ $file == *"upload_mode-replace"* ]] ; then
      FNDLOAD apps/$AppsPassword O Y UPLOAD $LCTPath/$LCT ${GIT_LOC}/$file CUSTOM_MODE=FORCE UPLOAD_MODE=REPLACE
   else
      FNDLOAD apps/$AppsPassword O Y UPLOAD $LCTPath/$LCT ${GIT_LOC}/$file CUSTOM_MODE=FORCE 
   fi
   if [ "$?" = "0" ] ; then
      echo "Successful uploading ${file}."
   else
      echo "FAILED uploading ${file}."
   fi
   cat *.log
   rm -f *.log
   echo "+===========================================================================+"
   echo
   echo
}

for file in `grep CP.ldt ${WorkingDir}/temp/files.lst` ; do
   ProcessLDT
done

for file in `grep RS.ldt ${WorkingDir}/temp/files.lst` ; do
   ProcessLDT
done

for file in `grep RG.ldt ${WorkingDir}/temp/files.lst` ; do
   ProcessLDT
done

for file in `grep "\.ldt" ${WorkingDir}/temp/files.lst | grep -v CP.ldt | grep -v RS.ldt | grep -v RG.ldt` ; do
   ProcessLDT
done

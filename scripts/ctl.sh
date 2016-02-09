#!/bin/bash

WorkingDir=$1
GIT_LOC=$2

for file in `grep "\\.ctl" ${WorkingDir}/temp/files.lst` ; do   
   if echo "$file" | grep -q "XXDC"; then
      mkdir -p $XXDC_TOP/bin/
      cp ${GIT_LOC}/${file} $XXDC_TOP/bin/
      if [ "$?" = "0" ] ; then
         echo "Successful placed ${GIT_LOC}/${file} in $XXDC_TOP/bin/."
      else
         echo "FAILED placing ${GIT_LOC}/${file} in $XXDC_TOP/bin/."
      fi
   else
      if echo "$file" | grep -q "XXCC"; then
         mkdir -p $XXCC_TOP/bin/
         cp ${GIT_LOC}/${file} $XXCC_TOP/bin/
         if [ "$?" = "0" ] ; then
            echo "Successful placed ${GIT_LOC}/${file} in $XXCC_TOP/bin/."
         else
            echo "FAILED placing ${GIT_LOC}/${file} in $XXCC_TOP/bin/."
         fi
      else
         echo "Failed moving ${GIT_LOC}/$file must be in XXCC/bin/ or XXDC/bin/."
      fi
   fi
done

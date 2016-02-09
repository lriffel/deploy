#!/bin/bash

WorkingDir=$1

function CopyAndCompile {
   GitLocation=$1
   Extension=$2
   CompileLocation=$3
   ModuleType=$4
   for file in `grep ${GitLocation} ${WorkingDir}/temp/allfiles.lst | grep .${Extension}` ; do
      if [ $vCount == 0 ] ; then
         echo "Deploying Libraries/Forms."
         mkdir -p ${XXDC_TOP}/forms/US/
         mkdir -p ${XXCC_TOP}/forms/US/
      fi

      cp -f ${file} ${CompileLocation}
      if [ "$?" = "0" ] ; then
         echo "Successful placed ${file}."
      else
         echo "FAILED placing ${file}."
      fi

      #Remove any old error log.
      rm -f ${CompileLocation}/`basename $file .${Extension}`.err
      
      echo "frmcmp_batch module=$CompileLocation/`basename ${file}` userid=apps/PASSWORD Module_type=${ModuleType} batch=yes compile_all=special"
      frmcmp_batch module=${CompileLocation}/`basename ${file}` userid=apps/`cat $HOME/scripts/secure/apps` Module_type=${ModuleType} batch=yes compile_all=special
      if [ "$?" = "0" ] ; then
         echo "Successful compiled ${file}."
      else
         echo "FAILED compiling ${file}.  Error log follows:"
         cat ${CompileLocation}/`basename $file .${Extension}`.err
      fi
      
      #List changed files.
      find ${CompileLocation}/* -maxdepth 1 -mtime -1 -printf %f-%c\\\n
   done
}


vCount=0
CopyAndCompile "_LIBRARIES" "pll" "${AU_TOP}/resource" "library"
CopyAndCompile "XXDC/forms" "fmb" "${XXDC_TOP}/forms/US" "form"
CopyAndCompile "XXCC/forms" "fmb" "${XXCC_TOP}/forms/US" "form"

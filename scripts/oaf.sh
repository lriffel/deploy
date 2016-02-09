#!/bin/bash

iWorkingDir=$1
iGitLoc=$2
iAppsPassword=$3

function try {
    "$@"
    local status=$?

    if [ $status -ne 0 ]; then
        echo "Error with command: $1 $2 $3 $4 $5" >&2
        exit $status
    fi
    return $status
}

function process {
   vFlavor=$1
   vCount=0

   if [[ $vFlavor == "Custom" ]] ; then
      vBasePath="cchs/oracle/apps"
   else
      vBasePath="oracle/apps"
   fi

   if [ $vCount == 0 ] ; then
      echo "Deploying ${vFlavor} OAF..."
   fi
   vCount=$((vCount+1))

   if [[ $vFlavor == "Custom" ]] ; then
      vSchema=`echo $vFile| cut -c 1-4| tr '[:upper:]' '[:lower:]'`
      vRemainder=`echo $vFile| cut -c 10-`
      vRemainder=${vSchema}/${vRemainder}
   else
      vRemainder=`echo $vFile| cut -c 14-`
   fi

   #Create Directory.
   vFileDst=${JAVA_TOP}/${vBasePath}/${vRemainder}
   vFileDir=$(dirname "${vFileDst}")
   mkdir -p ${vFileDir}
   #echo "Destination file: ${vFileDst}."
   #echo "Destination directory: ${vFileDst}."

   #Copy file.
   vFileSrc=${iGitLoc}/$vFile
   #echo "Source file: ${vFileSrc}."
   cp -f ${vFileSrc} ${vFileDst}
   echo "Successful placed ${vFileDst}."

   #Import xml files.
   if [[ $vFile == *"PG.xml" || $vFile == *"RN.xml" ]] ; then
      java oracle.jrad.tools.xml.importer.XMLImporter ${vFileDst} -username apps -password $iAppsPassword \
         -dbconnection "${AD_APPS_JDBC_URL}" -rootdir ${JAVA_TOP}
   fi

   #Save java files.
   if [[ $vFile == *".java" ]] ; then
      echo $vFileDst >> ${iWorkingDir}/temp/javafiles.txt
      vJavaCount=$((vJavaCount+1))
   fi
}

vJavaCount=0
for vFile in `grep -i "Standard/oaf/" ${iWorkingDir}/temp/allfiles.lst` ; do
   process "Standard"
done

for vFile in `grep -i "XX../oaf/" ${iWorkingDir}/temp/allfiles.lst` ; do
   process "Custom"
done

if [[ $vJavaCount != 0 ]] ; then
   echo "CLASSPATH=${CLASSPATH}"
   echo "Java to compile:"
   cat ${iWorkingDir}/temp/javafiles.txt
   echo ""
   echo "Compiling:"
   try javac @${iWorkingDir}/temp/javafiles.txt   
   rm -f ${iWorkingDir}/temp/javafiles.txt

  echo "Creating customall.jar:"
  $AD_TOP/bin/adcgnjar

  echo "Sync java between fs1 and fs2:"
  JAVA_TOP_1=${JAVA_TOP/fs2/fs1}
  JAVA_TOP_2=${JAVA_TOP/fs1/fs2}
  rsync -rtuv ${JAVA_TOP_1}/xx*  ${JAVA_TOP_2}/
  rsync -rtuv ${JAVA_TOP_2}/xx*  ${JAVA_TOP_1}/
  rsync -rtuv ${JAVA_TOP_1}/cchs ${JAVA_TOP_2}/
  rsync -rtuv ${JAVA_TOP_2}/cchs ${JAVA_TOP_1}/
  if [ -e ${JAVA_TOP_1}/customall.jar ] ; then
     rsync -rtuv ${JAVA_TOP_1}/customall.jar ${JAVA_TOP_2}/
  fi
  if [ -e ${JAVA_TOP_1}/customall.jar ] ; then
     rsync -rtuv ${JAVA_TOP_2}/customall.jar ${JAVA_TOP_1}/
  fi
fi


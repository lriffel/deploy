#!/bin/bash
#Deploys Oracle XML Publisher Customizations.

AppsPassword=$1
WorkingDir=$2
GIT_LOC=$3

vCount=0
for vFile in `grep "_XDO/" ${WorkingDir}/temp/files.lst | grep "\.txt"` ; do
   if [ $vCount == 0 ] ; then
      echo "Deploying XDO..."
   fi
   vCount=$((vCount+1))

   #Pulling parameters from the file.
   vFileName=$(exec awk '/^vFileName:/ { print $2 }' $vFile)   
   vApplicationShortName=$(exec awk '/^vApplicationShortName:/ { print $2 }' $vFile)   
   vLobType=$(exec awk '/^vLobType:/ { print $2 }' $vFile)   
   vLobCode=$(exec awk '/^vLobCode:/ { print $2 }' $vFile)   
   vFileType=$(exec awk '/^vFileType:/ { print $2 }' $vFile)   
   vContentType=$(exec awk '/^vContentType:/ { print $2 }' $vFile)   
   vForceYN=$(exec awk '/^vForceYN:/ { print $2 }' $vFile)   

   echo "==========================================================================================================================="
   echo "--XDO-Starting-------------------------------------------------------------------------------------------------------------"
   printf "java oracle.apps.xdo.oa.util.XDOLoader UPLOAD -DB_USERNAME apps -DB_PASSWORD '${AppsPassword}' " > /tmp/xdo_run.sh
   printf "   -JDBC_CONNECTION '${AD_APPS_JDBC_URL}' " >> /tmp/xdo_run.sh
   printf "   -APPS_SHORT_NAME ${vApplicationShortName} -LOB_TYPE ${vLobType} -LOB_CODE ${vLobCode} -LANGUAGE en " >> /tmp/xdo_run.sh
   printf "   -TERRITORY US -XDO_FILE_TYPE ${vFileType} -FILE_CONTENT_TYPE ${vContentType} -FILE_NAME ${GIT_LOC}/_XDO/${vFileName} " >> /tmp/xdo_run.sh
   if [ "$vForceYN" == "Y" ] ; then
      printf "   -NLS_LANG American_America.WE8ISO8859P1 -CUSTOM_MODE FORCE -LOG_FILE /tmp/xdo.txt" >> /tmp/xdo_run.sh
   else
      printf "   -NLS_LANG American_America.WE8ISO8859P1 -LOG_FILE /tmp/xdo.txt" >> /tmp/xdo_run.sh
   fi 
   bash /tmp/xdo_run.sh
   if [ "$?" = "0" ] ; then
      echo "Successful uploading XDO Loader using ${vFile}."
   else
      echo "FAILED uploading XDO Loader using ${vFile}."
   fi
   echo "--XDO-Run------------------------------------------------------------------------------------------------------------------"
   sed s/${AppsPassword}/xxxxxx/ /tmp/xdo_run.sh
   cat /tmp/xdo_run.sh
   echo " "
   echo "--XDO-Output---------------------------------------------------------------------------------------------------------------"
   cat /tmp/xdo.txt   
   echo "==========================================================================================================================="
   rm -f /tmp/xdo.txt
   rm -f /tmp/xdo_run.sh
done


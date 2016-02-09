#!/bin/bash

WorkingDir=$1
Env=$2
GIT_LOC=$3

function CopyIt {
   #Figure out if there is another server and assign a name.
   vHost=`hostname -s`
   vLast=${hostname: -1}
   if [ "$vLast" == "1" ] ; then
     vOtherHost=echo "${x%?}2"
   fi

   for file in `grep ${1}/${2} ${WorkingDir}/temp/allfiles.lst | grep .${3}` ; do
      if [ $vCount == 0 ] ; then
         echo "Deploying Reports..."
      fi
      vCount=$((vCount+1))

      echo "   Copying ${1} ${2} ${file}"
      cp -f $5/${file} $4/reports/US/

      if [ "$?" = "0" ] ; then
         echo "        Successful placed ${file}."
      else
         echo "        FAILED placing ${file}."
      fi
      
      #Copy to other server if necessary.
      if [ "$vLast" == "1" ] ; then
         #This server is a 1, so there must be a 2.
         scp -q -C $5/${file} oracle@${vOtherHost}:$4/reports/US/
         if [ "$?" = "0" ] ; then
            echo "        Successful placed ${file} on ${vOtherHost}."
         else
            echo "        FAILED placing ${file} on ${vOtherHost}."
         fi
      fi      
   done
}

vCount=0
mkdir -p ${XXDC_TOP}/reports/US/
mkdir -p ${XXCC_TOP}/reports/US/
CopyIt "XXDC" "reports" "rdf" "${XXDC_TOP}" "${GIT_LOC}"
CopyIt "XXCC" "reports" "rdf" "${XXCC_TOP}" "${GIT_LOC}"

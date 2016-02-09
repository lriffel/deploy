#!/bin/bash

#Replace the slash with an underscore so it is a valid filename.
vRelease="./releases/${1/\//_}"

WorkingDir="$HOME/deploy"

. ${WorkingDir}/scripts/functions.sh

vReleaseStatus="Success"

#Get Parameters specific to this instance.
cDBServerUsername=$(exec awk '/^cDBServerUsername:/ { print $2 }' config.txt)
cDBServer=$(exec awk '/^cDBServer:/ { print $2 }' config.txt)
cSID=$(exec awk '/^cSID:/ { print $2 }' config.txt)
cRequireReleaseFile=$(exec awk '/^cRequireReleaseFile:/ { print $2 }' config.txt)
cEnvFileDB=$(exec awk '/^cEnvFileDB:/ { print $2 }' config.txt)

echo "cRequireReleaseFile: ${cRequireReleaseFile}"
echo "vRelease: ${WorkingDir}/releases/${vRelease}"
echo "cSID: ${cSID}"

if [[ $cRequireReleaseFile == "N" ]] ; then
   if [ -f "${WorkingDir}/releases/${vRelease}" ] ; then
      cReleaseBranch=$(exec awk '/^cReleaseBranch:/ { print $2 }' $vRelease)
      cBranchesToDeploy=$(exec awk '/^cBranchesToDeploy:/ { print $2 }' $vRelease)
      cReleaseTicket=$(exec awk '/^cReleaseTicket:/ { print $2 }' $vRelease)
      cDeploymentType=$(exec awk '/^cDeploymentType:/ { print $2 }' $vRelease)
      vCompareBranch=$(exec awk '/^cCompareBranch:/ { print $2 }' $vRelease)
   else
      cReleaseBranch=$1
      cBranchesToDeploy=$1
      if [[ $cSID == "DEV1" ]] ; then
         cDeploymentType="All"
         vCompareBranch="PTCH"  #Used to be DEV2.
      else
         if [[ $cSID == "CNV2" ]] ; then
            cDeploymentType="All"
            vCompareBranch="CRP2"
         else
            if [[ $cSID == "DEV3" ]] ; then
               cDeploymentType="All"
               vCompareBranch="CRP2"
               ${WorkingDir}/scripts/check_temp.sh ${WorkingDir}
               vTempEnabled=$?
               echo "Temp Enabled: $vTempEnabled"
               if [ "${vTempEnabled}" == "0" ] ; then
                  echo "Deployments to DEV3 can only be done when the temp user is enabled."
                  exit 0
               else
                  echo "Temp is open in DEV3, proceeding with deployment."
               fi
            else
               echo "***** ERROR: Unknown SID of ${cSID}"
               exit 0;
            fi
         fi
      fi
   fi
else
   if [[ $vRelease == "./releases" ]] ; then
      echo "A release has not been provided, please provide a release branch."
      exit
   fi
   cReleaseBranch=$(exec awk '/^cReleaseBranch:/ { print $2 }' $vRelease)
   cBranchesToDeploy=$(exec awk '/^cBranchesToDeploy:/ { print $2 }' $vRelease)
   cReleaseTicket=$(exec awk '/^cReleaseTicket:/ { print $2 }' $vRelease)
   cDeploymentType=$(exec awk '/^cDeploymentType:/ { print $2 }' $vRelease)
   vCompareBranch=$(exec awk '/^cCompareBranch:/ { print $2 }' $vRelease)
fi
echo "Compare with: ${vCompareBranch}"

Host=`hostname -s`
Env="Atrium"
GIT_LOC="`echo ${WorkingDir}/../ebs-extensions`"
DeployLoc="_DEPLOY"

#Clean temp directory.
rm -f ${WorkingDir}/temp/*

#Create Release Log.
if [ -z "$cReleaseTicket" ] ; then
   vReleaseTicket=`echo ${cReleaseBranch} | cut -d'/' -f2 | cut -d'-' -f 1,2`
else
   vReleaseTicket=$cReleaseTicket 
fi
LogPrefix=${GIT_LOC}/${DeployLoc}/Release/${vReleaseTicket}_on_`date +%Y-%m-%d_%H-%M-%S`_to_${Host}
echo "LogPrefix=$LogPrefix"
mkdir -p ${LogPrefix}
ReleaseLog="${LogPrefix}/release.txt"
touch ${ReleaseLog}

#Error out if no release branch.
if [ "$cReleaseBranch" == "" ] ; then
   echo "You must configure a release branch in the release file."
   exit 0
fi
echo "-----------------------------------------------------------------------" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
echo "${cReleaseBranch} starting." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}

#Error out if no branches to deploy.
if [ "$cBranchesToDeploy" == "" ] ; then
   echo "You must configure at least one branch to deploy in the release file."
   exit 0
fi

mkdir -p $HOME/scripts/secure
if [ ! -f "$HOME/scripts/secure/apps" ] ; then
   read -s -p "Enter the Apps Password:" AppsPassword
   echo 
   echo "${AppsPassword}" > $HOME/scripts/secure/apps
else
   AppsPassword=`cat $HOME/scripts/secure/apps`
fi
if [ ! -f "$HOME/scripts/secure/system" ] ; then
   read -s -p "Enter the System Password:" SystemPassword
   echo
   echo "${SystemPassword}" > $HOME/scripts/secure/system
else
   SystemPassword=`cat $HOME/scripts/secure/system`
fi

echo "Set Environment."  | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
. $HOME/*.env
FORMS_PATH=$AU_TOP/forms/US:$XXCC_TOP/forms/US:$XXDC_TOP/forms/US:$FORMS_PATH
export FORMS_PATH

ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" 'bash' < ./scripts/release_before_invalids.sh

echo "Load branches into an array." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
IFS=',' read -ra BRANCHES <<< "$cBranchesToDeploy"

echo "Load JIRA keys into an array." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
regex="[A-Za-z]{2,5}-[0-9]+"
counter=0
for i in "${BRANCHES[@]}"; do
   if [[ $i =~ $regex ]] ; then
      TICKETS[$counter]=${BASH_REMATCH[0]}
   fi
   counter=$counter+1
done

#Go into directory.
cd $GIT_LOC

echo "GIT checkout/pull/diff." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
echo "      Compare Branch is $vCompareBranch." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}

${WorkingDir}/scripts/git_checkout.sh ${vCompareBranch} ${cReleaseBranch} ${WorkingDir} > /tmp/log.tmp
status=$?
if [[ $status -ne 0 ]] ; then
   cat /tmp/log.tmp
   exit $status
fi
${WorkingDir}/scripts/log2.sh ${ReleaseLog} /tmp/log.tmp

#Loop through branches applying differences.
counter=0
for BRANCH in "${BRANCHES[@]}"; do   
   TicketPrefix="${LogPrefix}/${TICKETS[$counter]}/"
   mkdir -p ${TicketPrefix}
   
   TicketLog="${TicketPrefix}_summary.txt"
   echo "" > ${TicketLog}
   echo "Deploying ${TICKETS[$counter]} - ${cDeploymentType}." | ${WorkingDir}/scripts/log.sh ${TicketLog}

   echo "   Extract file names and locations." | ${WorkingDir}/scripts/log.sh ${TicketLog}
   git diff --name-status origin/${vCompareBranch}..origin/${BRANCH} | grep -Pv "D\t" | sed -e 's/^M[\t]*/\t/' -e 's/^A[\t]*/\t/' | sed 's/[\t]//' > ${WorkingDir}/temp/files.lst

   grep -v .log ${WorkingDir}/temp/files.lst > ${WorkingDir}/temp/files2.lst
   rm -f ${WorkingDir}/temp/files.lst
   mv ${WorkingDir}/temp/files2.lst ${WorkingDir}/temp/files.lst      
   cp ${WorkingDir}/temp/files.lst ${TicketPrefix}/files.txt
   
   echo  "Checking for LDTs to deploy......." | ${WorkingDir}/scripts/log.sh ${TicketLog} 
   ${WorkingDir}/scripts/ldt.sh ${AppsPassword} ${WorkingDir} ${GIT_LOC} > /tmp/log.tmp 2>&1
   if [ -s /tmp/log.tmp ] ; then
      mv /tmp/log.tmp ${TicketPrefix}/ldt.txt

      if grep -q "FAILED" "${TicketPrefix}/ldt.txt"; then
         echo "...One or more LDT's FAILED!" | ${WorkingDir}/scripts/log.sh ${TicketLog}
         vReleaseStatus="Failed"
      else
         if grep -q "No data found for upload" "${TicketPrefix}/ldt.txt"; then
            echo "...One or more LDT's FAILED due to 'No data found for upload'!" | ${WorkingDir}/scripts/log.sh ${TicketLog}
            vReleaseStatus="Failed"
         else
            echo "...success." | ${WorkingDir}/scripts/log.sh ${TicketLog}
         fi   
      fi
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${TicketLog}
   fi
	
   echo "Checking for SQL to deploy........" | ${WorkingDir}/scripts/log.sh ${TicketLog} 
   ${WorkingDir}/scripts/sql.sh $AppsPassword $SystemPassword ${WorkingDir} \
      ${GIT_LOC}/${DeployLoc}/${TICKETS[$counter]}/_deploy.sql $GIT_LOC $Env ${cDBServerUsername} ${cDBServer} > /tmp/log.tmp
   status=$?
   if [ -s /tmp/log.tmp ] ; then   
      mv /tmp/log.tmp ${TicketPrefix}/sql.txt
      if [[ $status -ne 0 ]] ; then
         echo "...SQL failed exiting with a status of $status" | ${WorkingDir}/scripts/log.sh ${TicketLog}
         vReleaseStatus="Failed"
      else
         if grep -q "ORA-" "${TicketPrefix}/sql.txt"; then
            echo "...SQL failed with an ORA- error." | ${WorkingDir}/scripts/log.sh ${TicketLog}
            vReleaseStatus="Failed"
         else
            if grep -q "PLS-" "${TicketPrefix}/sql.txt"; then
               echo "...SQL failed with a PLS- error." | ${WorkingDir}/scripts/log.sh ${TicketLog}
               vReleaseStatus="Failed"
            else
               if grep -q "SP2-" "${TicketPrefix}/sql.txt"; then 
                  echo "...SQL failed with a SP2- error." | ${WorkingDir}/scripts/log.sh ${TicketLog}
                  vReleaseStatus="Failed"
               else
                  if grep -q "SQL>" "${TicketPrefix}/sql.txt"; then
                     echo "...success." | ${WorkingDir}/scripts/log.sh ${TicketLog}
                  else
                     echo "...none." | ${WorkingDir}/scripts/log.sh ${TicketLog}
                  fi 
               fi
            fi
         fi
      fi
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${TicketLog}
   fi

   if [[ "$cDeploymentType" != "AutoOnly" ]] ; then
      echo  "Checking for CTLs to deploy......." | ${WorkingDir}/scripts/log.sh ${TicketLog}
      ${WorkingDir}/scripts/ctl.sh ${WorkingDir} ${GIT_LOC} > /tmp/log.tmp
      if [ -s /tmp/log.tmp ] ; then
         mv /tmp/log.tmp ${TicketPrefix}/ctl.txt
         if grep -q -i "FAILED" "${TicketPrefix}/ctl.txt"; then
            echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${TicketLog}
            vReleaseStatus="Failed"
         else
            echo "...success." | ${WorkingDir}/scripts/log.sh ${TicketLog}
         fi
      else
         rm -f /tmp/log.tmp
         echo "...none." | ${WorkingDir}/scripts/log.sh ${TicketLog}
      fi
   fi
	
   echo "${TICKETS[$counter]} complete." | ${WorkingDir}/scripts/log.sh ${TicketLog}    
   echo "-----------------------------------------------------------------------" | ${WorkingDir}/scripts/log.sh ${TicketLog}    

   unix2dos -q ${TicketLog}
   
	counter=$counter+1
done 

if [ "$cDeploymentType" != "AutoOnly" ] ; then

   echo  "Checking for workflow to deploy..." | ${WorkingDir}/scripts/log.sh ${ReleaseLog} 
   ${WorkingDir}/scripts/wft.sh ${AppsPassword} ${WorkingDir} ${GIT_LOC} > /tmp/log.tmp 2>&1
   if [ -s /tmp/log.tmp ] ; then
      mv /tmp/log.tmp ${LogPrefix}/wft.txt
      if grep -q "FAILED" "${LogPrefix}/wft.txt"; then
         echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
         vReleaseStatus="Failed"
      else
         echo "...success." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
      fi
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   fi
      
   echo  "Checking for java to deploy......." | ${WorkingDir}/scripts/log.sh ${ReleaseLog} 
   ${WorkingDir}/scripts/java.sh ${WorkingDir} ${GIT_LOC} > /tmp/log.tmp 2>&1
   if [ -s /tmp/log.tmp ] ; then
      mv /tmp/log.tmp ${LogPrefix}/java.txt
      if grep -q "FAILED" "${LogPrefix}/java.txt"; then
         echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
         vReleaseStatus="Failed"
      else
         if grep -q "Error with command" "${LogPrefix}/java.txt"; then
            echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
            vReleaseStatus="Failed"
         else
            echo "...success." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
         fi
      fi 
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   fi
      
   echo  "Checking for XML Pubublisher......" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}       
   ${WorkingDir}/scripts/xdo.sh ${AppsPassword} ${WorkingDir} ${GIT_LOC} > /tmp/log.tmp 2>&1
   if [ -s /tmp/log.tmp ] ; then
      mv /tmp/log.tmp ${LogPrefix}/xdo.txt
      if grep -q "Error with command: javac" "${LogPrefix}/xdo.txt"; then
         echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
         vReleaseStatus="Failed"
      else
         if grep -q "FAILED uploading" "${LogPrefix}/xdo.txt"; then
            echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
            vReleaseStatus="Failed"
         else
            if grep -q "ORA-" "${LogPrefix}/xdo.txt"; then
               echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
               vReleaseStatus="Failed"
            else
               if grep -q "[ERROR]" "${LogPrefix}/xdo.txt"; then
                  echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
                  vReleaseStatus="Failed"
               else
                  echo "...success." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
               fi
            fi
         fi
      fi
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   fi

   echo  "Checking for OAF to deploy........" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   ${WorkingDir}/scripts/oaf.sh ${WorkingDir} ${GIT_LOC} ${AppsPassword} > /tmp/log.tmp 2>&1
   if [ -s /tmp/log.tmp ] ; then
      mv /tmp/log.tmp ${LogPrefix}/oaf.txt
      if grep -q "FAILED" "${LogPrefix}/oaf.txt"; then
         echo "...One or more OAF entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
         vReleaseStatus="Failed"
      else
         if grep -q "Error with command" "${LogPrefix}/oaf.txt"; then
            echo "...One or more OAF entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
            vReleaseStatus="Failed"
         else
            echo "...success." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
         fi
      fi
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   fi

   echo  "Checking for reports to deploy...." | ${WorkingDir}/scripts/log.sh ${ReleaseLog} 
   ${WorkingDir}/scripts/Reports.sh ${WorkingDir} ${Env} ${GIT_LOC} > /tmp/log.tmp   
   if [ -s /tmp/log.tmp ] ; then
      mv /tmp/log.tmp ${LogPrefix}/reports.txt
      if grep -q "FAILED" "${LogPrefix}/reports.txt"; then
          echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
          vReleaseStatus="Failed"
      else
         echo "...success." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
      fi
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   fi

   echo  "Checking for forms to deploy......" | ${WorkingDir}/scripts/log.sh ${ReleaseLog} 
   ${WorkingDir}/scripts/LibrariesAndForms.sh ${WorkingDir} > /tmp/log.tmp
   if [ -s /tmp/log.tmp ] ; then
      mv /tmp/log.tmp ${LogPrefix}/forms.txt
      if grep -q "FAILED" "${LogPrefix}/forms.txt"; then
          echo "...One or more entries FAILED!" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
          vReleaseStatus="Failed"
      else
         echo "...success." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
      fi
   else
      rm -f /tmp/log.tmp
      echo "...none." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   fi
fi

echo "-----------------------------------------------------------------------" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
printf "Compiling Invalids for Release...." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" 'bash' < ${WorkingDir}/scripts/release_compile.sh

vReleaseInvalids=$(release_after_invalids)
if [ "${vReleaseInvalids}" == "0" ] ; then
   echo "...none." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
else
   vReleaseStatus="Failed"
   echo "...${vReleaseInvalids} new invalids." | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
fi
echo "-----------------------------------------------------------------------" | ${WorkingDir}/scripts/log.sh ${ReleaseLog}    


if [ "${vReleaseStatus}" = "Failed" ] ; then
   echo '███████████████████████████████████████████████████████████████████████' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '█                                                                     █' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '█  X X X X X X X X X X X    Release FAILED!    X X X X X X X X X X X  █' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '█                                                                     █' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '███████████████████████████████████████████████████████████████████████' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
else
   echo '███████████████████████████████████████████████████████████████████████' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '█                                                                     █' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '█  Release successful.  :)                                            █' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '█                                                                     █' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}
   echo '███████████████████████████████████████████████████████████████████████' | ${WorkingDir}/scripts/log.sh ${ReleaseLog}

   echo "`date "+%Y/%m/%d %H:%M:%S"` Writing Pending Merge File"
   vDestination=`echo ${cSID} | tr '[:lower:]' '[:upper:]'`
   mkdir -p $HOME/deploy/pending/
   echo "#----Added `date "+%Y/%m/%d %H:%M:%S"` -------------------------#" >> $HOME/deploy/pending/pending_merge.txt
   echo "cd ${GIT_LOC}"                                                     >> $HOME/deploy/pending/pending_merge.txt
   echo "$HOME/deploy/scripts/git_merge.sh ""${vDestination}"" \\"          >> $HOME/deploy/pending/pending_merge.txt
   echo "   ""${cReleaseBranch}"" ""${vReleaseTicket}"""                    >> $HOME/deploy/pending/pending_merge.txt
   echo "cd $HOME/deploy"                                                   >> $HOME/deploy/pending/pending_merge.txt
   echo "#---------------------------------------------------------------#" >> $HOME/deploy/pending/pending_merge.txt
fi

unix2dos -q ${ReleaseLog}

echo "`date "+%Y/%m/%d %H:%M:%S"` Git Commit/Push"
${WorkingDir}/scripts/git_commit.sh ${cReleaseBranch} ${vReleaseTicket} > /dev/null 2>&1

#Go back out to home directory.
cd

echo "Deployment Complete"

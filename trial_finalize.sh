#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

vKeepAppsDown=$1

cd $HOME/deploy/
. ./scripts/functions.sh

#Get Parameters specific to this instance.
./scripts/init_config.sh
cDBServer=$(exec awk '/^cDBServer:/ { print $2 }' ./config.txt)
cDBServerUsername=$(exec awk '/^cDBServerUsername:/ { print $2 }' ./config.txt)
cSID=$(exec awk '/^cSID:/ { print $2 }' ./config.txt)
cEnvFile=$(exec awk '/^cEnvFile:/ { print $2 }' ./config.txt)
cEnvFileDB=$(exec awk '/^cEnvFileDB:/ { print $2 }' ./config.txt)

#Set the environment.
. ${cEnvFile}

echo "$(stop_if_temp_open)"
echo "$(stop_if_no_trial_deploy)"

if [ -e ./temp/temp_user_created ] ; then
   echo "The temp user has been created.  You must do a flashback_now or a trial_next."
   exit 1
fi 

#Create a restore point
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="$cEnvFileDB" iRestorePoint="Finalize__`date +"%Y_%m_%d__%H%M"`" iGuarentee="N" 'bash' < ./scripts/create_rp.sh

#Run pending merges.
if [ -e ./pending/pending_merge.txt ] ; then
   if [ -s ./pending/pending_merge.txt ] ; then
      bash ./pending/pending_merge.txt
      mv ./pending/pending_merge.txt /tmp/
   fi
fi

#Remove trial_deploy guaranteed restore point.
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="$cEnvFileDB" iRestorePoint="trial_deploy" iGuarentee="N" 'bash' < ./scripts/remove_rp.sh

#Startup Apps.
if [ "${vKeepAppsDown}" != "Y" ] ; then
   ./start_apps.sh
fi

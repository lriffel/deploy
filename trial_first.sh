#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

cd $HOME/deploy/
. ./scripts/functions.sh

./scripts/init.sh $0 $1

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
echo "$(stop_if_deploy_not_finalized)"
echo "$(stop_if_flashback_not_enabled)"

#Shutdown Apps.
./stop_apps.sh

#Create a guaranteed restore point
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" iRestorePoint="trial_deploy" iGuarentee="Y" 'bash' < ./scripts/create_rp.sh

#Remove all from pending folder.
rm -f ./pending/pending_merge.txt

#Run deployment.
./scripts/deploy_all.sh $1

rm -f /tmp/deploymentrunning.tmp

#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

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

echo "$(stop_if_no_trial_deploy)"

#Shutdown Apps.
./stop_apps.sh

#Flashback Database.
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="$cEnvFileDB" iRestorePoint="trial_deploy" 'bash' < ./scripts/flashback.sh

#Remove Guarenteed Restore Point.
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="$cEnvFileDB" iRestorePoint="trial_deploy" iGuarentee="N" 'bash' < ./scripts/remove_rp.sh

#Remove all from pending folder.
rm -f ./pending/pending_merge.txt

#Startup Apps.
./start_apps.sh



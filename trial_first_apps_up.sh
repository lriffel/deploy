#!/bin/bash

cd $HOME/deploy/

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

#Create a guaranteed restore point
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" iRestorePoint="trial_deploy" iGuarentee="Y" 'bash' < ./scripts/create_rp.sh

#Run deployment.
./scripts/deploy_all.sh $1

rm -f /tmp/deploymentrunning.tmp

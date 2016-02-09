#!/bin/bash
# Written 1/28/2015 by Leigh Riffel

cd $HOME/deploy/

#Get Parameters specific to this instance.
./scripts/init_config.sh
cDBServer=$(exec awk '/^cDBServer:/ { print $2 }' ./config.txt)
cDBServerUsername=$(exec awk '/^cDBServerUsername:/ { print $2 }' ./config.txt)
cSID=$(exec awk '/^cSID:/ { print $2 }' ./config.txt)
cEnvFile=$(exec awk '/^cEnvFile:/ { print $2 }' ./config.txt)
cEnvFileDB=$(exec awk '/^cEnvFileDB:/ { print $2 }' ./config.txt)

#Set the environment.
. ${cEnvFile}

vRestorePoint=$1
if [ -z $vRestorePoint ] ; then
   echo "Restore point missing, must be passed in."
   exit 1
fi
echo "Restore Point: $vRestorePoint"

iGuarenteed=$2
if [ -z $iGuarenteed ] ; then
   iGuarenteed='N'
fi

#Create a restore point(s)
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" iRestorePoint="${vRestorePoint}" iGuarentee="${iGuarenteed}" 'bash' < ./scripts/create_rp.sh

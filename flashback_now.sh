#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

cd $HOME/deploy/
. ./scripts/functions.sh

iRestorePoint=$1

if [ -z $iRestorePoint ] ; then
   echo "Restore point missing, must be passed in."
   exit 1 
fi

#Get Parameters specific to this instance.
./scripts/init_config.sh
cDBServer=$(exec awk '/^cDBServer:/ { print $2 }' ./config.txt)
cDBServerUsername=$(exec awk '/^cDBServerUsername:/ { print $2 }' ./config.txt)
cSID=$(exec awk '/^cSID:/ { print $2 }' ./config.txt)
cEnvFile=$(exec awk '/^cEnvFile:/ { print $2 }' ./config.txt)
cEnvFileDB=$(exec awk '/^cEnvFileDB:/ { print $2 }' ./config.txt)

#Set the environment.
. ${cEnvFile}

echo "$(stop_if_flashback_not_enabled)"

#Get System Password
if [ ! -f "$HOME/scripts/secure/system" ] ; then
   read -s -p "Enter the System Password:" SystemPassword
   echo
   echo "${SystemPassword}" > $HOME/scripts/secure/system
else
   SystemPassword=`cat $HOME/scripts/secure/system`
fi

#Make sure restore point exists.
export vRestorePointExists=`sqlplus -s system/${SystemPassword}@${cSID} << EOF
set feedback off
set verify off
set heading off
set pagesize 0
SELECT NVL((select 'Y' from gv\\$restore_point WHERE Name=UPPER('${iRestorePoint}')),'N') FROM dual;
exit;
EOF
`

if [[ $vRestorePointExists == "N" ]] ; then
   echo "Restore point missing on database."
   exit 1
fi

#Shutdown Apps.
./stop_apps.sh

#Flashback Database.
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="$cEnvFileDB" iRestorePoint="${iRestorePoint}" 'bash' < ./scripts/flashback.sh

#Remove Guarenteed Restore Point.
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="$cEnvFileDB" iRestorePoint="beforetemp" iGuarentee="Y" 'bash' < ./scripts/remove_rp.sh


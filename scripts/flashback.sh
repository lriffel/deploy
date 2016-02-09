#!/bin/bash

if [ -z $iRestorePoint ] ; then
   echo "Restore point missing, must be passed in."
   exit 1 
fi

if [ -z $cEnvFile ] ; then
   echo "Environment file definition must be passed in."
   exit 1
fi

#Set the environment.
. $cEnvFile

#Remove Temp file
rm -f ./temp/temp_user_created

sqlplus /nolog <<EOF
   whenever sqlerror exit failure
   connect / as sysdba

   prompt Shutting down database.
   shutdown immediate;
   prompt Starting database into mount exclusive state.
   startup mount exclusive;
   prompt Flashing back database to ${iRestorePoint}.
   flashback database to restore point ${iRestorePoint};
   prompt Opening database with resetlogs.
   alter database open resetlogs;

   exit 0
EOF



#!/bin/bash

if [ -z $cEnvFile ] ; then
   echo "Environment file definition must be passed in."
   exit 1
fi

WorkingDir="$HOME/deploy"

#Set the environment.
. $cEnvFile

touch ./temp/temp_user_created

#Create Temp User.
sqlplus /nolog <<EOF
   whenever sqlerror exit failure
   connect / as sysdba

   prompt Creating temp user.
   create user temp identified by temp;
   grant dba to temp;
   alter user apps grant connect through temp;

   exit 0
EOF


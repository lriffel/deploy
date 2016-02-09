#!/bin/bash

#$cEnvFile is passed in.

if [ -z $cEnvFile ] ; then
   echo "Environment file definition must be passed in to release_compile.sh."
   exit 1
fi

#Set the environment.
. $cEnvFile

sqlplus -s /nolog <<EOF
   whenever sqlerror exit failure
   set termout off
   connect / as sysdba

   @$ORACLE_HOME/rdbms/admin/utlrp.sql
   exit 0
EOF


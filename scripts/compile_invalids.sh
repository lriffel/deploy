#!/bin/bash

#$cEnvFile is passed in.

if [ -z $cEnvFile ] ; then
   echo "Environment file definition must be passed in."
   exit 1
fi

#Set the environment.
. $cEnvFile

sqlplus /nolog <<EOF
   whenever sqlerror exit failure
   connect / as sysdba
   @/tmp/InvalidsToCompile.sql
   exit 0
EOF




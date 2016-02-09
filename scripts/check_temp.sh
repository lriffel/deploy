#!/bin/bash

cEnvFile=$(exec awk '/^cEnvFile:/ { print $2 }' $1/config.txt)

#Set the environment.
. ${cEnvFile}

AppsPassword=`cat $HOME/scripts/secure/apps`

x=`sqlplus apps/${AppsPassword} <<endl | grep KEEP | sed 's/KEEP//;s/[ 	]//g'
select 'KEEP' , count(*) from dba_users where username='TEMP';
endl`

exit ${x}

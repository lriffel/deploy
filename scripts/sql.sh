#!/bin/bash

AppsPassword=$1
SystemPassword=$2
WorkingDir=$3
DeploySQL=$4
GIT_LOC=$5
Env=$6
cDBServerUsername=$7
cDBServer=$8

echo "Start SQL.sh"
echo "DeploySQL = $DeploySQL"
echo "Env = $Env"

if [ ! -f ${DeploySQL} ] ; then
   exit 0
fi

echo "Save current invalid objects to table."
sqlplus /nolog <<EOF
   whenever sqlerror exit failure
   connect system/$SystemPassword
   @${WorkingDir}/scripts/InvalidsTable.sql
   exit 0
EOF

sed "s|{GIT_LOC}|$GIT_LOC|g" ${DeploySQL} > ${WorkingDir}/temp/deploy.sql

sqlplus /nolog <<EOF
   whenever sqlerror continue
   connect system/$SystemPassword
   --Save off invalids
   INSERT INTO DBATools.Invalids (
      SELECT Owner, Object_Name, SubObject_Name, Object_ID, Data_object_id
         , object_type, created, last_ddl_time, timestamp, status
         , temporary, generated, secondary FROM DBA_Objects 
      WHERE Status='INVALID'
   );      
   set serveroutput on size 1000000 format wrapped;
   set linesize 30000;
   set pagesize 30000;
   alter session set current_schema=apps; 
   ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';
   set timing off;
   SELECT substr(sys_context('USERENV', 'DB_NAME'),1,7) "DB Name"
       , (SELECT instance_name FROM v\$instance) "Instance"
       , substr(sys_context('USERENV', 'HOST'),1,15) "Local Host"
       , substr(user,1,15) "User"
       , substr(sys_context('USERENV','SERVER_HOST'),1,20) "Server"
       , substr(sys_context('USERENV', 'CURRENT_SCHEMA'),1,15) "Schema"
       , to_char(sysdate,'MM/DD/YYYY HH:MI:SS PM') "Date-Time"
   FROM dual;
   set define off
   --User Scripts Start Here----------------------------------------------------
    
   @${WorkingDir}/temp/deploy.sql
 
   --User Scripts End Here------------------------------------------------------
   set define on
   @${WorkingDir}/scripts/Invalids.sql
   exit 0
EOF

if [ -s /tmp/InvalidsToCompile.sql ] ; then
   scp -q -C /tmp/InvalidsToCompile.sql ${cDBServerUsername}@${cDBServer}:/tmp/
   ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" 'bash' < ${WorkingDir}/scripts/compile_invalids.sh
fi

rm -f /tmp/InvalidsToCompile.sql


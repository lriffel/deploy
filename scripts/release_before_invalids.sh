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

   DECLARE
      eAlreadyExists Exception;
      pragma exception_init(eAlreadyExists,-00955);
   BEGIN
      EXECUTE IMMEDIATE 'CREATE TABLE DBATools.ReleaseInvalids 
         AS (SELECT Owner, Object_Name, SubObject_Name, Object_ID, Data_object_id, object_type, 
            created, last_ddl_time, timestamp, status, temporary, generated, secondary 
         FROM DBA_Objects WHERE 1=2)';
   EXCEPTION
      WHEN eAlreadyExists Then
         NULL;
   END;
   /

   --Save off invalids
   TRUNCATE TABLE DBATools.ReleaseInvalids;
   INSERT INTO DBATools.ReleaseInvalids (
      SELECT Owner, Object_Name, SubObject_Name, Object_ID, Data_object_id
         , object_type, created, last_ddl_time, timestamp, status
         , temporary, generated, secondary FROM DBA_Objects
      WHERE Status='INVALID'
   );
   COMMIT;

   exit 0
EOF




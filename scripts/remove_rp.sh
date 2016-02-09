#!/bin/bash
# Written 1/27/2015 by Leigh Riffel

#$iRestorePoint is passed in.
#$cEnvFile is passed in.

if [ -z $iRestorePoint ] ; then
   echo "Restore point missing, must be passed in."
   exit 1
fi
echo "Restore Point: $iRestorePoint"

if [ -z $cEnvFile ] ; then
   echo "Environment file definition must be passed in."
   exit 1
fi
echo "Environment file: $cEnvFile"

#Set the environment.
. $cEnvFile

sqlplus /nolog <<EOF
   whenever sqlerror exit failure
   connect / as sysdba

   DECLARE
      vRestorePoint Varchar2(30) := Upper('${iRestorePoint}');

      Procedure RemoveIt (iRP In Varchar2, iGuaranteed In Boolean) Is
         VExists  Varchar2(1);
      Begin
         DBMS_Output.Put_Line('Working on restore point ' || iRP);
         SELECT NVL((SELECT 'Y' FROM gv\$restore_point WHERE Name=iRP),'N') INTO vExists FROM dual;
         If (vExists = 'Y') Then
            DBMS_Output.Put_Line('Restore point ' || iRP || ' already exists, dropping it.');
            Execute Immediate ('DROP RESTORE POINT ' || iRP);
         End If;
      End;
   BEGIN
      DBMS_Output.Put_Line(' ');
      RemoveIt('G_' || vRestorePoint, true);
   END;
   /

   exit 0
EOF


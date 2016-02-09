#!/bin/bash
trap "exit 1" TERM
export TOP_PID=$$

cd $HOME/deploy/
. ./scripts/functions.sh

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
echo "$(stop_if_temp_open)"

#Get System Password
if [ ! -f "$HOME/scripts/secure/system" ] ; then
   read -s -p "Enter the System Password:" SystemPassword
   echo
   echo "${SystemPassword}" > $HOME/scripts/secure/system
else
   SystemPassword=`cat $HOME/scripts/secure/system`
fi

#Create Restore Point.
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" iRestorePoint="BeforeTemp" iGuarentee="Y" 'bash' < ./scripts/create_rp.sh

#Create Temp User.
ssh -q ${cDBServerUsername}@${cDBServer} cEnvFile="${cEnvFileDB}" 'bash' < ./scripts/create_temp_user.sh

./stop_apps.sh

sqlplus /nolog <<EOF
   whenever sqlerror exit failure
   connect system/$SystemPassword

   alter session set current_schema=apps;

   DECLARE

   Procedure SiteChange (iName Varchar2, iValue Number) Is
      vResult Boolean;
   Begin
      vResult := apps.FND_PROFILE.save(x_level_name => 'SITE', x_name =>iName ,x_value =>iValue);
      If vResult Then
         DBMS_Output.Put_Line ('Successfully changed ' || iName || ' to ' || iValue || '.');
      Else
         DBMS_Output.Put_Line ('Failed attempting to change ' || iName || ' to ' || iValue || '. Error: ' || sqlerrm);
      End If;
   End;

   Procedure SiteChange (iName Varchar2, iValue Varchar2) Is
      vResult Boolean;
   Begin
      vResult := apps.FND_PROFILE.save(x_level_name => 'SITE', x_name =>iName ,x_value =>iValue);
      If vResult Then
         DBMS_Output.Put_Line ('Successfully changed ' || iName || ' to ' || iValue || '.');
      Else
         DBMS_Output.Put_Line ('Failed attempting to change ' || iName || ' to ' || iValue || '. Error: ' || sqlerrm);
      End If;
   End;


   BEGIN
      SiteChange(iName => 'SITENAME', iValue => sys_context('USERENV', 'DB_NAME') || ' Temp user enabled, all changes to this environment will be lost');
      SiteChange(iName => 'FND_COLOR_SCHEME', iValue => 'RED');
      COMMIT;
   END;
   /

   exit 0
EOF

./start_apps.sh

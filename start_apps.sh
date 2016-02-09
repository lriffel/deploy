#!/bin/sh

cd $HOME/deploy/

#Set the environment.
cEnvFile=$(exec awk '/^cEnvFile:/ { print $2 }' ./config.txt)
. ${cEnvFile}

#Put in both environment variables.
vAppsPassword=$APPSPWD

echo `date +%m-%d-%Y%t%H:%M:%S%P` "- Verifying that $TWO_TASK is accessible with this password, otherwise don't run the script."
sqlplus -s /nolog > /dev/null 2>&1 <<EOF
whenever sqlerror exit failure
connect apps/$vAppsPassword@$TWO_TASK
exit success
EOF

if [ $? -ne 0 ]; then
   echo `date +%m-%d-%Y%t%H:%M:%S%P` "- The password is incorrect or there is a problem on the $ORACLE_SID database server."
   exit;
fi

export forms_sessions=`pgrep -f FND | wc -l`
if [ ! "${forms_sessions}" == "0" ] ; then
   echo "Apps already running."
   exit 0
fi

echo `date +%m-%d-%Y%t%H:%M:%S%P` "- DB and password verified, run script."
{ echo $WLPWD ; } | adstrtal.sh apps/$APPSPWD

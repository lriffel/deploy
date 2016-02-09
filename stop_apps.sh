#!/bin/sh

cd $HOME/deploy/

export forms_sessions=`pgrep -f FND | wc -l`
if [ "${forms_sessions}" == "0" ] ; then
   echo "Apps not running."
   exit 0
fi

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

echo `date +%m-%d-%Y%t%H:%M:%S%P` "- DB and password verified, run script."
adcmctl.sh stop apps/$APPSPWD wait=Y&


#Kill FND sessions.
export forms_sessions=`pgrep -f FND | wc -l`
vCounter=0
case "${TWO_TASK}" in
   "DEV1"|"BILD"|"dev1"|"cnv2"|"bild"|"CNV2"|"dev2"|"DEV2"|"ptch"|"PTCH"|"DEV3"|"dev3") let vCounter=120 ;;
esac
while [ "$forms_sessions" -ne "0" ] ; do
   if [ "$vCounter" -gt "119" ] ; then
      echo "Killing forms sessions"
      pgrep -f FND | while read p; do kill -9 $p; done
      sleep 3
      export forms_sessions=`pgrep -f FND | wc -l`
      let vCounter=vCounter+1
      continue
   fi
   if [ "$vCounter" -gt "200" ] ; then
      echo "All forms sessions could not be stopped."
      exit 1;
   fi
   echo "Sleeping for $vCounter second(s) [sessions killed at 120]  while waiting for FND Processes to end.  There are currently $forms_sessions."
   let vCounter=vCounter+1
   export forms_sessions=`pgrep -f FND | wc -l`
   sleep 1
done

#Kill the stop process put in the background.
kill $! &2>/dev/null

adcmctl.sh abort apps/$APPSPWD wait=Y
{ echo $WLPWD ; } | adstpall.sh apps/$APPSPWD

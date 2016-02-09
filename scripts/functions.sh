stop_if_temp_open() {
   SystemPassword=`cat $HOME/scripts/secure/system`

   local vTempOpen=`sqlplus system/${SystemPassword} <<endl | grep KEEP | sed 's/KEEP//;s/[	 ]//g'
      select 'KEEP', count(*) from dba_users where username='TEMP';
      endl`

   if [ "$vTempOpen" == "1" ] ; then
      printf "Temp should not be open when performing this action.\n"
      kill -s TERM $TOP_PID
   else
      printf "Temp is not open, continuing.\n"
   fi
}


stop_if_temp_not_open() {
   SystemPassword=`cat $HOME/scripts/secure/system`

   local vTempOpen=`sqlplus system/${SystemPassword} <<endl | grep KEEP | sed 's/KEEP//;s/[ 	]//g'
      select 'KEEP', count(*) from dba_users where username='TEMP';
      endl`

   if [ "$vTempOpen" == "0" ] ; then
      printf "Temp is not open, so any flashback will need to be manual.  Contact a DBA.\n"
      kill -s TERM $TOP_PID
   else
      printf "Temp is open, continuing.\n"
   fi
}


stop_if_deploy_not_finalized() {
   SystemPassword=`cat $HOME/scripts/secure/system`

   local vTrialStarted=`sqlplus system/${SystemPassword} <<endl | grep KEEP | sed 's/KEEP//;s/[ 	]//g'
      SELECT 'KEEP', count(*) FROM gv\\$restore_point WHERE Name LIKE '%TRIAL_DEPLOY%' AND Guarantee_Flashback_Database='YES' AND rownum<=1;
      endl`

   #echo "vTrialStarted is x${vTrialStarted}x."
   if [ "$vTrialStarted" == "1" ] ; then
      printf "A deployment has been started, but not finalized.  Your options are to do a trial deploy next, trial deploy flashback, or tiral deploy finalize.\n"
      kill -s TERM $TOP_PID
   else
      printf "A trial deployment has not been done yet, continuing.\n"
   fi
}


stop_if_no_trial_deploy() {
   SystemPassword=`cat $HOME/scripts/secure/system`

   local vTrialStarted=`sqlplus system/${SystemPassword} <<endl | grep KEEP | sed 's/KEEP//;s/[ 	]//g'
      SELECT 'KEEP', count(*) FROM gv$restore_point WHERE Name LIKE '%TRIAL_DEPLOY%' AND Guarantee_Flashback_Database='YES' AND rownum<=1;
      endl`

   if [ "$vTrialStarted" == "0" ] ; then
      printf "A deployment has not been started, nothing can be finalized.\n"
      kill -s TERM $TOP_PID
   else
      printf "There is a trial deployment to finalize, continuing.\n"
   fi
}


stop_if_flashback_not_enabled() {
   SystemPassword=`cat $HOME/scripts/secure/system`

   local vFlashbackEnabled=`sqlplus system/${SystemPassword} <<endl | grep KEEP | sed 's/KEEP//;s/[ 	]//g'
      SELECT 'KEEP', count(*) FROM v$database WHERE flashback_on='YES';
      endl`

   if [ "$vFlashbackEnabled" == "0" ] ; then
      printf "Flashback is not enabled.  No restore points can be set.\n"
      kill -s TERM $TOP_PID
   else
      printf "Flashback enabled, continuing.\n"
   fi
}


release_after_invalids() {
   SystemPassword=`cat $HOME/scripts/secure/system`

   local vAfterInvalids=`sqlplus system/${SystemPassword} <<endl | grep KEEP | sed 's/KEEP//;s/[ 	]//g'
      SELECT 'KEEP', count(*) FROM
      (
         SELECT owner, object_type, object_name FROM DBA_OBJECTS WHERE Status = 'INVALID'
         MINUS
         SELECT owner, object_type, object_name FROM DBATools.ReleaseInvalids
      );
      endl`

   printf $vAfterInvalids
}


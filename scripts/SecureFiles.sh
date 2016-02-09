#!/bin/bash
#Handle secure files (identified by .txt extension)

WorkingDir=$1

for file in `grep SECURE/formsecurefiles ${WorkingDir}/temp/files.lst | grep -i .txt` ; do
   if [ "${DBServer}" == "" ] ; then
      if [ ! -f "$HOME/scripts/secure/DBServer" ] ; then
         read -p "Enter the db server (first if two and the folder is shared like OAPROD is):" DBServer
         echo
         echo "${DBServer}" > $HOME/scripts/secure/DBServer
      else
         DBServer=`cat $HOME/scripts/secure/DBServer`
      fi
   fi
   ssh -q oracle@${DBServer} rm -f /secure/$file
   scp -q -C $file oracle@${DBServer}:/secure
   if [ "$?" = "0" ] ; then
      echo "Successful placed ${file} on db server in secure folder."
   else
      echo "FAILED placing ${file} on db server in secure folder."
   fi
done

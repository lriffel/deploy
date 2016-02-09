#!/bin/bash
#Initializes a deployment tools process.

cd $HOME/deploy/
mkdir -p temp

vCalledMe=$1
vBranch=$2

#Get the parameters from the file.
./scripts/init_config.sh
cSID=$(exec awk '/^cSID:/ { print $2 }' config.txt)
cDeploymentToolsBranch=$(exec awk '/^cDeploymentToolsBranch:/ { print $2 }' config.txt)

#Check to see if the deployment process is already running.
if [ -f /tmp/deploymentrunning.tmp ] ; then
   echo "A deployment tools script is running.  If it is not then delete as follows:"
   echo "rm -f /tmp/deploymentrunning.tmp"
   if [ ! "$cSID" == "DEV1" ] ; then
       echo "Removing deployment file for you.  You can now run if you're sure no one else is."
       rm -f /tmp/deploymentrunning.tmp
   fi 
   exit 1
else
   echo "======================================================================================"
   echo "==Start=Of=Deployment================================================================="
   echo "======================================================================================"
   touch /tmp/deploymentrunning.tmp
fi

echo "Cleaning and pulling $cDeploymentToolsBranch"
git fetch --prune
git checkout -f "$cDeploymentToolsBranch"
git reset --hard HEAD
git clean -fd
git branch | grep -v \* | xargs git branch -D > /dev/null 2>&1

rm -rf /tmp/gitpull.tmp > /dev/null
git pull | tee /tmp/gitpull.tmp
export gitpullreturn=`grep "up-to-date" "/tmp/gitpull.tmp"`
rm -rf /tmp/gitpull.tmp

if [ "$gitpullreturn" = "Already up-to-date." ] ; then
   echo "Deployment Tools already up to date."
   exit 0
else
   echo "We just pulled a new version of the Deployment-Tools, re-run."
   rm -f /tmp/deploymentrunning.tmp
   #Run whoever called me.
   echo `pwd`
   echo "CalledMe=$vCalledMe"
   cd $HOME
   eval "$vCalledMe $vBranch"
fi

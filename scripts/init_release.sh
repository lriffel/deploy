#!/bin/bash

echo "Creating the release file by prompting for input."

if [[ "$1" != "" ]] ; then
   cReleaseBranch=$1
else
   echo "#Example: RELEASE/DBA-1234" 
   read -p "Enter release branch:" -e cReleaseBranch
   echo
fi

#Make branch a usable filename by changing the / to an underscore.
vReleaseBranch=$cReleaseBranch
vReleaseBranch="./releases/${vReleaseBranch/\//_}"

#Start writing file.
echo "#Parameter file for deployment." > $vReleaseBranch
echo "#---------------------------------------------------------------------------------------------" >> $vReleaseBranch
echo "# Release Configuration. " >> $vReleaseBranch
echo "#---------------------------------------------------------------------------------------------" >> $vReleaseBranch
echo "cReleaseBranch: $cReleaseBranch" >> $vReleaseBranch

if [[ "$2" != "" ]] ; then
   cBranchesToDeploy=$2
else
   echo "#Example: JIRA/EBS-1234,JIRA/EBS-4567,JIRA/EBS-8910" 
   read -p "Enter the comma delimited feature branches: " -e cBranchesToDeploy
   echo
fi
echo "cBranchesToDeploy: $cBranchesToDeploy" >> $vReleaseBranch

if [[ "$3" != "" ]] ; then
   cReleaseTicket=$3
else
   echo "#Examples: DBA-1234, EBS-1234 (must enter something)" 
   read -p "Enter the release ticket: " -e cReleaseTicket
   echo
fi
echo "cReleaseTicket: $cReleaseTicket" >> $vReleaseBranch

if [[ "$4" != "" ]] ; then
   cDeploymentType=$4
else
   echo "#Example: All (Defaults to All, set to AutoOnly to deploy only PL/SQL and LDTs." 
   read -p "Enter the Database Deployment Type: " -e cDeploymentType
   echo
   if [ "$cDeploymentType" == "" ] ; then
      cDeploymentType="All"
   fi
fi
echo "cDeploymentType: $cDeploymentType" >> $vReleaseBranch

if [[ "$5" != "" ]] ; then
   cCompareBranch=$5
else
   echo "#Example: RELEASE/RC99-2015-08-27-DBA-2066."
   read -p "Enter the branch to compare to: " -e cCompareBranch
   echo
fi
echo "cCompareBranch: $cCompareBranch" >> $vReleaseBranch

cat $vReleaseBranch

git add ./releases/*
git commit -a -m "Adding release file."
git pull
git push

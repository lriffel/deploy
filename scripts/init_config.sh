#!/bin/bash

if [ -e ./config.txt ] ; then
   exit 0;
fi

echo "Creating the config.txt parameter file by prompting for input."

echo "#Parameter file for all functions." > config.txt
echo "#---------------------------------------------------------------------------------------------" >> config.txt
echo "# Parameter Configuration. " >> config.txt
echo "#---------------------------------------------------------------------------------------------" >> config.txt

echo "#Example: PTCH" 
read -p "Enter the Database SID: " -e cSID
echo
echo "cSID: $cSID" >> config.txt

echo "#Example: /home/oracle/ptch.env" 
read -p "Enter the path and filename for the environment file (for apps): " -e cEnvFile
echo
echo "cEnvFile: $cEnvFile" >> config.txt

echo "#Example: /home/oracle/ptch.env"
read -p "Enter the path and filename for the environment file (for db): " -e cEnvFileDB
echo
echo "cEnvFileDB: $cEnvFileDB" >> config.txt

echo "#Example: atd0dbadm01" 
read -p "Enter the database server name: " -e cDBServer
echo
echo "cDBServer: $cDBServer" >> config.txt

echo "#Example: oracle" 
read -p "Enter the database server user name: " -e cDBServerUsername
echo
echo "cDBServerUsername: $cDBServerUsername" >> config.txt

echo "#Example: master (defaults to master, only change this to use an experimental branch.)"
read -p "Enter the Database deployment tools branch to use: " -e cDeploymentToolsBranch
echo
if [ "$cDeploymentToolsBranch" == "" ] ; then
   cDeploymentToolsBranch="master"
fi
echo "cDeploymentToolsBranch: $cDeploymentToolsBranch" >> config.txt

echo "#Example: Y"
read -p "Enter whether or not you require deployments done here to use a release file: " -e cRequireReleaseFile
echo
if [[ $cRequireReleaseFile == "Y" ]] ; then
   echo "cRequireReleaseFile: $cRequireReleaseFile" >> config.txt
else
   echo "cRequireReleaseFile: N" >> config.txt
fi


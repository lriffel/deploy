#!/bin/bash
#Deploys one or more tickets.

cd $HOME/deploy/

./scripts/init.sh $0 $1

#Get the parameters from the file.
./scripts/init_config.sh
cSID=$(exec awk '/^cSID:/ { print $2 }' ./config.txt)
cDeploymentToolsBranch=$(exec awk '/^cDeploymentToolsBranch:/ { print $2 }' ./config.txt)

./scripts/deploy_all.sh $1

rm -f /tmp/deploymentrunning.tmp

#!/bin/bash

cd $HOME/deploy/

if [ ! -e config.txt ] ; then
   ./scripts/init_config.sh
fi
./scripts/init_release.sh $1 $2 $3 $4 $5

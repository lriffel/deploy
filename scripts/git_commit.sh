#!/bin/bash

ReleaseBranch=$1
ReleaseTicket=$2

git add .
git commit -m "${ReleaseTicket} Deployment to $HOSTNAME"
git push origin ${ReleaseBranch}
git checkout master
git branch -D ${ReleaseBranch}

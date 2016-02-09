#!/bin/bash

CompareBranch=$1
ReleaseBranch=$2
WorkingDir=$3

#Make sure global configuration is set.
git config --global user.email "databases-`hostname -a`@cchs.com"
git config --global user.name "Deployment Tools"

function try {
    "$@"
    local status=$?
    
    if [ $status -ne 0 ]; then  
        echo "Error with command: $1 $2 $3 $4 $5" >&2 
        exit $status
    fi
    return $status
}

try git fetch --prune

try git checkout -f master
try git branch | grep -v \* | xargs git branch -D

try git checkout "${CompareBranch}"
try git reset --hard origin/"${CompareBranch}"
try git pull
export vLastHash=`git log -n 1 --pretty=format:"%H"`

try git checkout "${ReleaseBranch}"
try git reset --hard origin/"${ReleaseBranch}"
try git pull
export vFoundHash=`git log --pretty="%H" | grep ${vLastHash}`

if [[ "${vFoundHash}" != "${vLastHash}" ]] ; then
  echo "The release branch (${ReleaseBranch}) does not contain the latest commit from the compare branch (${vCompareBranch})."
  echo "A merge may need to be done before deploying this ticket."
  echo "Found Hash: ${vFoundHash}"
  echo "Last Hash : ${vLastHash}"
  #exit 1283
fi

try git diff --name-status origin/${CompareBranch}..origin/${ReleaseBranch} | grep -Pv "D\t" | sed -e 's/^M[\t]*/\t/' -e 's/^A[\t]*/\t/' | sed 's/[\t]//' > ${WorkingDir}/temp/allfiles.lst

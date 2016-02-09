#!/bin/bash
CompareBranch=$1
ReleaseBranch=$2
ReleaseTicket=$3

function try {
    "$@"
    local status=$?

    if [ $status -ne 0 ]; then
        echo "Error with command: $1 $2 $3" >&2
        exit $status
    fi
    return $status
}

try git fetch --prune
try git checkout "${ReleaseBranch}"
try git reset --hard origin/"${ReleaseBranch}"
try git pull
try git checkout "${CompareBranch}"
try git reset --hard origin/"${CompareBranch}"
try git pull
try git merge -m "Merging branch ${ReleaseBranch} into ${CompareBranch}." "${ReleaseBranch}"
try git add .
#Not putting this in a try block because there may be nothing to commit, which is ok.
git commit -m "Deployed ${ReleaseTicket}"
try git push origin "${CompareBranch}"



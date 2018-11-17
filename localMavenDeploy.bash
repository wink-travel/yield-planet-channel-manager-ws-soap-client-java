#!/bin/bash

echo "Deploying Maven artifact to external repo"

# make sure the variables are set
if [ -z ${1+x} ]; then
    echo "Git branch unset"
    exit
else
    echo "git branch is set to '$1'"
fi

gitBranch=$1

git checkout $gitBranch

mvn -B clean deploy -Dmaven.test.skip=true
STATUS=$?
if [ $STATUS -ne 0 ]; then
    echo "Something went wrong on line: ${BASH_LINENO[*]}"
    git checkout develop
    exit 1
fi

git checkout develop
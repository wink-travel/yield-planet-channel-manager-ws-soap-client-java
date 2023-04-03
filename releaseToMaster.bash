#!/bin/bash

#
# Copyright (c) 2023. wink.travel. All rights Reserved.
#

echo "Releasing siteminder-channel-manager-web-services-client..."

echo "Cleaning artifacts..."
mvn clean

echo "Sync-ing remote master with local"
git checkout master
git pull

git checkout develop
echo "Retrieving next version number..."
newVersion=`npx git-changelog-command-line --print-next-version --major-version-pattern BREAKING --minor-version-pattern feat`

read -p "Do you want to proceed with version $newVersion? (y/n) " yn

case $yn in
	[yY] ) echo "New semantic version using Conventional Commits: $newVersion"

    mvn versions:set -DnewVersion="$newVersion-SNAPSHOT" -DgenerateBackupPoms=false

    git commit -a -m ":bookmark: build: Committing updated pom.xml files and CHANGELOG.md."

    echo "Starting release process..."

    mvn -B gitflow:release-start gitflow:release-finish -DskipTestProject=true
    STATUS=$?
    if [ $STATUS -ne 0 ]; then
      echo "Something went wrong on line: ${BASH_LINENO[*]}"
      exit 1
    fi

    echo "Release complete. Cleaning up..."

    echo "Pushing master to origin"
    git checkout master

    echo "Updating CHANGELOG.md..."
    npx git-changelog-command-line -of CHANGELOG.md
    git commit -a -m ":memo: doc: Updated CHANGELOG.md..."

    git push origin master:refs/heads/master

    echo "Creating GitHub release..."
    gh release create v$newVersion --notes "See CHANGELOG.md for release notes" --target master

    echo "Grabbing the last Git release details"
    git pull

    git checkout develop

    echo "Merging CHANGELOG.md from master..."
    git merge master --no-edit -m ":twisted_rightwards_arrows: doc: merged CHANGELOG.md from master into develop branch" --strategy-option theirs

    echo "Pushing develop to origin"
    git push origin develop:refs/heads/develop
    exit;;
	[nN] ) echo "Exiting...";
		exit;;
	* ) echo "Invalid response";
    exit 1;;
esac

echo "Release SUCCESS"

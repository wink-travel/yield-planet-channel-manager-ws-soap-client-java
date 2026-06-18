#!/bin/bash

#
# Copyright (c) 2023. wink.travel. All rights Reserved.
#

echo "Releasing yield-planet-channel-manager-web-services-client..."

echo "Cleaning artifacts..."
mvn clean

echo "Sync-ing remote master with local"
# --- release hardening: never let an ambient pull.rebase=true / pull.ff turn a
# sync-pull into a history-rewriting rebase or surprise merge. Pin every pull to
# fast-forward-only so a diverged shared branch FAILS LOUDLY instead of silently
# rebasing a just-finished release onto origin. Overrides personal git config. ---
git config --local pull.ff only
git config --local pull.rebase false
git checkout master
git pull --ff-only

git checkout develop

# --- Pre-flight conflict guard (run BEFORE the gitflow release/merge) ---
# The maven gitflow plugin merges develop into master at release. If develop has
# diverged (a previous release's back-merge was lost, or commits landed straight
# on master), that merge CONFLICTS and breaks the release. Detect it here, in
# memory: `git merge-tree` never touches the working tree (requires git >= 2.38).
echo "==> Pre-flight: checking develop merges into master without conflicts..."
if git merge-base --is-ancestor master develop; then
  echo "OK: master already contained in develop -- release merge will be clean"
elif _gtout=$(git merge-tree --write-tree --name-only develop master 2>/dev/null); then
  echo "WARN: develop diverged from master but merges cleanly -- proceeding."
  git --no-pager log --oneline master ^develop | sed 's/^/     /'
else
  echo ""
  echo "RELEASE STOPPED -- develop must be reconciled with master first."
  echo "   Merging 'develop' into 'master' would CONFLICT and break the release."
  echo "   Conflicting files:"
  printf '%s\n' "$_gtout" | tail -n +2 | sed 's/^/     - /'
  echo ""
  echo "   Reconcile develop first, then re-run:"
  echo "     git checkout develop && git merge master   # resolve toward develop, commit"
  echo "     git push origin develop"
  echo ""
  echo "   Commits on master missing from develop:"
  git --no-pager log --oneline master ^develop | sed 's/^/     /'
  exit 1
fi

echo "Retrieving next version number..."
newVersion=`npx git-changelog-command-line --print-next-version --major-version-pattern BREAKING --minor-version-pattern feat`

read -p "Do you want to proceed with version $newVersion? (y/n) " yn

case $yn in
	[yY] ) echo "New semantic version using Conventional Commits: $newVersion"

    mvn versions:set -DnewVersion="$newVersion-SNAPSHOT" -DgenerateBackupPoms=false

    git commit -a -m ":bookmark: build: Committing updated pom.xml files and CHANGELOG.md. [no ci]"

    echo "Starting release process..."

    mvn -B gitflow:release-start gitflow:release-finish -DskipTestProject=true -DcommitMessagePrefix="[no ci] "
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
    git commit -a -m ":memo: doc: Updated CHANGELOG.md... [no ci]"

    git push origin master:refs/heads/master

    echo "Creating GitHub release..."
    gh release create v$newVersion --notes "See CHANGELOG.md for release notes" --target master

    echo "Grabbing the last Git release details"
    git pull --ff-only

    git checkout develop

    echo "Merging CHANGELOG.md from master..."
    git merge master --no-edit -m ":twisted_rightwards_arrows: doc: merged CHANGELOG.md from master into develop branch [no ci]" --strategy-option theirs

    echo "Pushing develop to origin"
    git push origin develop:refs/heads/develop
    exit;;
	[nN] ) echo "Exiting...";
		exit;;
	* ) echo "Invalid response";
    exit 1;;
esac

echo "Release SUCCESS"

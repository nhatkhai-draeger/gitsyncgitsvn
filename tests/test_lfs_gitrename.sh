#!/bin/bash
runMany variables_setup.sh
runOnce test_lfs_gitcommits.sh

TEST "ADD FILE IN SVN, SYNC, GIT MOVE FILE, THEN SYNC"

pushd svn_test/proj2
echo "gitrename1" > gitrename1.dat
echo "gitrename_conflict1" > gitrename_conflict1
svn add gitrename1.dat gitrename_conflict1
"${svnCommit[@]}" -m "add gitrename1"
popd

INFO "# Sync svn change to git"
echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj2
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

INFO "# Modify file on SVN, and move file from git repos"
pushd svn_test/proj2
echo "gitrename_conflict1 modify" >> gitrename_conflict1
"${svnCommit[@]}" -m "modify gitrename_conflict1"
popd

pushd git_test/proj2_local
git lfs install --local
git pull --no-rebase
mkdir gitrename_folder
git mv gitrename1.dat gitrename_folder
git rm gitrename_conflict1
git commit -m "move gitrename1"
git push
popd

INFO "# Sync svn change to git"
pushd git_test/proj2
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

(cd svn_test/proj2; svn up .)
(cd git_test/proj2_local; git pull --no-rebase)
pushd git_test/proj2
git lfs install --local
git checkout master -f
diff . ../../svn_test/proj2 \
  -x .git -x mod1 -x mod2 -x .gitmodules -x .gitattributes && a=0 || a=$?
Assert $a -eq 0 "svn and git should be matched"

Assert "" -f ../../svn_test/proj2/gitrename_folder/gitrename1.dat \
  "file gitrename1.dat in svn should be moved in gitrename_folder"
popd

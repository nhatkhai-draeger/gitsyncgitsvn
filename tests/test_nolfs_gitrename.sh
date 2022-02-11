#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_init.sh
runOnce test_nolfs_gitcommits.sh

TEST "ADD FILE IN SVN, SYNC, GIT MOVE FILE, THEN SYNC"

pushd svn_test/proj1
echo "nolfs_gitrename1" > nolfs_gitrename1
svn add nolfs_gitrename1
"${svnCommit[@]}" -m "add nolfs_gitrename1"
popd

INFO "# Sync svn change to git"
echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj1
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

INFO "# Move file from git repos"
pushd git_test/proj1_local
git pull --no-rebase
mkdir gitrename_folder
git mv nolfs_gitrename1 gitrename_folder
git commit -m "move nolfs_gitrename1"
git push
popd

INFO "# Sync svn change to git"
pushd git_test/proj1
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

(cd svn_test/proj1; svn up .)
(cd git_test/proj1_local; git pull --no-rebase)
pushd git_test/proj1
git checkout master -f
diff . ../../svn_test/proj1 \
  -x .git -x mod1 -x mod2 -x .gitmodules  && a=0 || a=$?
Assert $a -eq 0 "svn and git should be matched"

diff . ../../git_test/proj1_local -x .git && a=0 || a=$?
Assert "" -f ../../svn_test/proj1/gitrename_folder/nolfs_gitrename1 \
  "file nolfs_gitrename1 in svn should be moved in gitrename_folder"
popd

#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_init.sh

TEST "SYNC COMMITS PROJ1 FROM GIT"

INFO "# Inject some change from git repos"
echo git_test/proj1_local >> clean_list
git clone file://$curDir/git_repo/proj1.git git_test/proj1_local
pushd git_test/proj1_local
echo "test2" > file2
git add file2
git commit -m "2nd"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj1
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

(cd svn_test/proj1; svn up .)
pushd git_test/proj1
git checkout master -f
diff . ../../svn_test/proj1 -x .git -x mod1 -x mod2 -x .gitmodules \
  || Assert $? -eq 0 "svn and git should be matched"

diff . ../../git_test/proj1_local -x .git \
  || Assert $? -eq 0 "git local and git should be matched"
popd

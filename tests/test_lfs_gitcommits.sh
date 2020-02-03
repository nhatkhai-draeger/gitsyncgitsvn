#!/bin/bash
runMany variables_setup.sh
runOnce test_lfs_init.sh

TEST "SYNC COMMITS PROJ1 FROM GIT"

INFO "## Inject some change from git repos"
echo git_test/proj2_local >> clean_list
git clone file://$curDir/git_repo/proj2.git git_test/proj2_local
pushd git_test/proj2_local
echo "test2" > file2
git add file2
git commit -m "2nd"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj2
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "## ${cmd[*]}"
"${cmd[@]}" 
popd

(cd svn_test/proj2; svn up .)
pushd git_test/proj2
git checkout master -f
diff . ../../svn_test/proj2 -x .git -x .gitattributes -x .gitmodules -x mod2 
Assert $? -eq 0 "svn and git should be matched"
popd

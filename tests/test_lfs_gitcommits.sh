#!/bin/bash
runMany variables_setup.sh
runOnce test_lfs_init.sh

TEST "SYNC COMMITS PROJ2 FROM GIT (LFS)"

INFO "# Inject some change from git repos"
echo git_test/proj2_local >> clean_list
git clone -n $gitUrl/git_repo/proj2.git git_test/proj2_local
pushd git_test/proj2_local
git lfs install --local
git checkout master
echo "test2" > file2
echo "test3" > file3.dat
git add -- file2 file3.dat
git commit -m "2nd"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj2
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

(cd svn_test/proj2; svn up .)
pushd git_test/proj2
git lfs install --local
git checkout master -f
diff . ../../svn_test/proj2 \
  -x .git -x .gitattributes -x .gitmodules -x mod2 && a=0 || a=$?
Assert $a -eq 0 "svn and git should be matched"

diff . ../../git_test/proj2_local && a=0 || a=$?
Assert $a -eq 0 "git_local and git should be matched"
popd

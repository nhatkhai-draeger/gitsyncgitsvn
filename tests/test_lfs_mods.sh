#!/bin/bash
runMany variables_setup.sh
runOnce test_lfs_gitcommits.sh
runOnce create_submodules.sh

TEST "SYNC MULTIPLE COMMITS CONTAINS SUBMODULE (LFS)"

INFO "# Add submodule"
pushd git_test/proj2_local
git pull --no-rebase
git submodule add $gitUrl/git_repo/mod2.git mod2
git commit -a -m "Add mod2"
INFO "# Modify submodule"
pushd mod2
echo "mod2 - Proj2" > modProj2File2
git add modProj2File2
git commit -m "Proj2 2nd mod2"
git push
popd
git commit -a -m "Proj2 Update mod2"
INFO "# Modify submodule 2nd time"
pushd mod2
echo "modify1 - Proj2" > modProj2File2
git commit -a -m "Proj2 3rd mod2"
git push
popd
echo "mod4 - Proj2" > file1
git commit -a -m "Proj2 Update mod2 2nd time, and file1"
echo "mod5 - Proj2" > file2
git commit -a -m "Proj2 Update file2"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj2
cmd=($scriptDir/sync)
INFO "# ${cmd[*]}"
"${cmd[@]}" "${syncParam[@]}"
popd

(cd svn_test/proj2; svn up .)
pushd git_test/proj2
git lfs install --local
git checkout master -f

diff . ../../svn_test/proj2 \
  -x .git -x .gitattributes -x .gitmodules -x mod2 && a=0 || a=$?
Assert $a -eq 0 "git and svn should match except mod1, mod2, .git*"

diff . ../../git_test/proj2_local && a=0 || a=$?
Assert $a -eq 0 "git local and git should match"
popd

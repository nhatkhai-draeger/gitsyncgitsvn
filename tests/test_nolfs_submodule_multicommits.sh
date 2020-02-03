#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_gitcommits.sh
runOnce create_submodules.sh

TEST "SYNC MULTIPLE COMMITS CONTAINS SUBMODULE"

INFO "## Add submodule"
pushd git_test/proj1_local
git submodule add file://$curDir/git_repo/mod2.git mod2
git commit -a -m "Add mod2"
INFO "## Modify submodule"
pushd mod2
echo "mod2" > modfile2
git add modfile2
git commit -m "2nd mod2"
git push
popd
git commit -a -m "Update mod2"
INFO "## Modify submodule 2nd time"
pushd mod2
echo "modify1" > modfile2
git commit -a -m "3rd mod2"
git push
popd
echo "mod4" > file1
git commit -a -m "Update mod2 2nd time, and file1"
echo "mod5" > file2
git commit -a -m "Update file2"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj1
cmd=($scriptDir/sync)
INFO "## ${cmd[*]}"
"${cmd[@]}" "${syncParam[@]}"
popd

(cd svn_test/proj1; svn up .)
pushd git_test/proj1
git checkout master -f
diff . ../../svn_test/proj1 -x .git -x mod1 -x mod2 -x .gitmodules
Assert $? -eq 0 "git and svn should match except mod1, mod2, .git*"
popd

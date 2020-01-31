#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_gitcommits.sh

TEST "SYNC A COMMIT CONTAINS SUBMODULE"

INFO "## Create submodule"
echo git_repo/mod1.git  >> clean_list
echo git_test/mod1      >> clean_list
git init --bare git_repo/mod1.git
git clone file://$curDir/git_repo/mod1.git git_test/mod1
pushd git_test/mod1
echo "mod1" > modfile1
git add modfile1
git commit -m "1st mod1"
git push
popd

INFO "## Add submodule"
pushd git_test/proj1_local
git submodule add file://$curDir/git_repo/mod1.git mod1
git commit -a -m "Add mod1"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj1
cmd=($scriptDir/sync)
INFO "## ${cmd[*]}"
"${cmd[@]}" "${syncParam[@]}"
popd

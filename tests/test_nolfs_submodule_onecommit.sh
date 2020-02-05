#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_gitcommits.sh
runOnce create_submodules.sh

TEST "SYNC A COMMIT CONTAINS SUBMODULE"

INFO "# Add submodule"
pushd git_test/proj1_local
git submodule add file://$curDir/git_repo/mod1.git mod1
git commit -a -m "Add mod1"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj1
cmd=($scriptDir/sync)
INFO "# ${cmd[*]}"
"${cmd[@]}" "${syncParam[@]}"
popd

(cd svn_test/proj1; svn up .)
pushd git_test/proj1
git checkout master -f
diff . ../../svn_test/proj1 -x .git -x mod1 -x mod2 -x .gitmodules \
  || Assert $? -eq 0 "svn and git should match except mod1 and .git*"
popd

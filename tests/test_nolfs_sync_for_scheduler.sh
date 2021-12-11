#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_gitcommits.sh

TEST "SYNC_FOR_SCHEDULER script"

INFO "# Inject some change from git repos"
pushd git_test/proj1_local
git pull --no-rebase
echo "test sync for scheduler1" > file2
git commit -am "test sync for scheduler1"
git push
popd

echo "/tmp/sync_for_scheduler_{0,1}*" >> clean_list
cmd=($scriptDir/sync_for_scheduler $flockMode "${jenkinsParam[@]}" -d proj1)
INFO "# ${cmd[*]}"
"${cmd[@]}" "${syncParam[@]}"

(cd svn_test/proj1; svn up .)
pushd git_test/proj1
git checkout master -f
diff . ../../svn_test/proj1 \
  -x .git -x mod1 -x mod2 -x .gitmodules && a=0 || a=$?
Assert $a -eq 0 "svn and git should match except mod1 and .git*"

diff . ../../git_test/proj1_local && a=0 || a=$?
Assert $a -eq 0 "git local and git should match"
popd

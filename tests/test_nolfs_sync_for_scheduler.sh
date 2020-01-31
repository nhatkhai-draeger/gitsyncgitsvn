#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_gitcommits.sh

TEST "SYNC_FOR_SCHEDULER script"

INFO "## Inject some change from git repos"
pushd git_test/proj1_local
echo "test sync for scheduler1" > file2
git commit -am "test sync for scheduler1"
git push
popd

echo "/tmp/sync_for_scheduler_{0,1}*" >> clean_list
cmd=($scriptDir/sync_for_scheduler "${jenkinsParam[@]}" -d proj1)
INFO "## ${cmd[*]}"
"${cmd[@]}" "${syncParam[@]}"

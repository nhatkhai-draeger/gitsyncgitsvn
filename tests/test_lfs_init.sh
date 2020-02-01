#!/bin/bash
runMany variables_setup.sh
runOnce cleanup.sh
runOnce env_setup.sh
runOnce init_repos.sh

TEST "INITIAL SYNC PROJ2 FROM SVN (LFS)"

echo git_test/proj2         >> clean_list
echo log                    >> clean_list
echo "/tmp/init_new_sync_{0,1}*" >> clean_list
cmd=($scriptDir/init_new_sync "${urls[@]}" "${syncParam[@]}")
cmd+=("${jenkinsParam[@]}")
cmd+=(--gitDot gitLFSDot -d proj2)
INFO "## ${cmd[*]}"
"${cmd[@]}" 

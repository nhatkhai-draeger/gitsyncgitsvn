#!/bin/bash
runMany variables_setup.sh
runOnce cleanup.sh
runOnce env_setup.sh
runOnce init_repos.sh

TEST "INITIAL SYNC PROJ1 FROM SVN"

echo git_test/proj1         >> clean_list
echo log                    >> clean_list
echo "/tmp/init_new_sync_{0,1}*" >> clean_list
cmd=($scriptDir/init_new_sync "${urls[@]}" "${syncParam[@]}")
cmd+=("${jenkinsParam[@]}")
cmd+=(--gitDot . -d proj1)
INFO "# ${cmd[*]}"
"${cmd[@]}" 

pushd git_test/proj1
git checkout svn/proj1 -f
diff . ../../svn_test/proj1 -x .git \
  || Assert $? -eq 0 "should match svn contents"
Assert -z '"`git lfs ls-files`"' "" "no lfs in svn/proj1 branch"
Assert -z '"`git diff master`"' "" "master and svn/proj1 are the same"
popd

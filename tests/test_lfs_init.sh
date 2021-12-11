#!/bin/bash
runMany variables_setup.sh
runOnce cleanup.sh
runOnce env_setup.sh
runOnce init_repos.sh

TEST "INITIAL SYNC PROJ2 FROM SVN (LFS)"

echo git_test/proj2         >> clean_list
echo log                    >> clean_list
echo "/tmp/init_new_sync_{0,1}*" >> clean_list
cmd=($scriptDir/init_new_sync $flockMode "${urls[@]}" "${syncParam[@]}")
cmd+=("${jenkinsParam[@]}")
cmd+=(--gitDot gitLFSDot -d proj2)
INFO "# ${cmd[*]}"
"${cmd[@]}" 

pushd git_test/proj2
git lfs uninstall --local
git checkout svn/proj2 -f
diff . ../../svn_test/proj2 -x .git && a=0 || a=$?
Assert $a -eq 0 "should match svn contents"
Assert -z '"`git lfs ls-files`"' "" "no lfs in svn/proj2 branch"

git lfs install --local
git checkout master -f
diff . ../../svn_test/proj2 \
  -x .git -x .gitattributes -x .gitmodules -x mod2 && a=0 || a=$?
Assert $a -eq 0 "should match svn contents"
Assert '"`git lfs ls-files`"' =~ '"* file1.dat"$' "lfs in master"
popd


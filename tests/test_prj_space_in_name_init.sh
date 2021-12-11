#!/bin/bash
runMany variables_setup.sh
runOnce cleanup.sh
runOnce env_setup.sh
runOnce init_repos.sh

TEST "INITIAL SYNC "PROJ A B" FROM SVN"

echo git_test/projab        >> clean_list
echo log                    >> clean_list
echo "/tmp/init_new_sync_{0,1}*" >> clean_list
cmd=($scriptDir/init_new_sync $flockMode "${urls[@]}" "${syncParam[@]}")
cmd+=("${jenkinsParam[@]}")
cmd+=(--gitDot gitLFSDot -d "proj a b")
INFO "# ${cmd[*]}"
"${cmd[@]}" 

pushd git_test/projab
git lfs uninstall --local
git checkout svn/projab -f
diff . "../../svn_test/proj a b" -x .git && a=0 || a=$?
Assert $a -eq 0 "should match svn contents"
Assert -z '"`git lfs ls-files`"' "" "no lfs in svn/projab branch"

git lfs install --local
git checkout master -f
diff . "../../svn_test/proj a b" -x .git -x .gitattributes && a=0 || a=$?
Assert $a -eq 0 "should match svn contents"
Assert '"`git lfs ls-files`"' =~ '" file1.dat"$' "file1.dat is lfs file"
popd


#!/bin/bash
runMany variables_setup.sh
runOnce test_prj_space_in_name_init.sh

TEST "SYNC COMMITS PROJ A B FROM GIT & SVN REPOS URL MOVED"

INFO "# Inject some change from git repos"
echo git_test/projab_local >> clean_list
git clone -n $gitUrl/git_repo/projab.git git_test/projab_local
pushd git_test/projab_local
git lfs install --local
git checkout master
echo "test4" > file4
git add file4
git commit -m "proj ab file4"
git push
popd

INFO "# Copy svn_repo to svn_rewrite_repo"
echo svn_rewrite_repo >> clean_list
cp -rf svn_repo svn_rewrite_repo

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/projab
cmd=($scriptDir/sync "${syncParam[@]}")
cmd+=(--svnUrl "$svnUrl/svn_rewrite_repo")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

INFO "# Checkout new svn URL to svn_test_rewrite"
echo svn_test_rewrite >> clean_list
svn co $svnUrl/svn_rewrite_repo svn_test_rewrite

pushd git_test/projab
git lfs install --local
git checkout master -f
diff . "../../svn_test_rewrite/proj a b" \
  -x .git -x .gitattributes && a=0 || a=$?
Assert $a -eq 0 "svn and git should be matched"

diff . "../../git_test/projab_local" && a=0 || a=$?
Assert $a -eq 0 "git local and git should be matched"
popd


INFO "# Inject some change after rewrite from git repos"
pushd git_test/projab_local
echo "test5" > file5
git add file5
git commit -m "proj ab file5"
git push
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/projab
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

pushd svn_test_rewrite
svn up
popd

pushd git_test/projab
git lfs install --local
git checkout master -f
diff . "../../svn_test_rewrite/proj a b" \
  -x .git -x .gitattributes && a=0 || a=$?
Assert $a -eq 0 "svn and git should be matched"

diff . "../../git_test/projab_local" && a=0 || a=$?
Assert $a -eq 0 "git local and git should be matched"
popd

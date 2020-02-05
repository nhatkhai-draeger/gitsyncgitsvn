#!/bin/bash
runMany variables_setup.sh
runOnce test_prj_space_in_name_init.sh

TEST "SYNC COMMITS PROJ A B FROM GIT & SVN REPOS URL MOVED"

INFO "# Inject some change from git repos"
echo git_test/projab_local >> clean_list
git clone file://$curDir/git_repo/projab.git git_test/projab_local
pushd git_test/projab_local
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
cmd+=(--svnUrl "file://$curDir/svn_rewrite_repo")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

INFO "# Checkout new svn URL to svn_test_rewrite"
echo svn_test_rewrite >> clean_list
svn co file://$curDir/svn_rewrite_repo svn_test_rewrite

pushd git_test/projab
git lfs install --local
git checkout master -f
diff . "../../svn_test_rewrite/proj a b" -x .git -x .gitattributes \
  || Assert $? -eq 0 "svn and git should be matched"

diff . "../../git_test/projab_local" -x .git -x file1.dat \
  || Assert $? -eq 0 "svn and git should be matched except lfs files"
popd

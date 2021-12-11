#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_init.sh
runOnce test_nolfs_gitcommits.sh

TEST "SYNC COMMITS PROJ1 FROM GIT WHILE GIT GOT NEW COMMITS"

INFO "# Inject some change from git repos"
pushd git_test/proj1_local
echo "nolfs_gitchange test1" > nolfs_gitchange_file1
git add nolfs_gitchange_file1
git commit -m "nolfs_gitchange_file1"
git push
popd

echo "$HOME/.SYNC_TEST_MASTER_CHANGE_WHILE_MERGE" >> clean_list
cat > $HOME/.SYNC_TEST_MASTER_CHANGE_WHILE_MERGE <<EOF
pushd ../../git_test/proj1_local
echo "nolfs_gitchange test2" > nolfs_gitchange_file2
git add nolfs_gitchange_file2
git commit -m "nolfs_gitchange_file2"
git push
popd
rm $HOME/.SYNC_TEST_MASTER_CHANGE_WHILE_MERGE
EOF

pushd svn_test/proj1
echo "nolfs_gitchange svn1" > nolfs_gitchange_svn1
svn add nolfs_gitchange_svn1
"${svnCommit[@]}" -m "nolfs_gitchange svn1"
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj1
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

(cd svn_test/proj1; svn up .)
(cd git_test/proj1_local; git pull --no-rebase)
pushd git_test/proj1
WARN "MANUAL CHECK: git log below should show two merge commits on master"
git log master svn/proj1 --oneline --graph --decorate=short --author-date-order

git checkout master -f
diff . ../../svn_test/proj1 \
  -x .git -x mod1 -x mod2 -x .gitmodules  && a=0 || a=$?
Assert $a -eq 0 "svn and git should be matched"

diff . ../../git_test/proj1_local -x .git && a=0 || a=$?
Assert $a -eq 0 "git local and git should be matched"
popd

#!/bin/bash
runMany variables_setup.sh
runOnce test_nolfs_init.sh
runOnce test_nolfs_gitcommits.sh

TEST "SYNC COMMITS PROJ1 FROM GIT WHILE SVN GOT NEW COMMITS DURING DCOMMIT"

INFO "# Inject some change from git repos"
pushd git_test/proj1_local
echo "nolfs_chgdcommit test1" > nolfs_chgdcommit_file1
git add nolfs_chgdcommit_file1
git commit -m "nolfs_chgdcommit_file1"
git push
popd

echo "$HOME/.SYNC_TEST_SVN_CHANGE_WHILE_DCOMMIT" >> clean_list
cat > $HOME/.SYNC_TEST_SVN_CHANGE_WHILE_DCOMMIT <<EOF
pushd ../../svn_test/proj1
echo "nolfs_chgdcommit svn2" > nolfs_chgdcommit_svn2
svn add nolfs_chgdcommit_svn2
${svnCommit[@]} -m "nolfs_chgdcommit svn2"
popd
rm $HOME/.SYNC_TEST_SVN_CHANGE_WHILE_DCOMMIT
EOF

pushd svn_test/proj1
echo "nolfs_chgdcommit svn1" > nolfs_chgdcommit_svn1
svn add nolfs_chgdcommit_svn1
"${svnCommit[@]}" -m "nolfs_chgdcommit svn1"
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj1
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" && Assert $? -ne 0 "Should got unhandled error"
popd


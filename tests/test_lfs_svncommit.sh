#!/bin/bash
runMany variables_setup.sh
runOnce test_lfs_init.sh

TEST "SYNC SVN COMMITS W/ UNEXPECTED BINARY FILE (LFS)"

INFO "# Add a binary file that not specified in .gitattributes"
pushd svn_test/proj2
svn up .
echo "test2" > file3
printf "\01\02\03" > newBinFile2
svn add file3 newBinFile2
svn commit -m "LFS with unexpected binary file"
popd

echo "/tmp/sync_{0,1}*" >> clean_list
pushd git_test/proj2
cmd=($scriptDir/sync "${syncParam[@]}")
INFO "# ${cmd[*]}"
"${cmd[@]}" 
popd

pushd git_test/proj2
git lfs install --local
git checkout master -f
diff . ../../svn_test/proj2 \
  -x .git -x .gitattributes -x .gitmodules -x mod2 && a=0 || a=$?
Assert $a -eq 0 "should match svn contents"
Assert '"`git lfs ls-files -n | grep newBinFile2`"' =~ '^"newBinFile2"$' \
  "newBinFile should automatic tracked by lfs"
popd

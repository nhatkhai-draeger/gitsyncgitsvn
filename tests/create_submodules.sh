#!/bin/bash
INFO "# Create submodule1"
echo git_repo/mod1.git  >> clean_list
echo git_test/mod1      >> clean_list
git init -b master --bare git_repo/mod1.git
git clone $gitUrl/git_repo/mod1.git git_test/mod1
pushd git_test/mod1
echo "mod1" > modfile1
git add modfile1
git commit -m "1st mod1"
git push
popd

INFO "# Create submodule2"
echo git_repo/mod2.git  >> clean_list
echo git_test/mod2      >> clean_list
git init -b master --bare git_repo/mod2.git
git clone $gitUrl/git_repo/mod2.git git_test/mod2
pushd git_test/mod2
echo "mod2" > modfile1
git add modfile1
git commit -m "1st mod2"
git push
popd


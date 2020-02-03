NOTE "# Crate repos"

INFO "## Create empty svn repo"
echo svn_repo >> clean_list
svnadmin create svn_repo

INFO "## Create proj1 in SVN with some commits"
echo svn_test >> clean_list
svn co file://$curDir/svn_repo svn_test
pushd svn_test

mkdir proj1
echo "test" > proj1/file1
svn add proj1
svn commit -m "1st"
popd

INFO "## Create proj2 in SVN with some commits"
pushd svn_test
mkdir proj2
echo "proj2 file1" > proj2/file1.dat
echo "proj2 file1" > proj2/file1
svn add proj2
svn commit -m "1st project2"
svn up .
popd

INFO "## Create empty git repo"
echo git_repo >> clean_list
git init --bare git_repo/proj1.git
git init --bare git_repo/proj2.git

INFO "## Create empty git test folder"
echo git_test >> clean_list
mkdir -p git_test


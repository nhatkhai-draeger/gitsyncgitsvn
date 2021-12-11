#!/bin/bash
os=`uname -o`

gitUrl="file://$curDir"
if [[ $os == "Msys" ]]; then
  svnUrl="svn://localhost/`cygpath -m "$curDir"`"
  svnCommit=(svn commit --username `whoami` --password a)
  flockMode=--noflock

else
  svnUrl="$gitUrl"
  svnCommit=(svn commit)
  flockMode=
fi

syncParam=(--svnUser `whoami` --svnPwd a --authors "$curDir/authors")
urls=(--svnUrl "$svnUrl/svn_repo" --gitUrl "$gitUrl/git_repo")
jenkinsParam=(-v --logDir log --gitDir git_test)

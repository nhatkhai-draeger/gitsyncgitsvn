syncParam=(--svnUser `whoami` --svnPwd a --authors "$curDir/authors")
urls=(--svnUrl "file://$curDir/svn_repo" --gitUrl "file://$curDir/git_repo")
jenkinsParam=(-v --logDir log --gitDir git_test)

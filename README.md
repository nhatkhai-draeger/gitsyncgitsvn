## GIT <==> SVN with or without LFS support
Script to synchronize change from SVN to GIT and vise versa.

## Setup a initial git repository
* Repair a .gitattributes file to specify which type need to be track by
  lfs in folder XXX
* Repair a .gitignore and other .git files in folder XXX.

```
SYNC_GIT_PATH>init_new_sync --svnUser AAA --svnPwd BBB --svnUrL CCC --gitUrl DDD --gitDot XXX -- A_PROJECT_FOLDER_IN_SVN
```

When this initialization is complete, you can run regularly the sync script
in under the root of your git folder to synchronize commits.
```
SYNC_GIT_PATH/A_PROJECT_FOLDER_IN_SV>THIS_SCRIPT_FOLDER/sync
```

## Detail parameters
The sync script allows you to specify many other parameters other than its 
default values. ``sync -h`` to see all available options

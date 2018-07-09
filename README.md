## GIT <==> SVN with or without LFS support
Script to synchronize change from SVN to GIT and vise versa.

## Setup a initial git repository
```
SYNC_GIT_PATH>git init
SYNC_GIT_PATH>git remote add origin ssh://git@stash.xyz.com:7999/XYZ.git
SYNC_GIT_PATH>git checkout --orphan master
SYNC_GIT_PATH>git lfs track "*.exe"
# Edit .gitattributes file to have all the binary file use LFS
SYNC_GIT_PATH>git add .gitattributes
SYNC_GIT_PATH>git commit -m "Initial repo setting"
```

After this initial setting you now can pick a SVN folder or subfolder to be
synchronize with git. For example a Cricket folder in SVN
```
SYNC_GIT_PATH>THIS_SCRIPT_FOLDER/sync --init Cricket
```

When this initialization is complete, you can run regularly the sync script
in under the root of your git folder to synchronize commits. You can also
use task scheduler to run the script
```
SYNC_GIT_PATH>THIS_SCRIPT_FOLDER/sync
```
## Detail parameters
The sync script allows you to specify many other parameters other than its 
default values. ``sync -h`` to see all available options

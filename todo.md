# Issues:
## Known:
None

## Wish list
None

## Fixed
* (Solved) When run on jenkins - assuming nodes have git-lfs, cygwin git, cygwin
  bash, scheduler cygwin home setting: Control all significant environment
  variables.
* (Solved) When run on jenkins - still have dependency on nodes for global
  .gitconfig: Control all significant environment variables, and point to
  the special .gitconfig for the project while run.
* (Solved) git svn dcommit use differ svn user for commits: by using svn
  commit hook to fix the author base on commit message.
* (Solved) git rebase need to reserve it's original author info.
* (Solved) one incident a merge from git to svn that left minor file content
  differences (sim_report.txt were the one). Manually fix the project
  history on git side. The cause of the problem  where rebase code that did
  not take care submodules and normal file commit correctly.

# Initial ideas
## Manual trial
>svn log -q | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); printf $2" = "$2" <"$2">"}' | sort -u > authors-transform.txt
Edit authors-transform.txt file xyz = xyz <xyz.xyz@xyz.com>

>git init
>git remote add origin ssh://git@stash.xyz.com:7999/att/cricket_test.git

add (Oldest folder name)
[svn-remote "svn"]
	url = http://xyz:8080/svn/projects/GoldBox
	fetch = :refs/remotes/git-svn-goldbox
>git svn fetch -A ../authors-transform.txt
>git checkout -b feature/svn-goldbox git-svn-goldbox
>git push -u origin feature/svn-goldbox

change (newer folder name)
[svn-remote "svn"]
	url = http://xyz:8080/svn/projects/Cricket
  fetch = :refs/remotes/git-svn-cricket
>git svn fetch -A ../authors-transform.txt
>git checkout -b feature/svn-cricket git-svn-cricket
>git push -u origin feature/svn-cricket

## Script method
 * - set up .gitattribute for LFS tracking
 1 - Fetch from SVN (Cricket) - Capture the SHA1 range
 2 - Rebase onto svn/lfs/Cricket - Capture then SHA1 range
 3 - Apply filter-branch SHA1..svn/lfs/Cricket
    git filter-branch --prune-empty -f --tree-filter '
        #cp /tmp/1 .gitattributes
        git ls-files | while read file; do git add "$file"; done
        ' -- SHA1..svn/goldbox
 * - Push svn/lfs/Cricket to Stash
 
 * - Lock master
 * - Fetch master from Stash
 4 - Merge svn/lfs/Cricket to master
 * - Rebase master on svn/Cricket call try/master
 * - Apply filter-branch to undo LFS
 6 - SVN Dcommit
 * - Handle after Dcommit error or success
 * - Push master to Stash
 * - UnLock master

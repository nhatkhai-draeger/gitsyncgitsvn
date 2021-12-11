#!/bin/bash
# Run on VirtualBox Win10_cyg image via ssh
svn --version

INFO "# Configure test environment"
if [[ -f "$HOME/.gitconfig" ]]; then
  if [[ ! "$HOME" -ef "`pwd`" ]]; then
    ERROR "HOME should be set to `pwd`"
    exit 1
  fi
fi
echo "$HOME/.gitconfig" >> clean_list
git config --global user.email "test@email.com"
git config --global user.name "tester"

INFO "## Create authors file"
echo clean_list     >> clean_list
echo authors        >> clean_list
echo "`whoami`=ze <one@email.com>" > authors
echo "test=tester <test@email.com>" >> authors

INFO "## Create .gitattributes files"
echo .gitattributes >> clean_list
echo > .gitattributes

echo gitLFSDot      >> clean_list
mkdir -p gitLFSDot
echo "*.dat filter=lfs diff=lfs merge=lfs -text" > gitLFSDot/.gitattributes


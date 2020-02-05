# Run on VirtualBox Win10_cyg image via ssh
INFO "# Check required cygwin modules"
cygmods=(git git-svn subversion)
cnt=`cygcheck -c -d "${cygmods[@]}" | wc -l`
( 
  if [[ $(($cnt-2)) -lt ${#cygmods[@]} ]]; then
    NOTE "## Install required cygwin modules"
    net use x: \\\\att.corp.draeger.global\\distribution \
      /user:corp\\`whoami`
    IFS=","
    /cygdrive/x/3rdParties/cygwin64_setup/setup-x86.exe -q \
      -l x:\\3rdParties\\cygwin64_setup -L -P "${cygmods[*]}"
  fi 
)

INFO "# Configure test environment"
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


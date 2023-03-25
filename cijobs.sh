#!/usr/bin/bash
syntax()
{
  # Search all the bash script files
  grep "^#!.*/bash" . -R -l --exclude-dir .git > .tmp.bashFiles

  # Check syntax on all bash script files
  rm -f .tmp.errors
  while read f; do 
    echo "Check $f";
    bash -n "$f" || printf "$f, ">>.tmp.errors & 
  done < .tmp.bashFiles
  wait
  if [[ -f .tmp.errors ]]; then exit 1; fi
}

test()
{
  os=`uname -o`
  if [[ $os == "Cygwin" ]]; then
    echo "# Check and install required cygwin modules"
    $CIUTILS getCygPkg "" git git-svn subversion sed gawk

    echo "Check and install git lfs if needed"
    [[ $GIT_LFS_INST_DEF ]] && PATH="`cygpath "$GIT_LFS_INST_DEF"`:$PATH"
    which git-lfs &>/dev/null || $CIUTILS runUrl $GIT_LFS_INST_URL

  elif [[ $os == "Msys" ]]; then
    echo "Check and install subversion if needed"
    [[ $SVN_INST_DEF ]] && PATH="`cygpath "$SVN_INST_DEF"`:$PATH"
    which svn &>/dev/null || $CIUTILS runMsiUrl $SVN_INST_URL

    echo "Start svn server"
    svnserve -d &
    svnservePID=$!
  fi

  mkdir tmp_$os 2>/dev/null
  pushd tmp_$os
  export HOME="`pwd`"
  export GIT_CONFIG_NOSYSTEM=1
  export FILTER_BRANCH_SQUELCH_WARNING=1
  unset  SSH_ASKPASS
  export PATH
  ../sync_test -v -f "$@"
  err=$?
  popd

  if [[ $os == "Msys" ]]; then
    echo "Stop svn server"
    kill -KILL $svnservePID
  fi

  [[ $err -eq 0 ]] || exit $err
}

default_value()
{
  [[ -z $CIUTILS ]] && CIUTILS=./ciUtils.cmd
  CIUTILS=`realpath "$CIUTILS"`
}

default_value
if [[ $# -ne 0 ]]; then
  if [[ $1 == "." ]]; then
    # Normal run
    shift;
    "$@"

  else 
  ( # Try to under default environment
    if [[ -z $DEF_ENV_URL ]]; then
      rm -f "$TMP/.cache/.envVars"
      export DEF_ENV_URL="https://att.corp.draeger.global/Distribution/Config/env/developer.txt"
    fi
    $CIUTILS runBash $0 . "$@"
  )
  fi
fi

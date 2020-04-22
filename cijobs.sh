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
mkdir tmp 2>/dev/null
pushd tmp
../sync_test -v -f || exit $?
popd
}

while true; do
  [[ $1 =~ ^(syntax|)$ ]] && syntax
  [[ $1 =~ ^(test|)$   ]] && test
  shift;
  [[ -z "$1" ]] && break;
done

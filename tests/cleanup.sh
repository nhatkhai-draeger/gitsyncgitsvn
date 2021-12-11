#!/bin/bash
NOTE "# Clean current directory"
if [[ -f clean_list ]]; then
  sort -u clean_list | while read f; do
    INFO "removing $f"
    for file in $f; do 
      rm -rf "$file" &>/dev/null || continue
    done
  done
fi
INFO_EVAL "ls -a"

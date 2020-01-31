#!/usr/bash
TEST "utils library code"
source "$scriptDir/utils"

pushd /
Assert `tryRealPath "tmp"` == "/tmp" "Folder exist"
Assert `tryRealPath "tmp1"` == "tmp1" "Not existing"

echo /tmp/tmp_$$ >> clean_list
echo "hello" > tmp/tmp_$$
Assert `tryRealPath "tmp/tmp_$$"` == /tmp/tmp_$$ "File exist"
rm -f tmp/tmp_$$                     
Assert `tryRealPath "tmp/tmp_$$"` == tmp/tmp_$$ "File not exist"
popd

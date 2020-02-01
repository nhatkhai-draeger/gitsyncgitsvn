#!/usr/bash
runOnce cleanup

TEST "logging library code"
source "$scriptDir/logging"

# Remove all the escape code to easier for verify text message
LOG_DEBUG="DEBUG"
 LOG_INFO=" INFO"
 LOG_NOTE=" NOTE"
 LOG_WARN=" WARN"
LOG_ERROR="ERROR"

      LOG_EOL='++\n'
  LOG_LINEMSG=''

LOG_LEVEL=$LOG_LEVEL_DEBUG
Assert "'`DBG "#1 THIS IS DEBUG Message"`'"   =~ \
     '"] DEBUG #1 THIS IS DEBUG Message"'
Assert "'`INFO "#2 THIS IS INFO Message"`'"   =~ \
      '"]  INFO #2 THIS IS INFO Message"'
Assert "'`NOTE "#3 THIS IS NOTE Message"`'"   =~ \
      '"]  NOTE #3 THIS IS NOTE Message"' 
Assert "'`WARN "#4 THIS IS WARN Message"`'"   =~ \
     '"]  WARN #4 THIS IS WARN Message"' 
Assert    "'`ERROR "#5 THIS IS ERROR Message" 2>&1`'" =~ \
         '"] ERROR #5 THIS IS ERROR Message"'
Assert -z "'`ERROR "#5 THIS IS ERROR Message" 2>/dev/null`'" "" \
  "ERROR does not print out standard output"


LOG_LEVEL=$LOG_LEVEL_INFO
Assert -z "'`DBG "FAIL: THIS DEBUG Message should not shown"`'" "" \
  "DBG should not print out anything with LOG_LEVEL_INFO"
Assert "'`INFO "#6 THIS IS INFO Message\nMultiline"`'" =~ '"
                #6 THIS IS INFO Message++ 
                        -- Multiline++"'
Assert "'`NOTE "#7 THIS IS NOTE Message
          Line2
          Line3"`'" =~ '"
          NOTE #7 THIS IS NOTE Message++
       -- Line2++
       -- Line3++"'
Assert "'`WARN "#8 THIS IS WARN Message#2"`'" =~ \
              '"#8 THIS IS WARN Message#2"'
Assert -z "'`ERROR "THIS IS ERROR MESSAGE SHOULD NOT SHOWN" 2>/dev/null`'" \
  "" "ERROR do not print to standard output"

Assert -z "'`exitIfErr 1 "FAIL: This should not shown" echo "also this"`'" \
  "" "exitIfErr do nothing when cond. not meet"
Assert -z "'`exitIf '1 == 2' 1 "FAIL: This should not shown" echo "also this"`'" \
  "" "exitIf do nothing when cond. not meet"

cleanUp1() { echo "#10 CleanUp 1"; }
cleanUp2() { echo "#9 CleanUp 2"; }
EXIT_CMDS=(cleanUp1)

echo logging_test.err >> clean_list
echo logging_test.out >> clean_list
(
  set +e
  (
    EXIT_CMDS=(cleanUp2)
    (exit 1)
    exitIfErr 2 "#9 exiting error message" \
      echo "\#9 Exit code SHOULD be 2"
  ) 2> logging_test.err 1> logging_test.out
  Assert $? -eq 2 "exitIfErr exit with error code 2"
)
Assert "'`cat logging_test.out`'" =~ \
  '"#9 exiting error message++
    #9 CleanUp 2"$'
Assert "'`cat logging_test.err`'" =~ \
  '"#9 Exit code SHOULD be 2"'

(
  set +e
  (
    (exit 2)
    exitIf "$? -ne 2" "4" "FAIL: \$? issue in exitIf"
    (exit 2)
    exitIf '$errCode -ne 2' "4" "FAIL: \$erroCode issue in exitIf"
    echo HERE
  )  2> logging_test.err 1> logging_test.out
  Assert '$errCode' -eq 0 "exitIf is not meet cond."
)
Assert "'`cat logging_test.out`'" == \
  '"HERE"'
Assert -z "" "'`cat logging_test.err`'" \
  "exitIf do nothing with satisfy cond."

myVar="Khai aflk iahK"
(
  set +e
  (
    (exit 3)
    exitIf "$? -ne 2" 3 "#10 exiting error message" '
      echo "#10 My exit code is $exitCode" "'$myVar'"
      echo "#10 My LOG_LEVEL is $LOG_LEVEL"
    '
  )  2> logging_test.err 1> logging_test.out
  Assert $? -eq 3 "exitIf meet cond. and exit with 3"
)
Assert "'`cat logging_test.out`'" =~ \
  '"#10 exiting error message++
    #10 CleanUp 1"'
Assert "'`cat logging_test.err`'" == \
  '"#10 My exit code is 3 Khai aflk iahK
    #10 My LOG_LEVEL is 3"'

LOG_LEVEL=$LOG_LEVEL_DEBUG
Assert "'`DBG_EVAL  'echo "#11 THIS IS A DBG_EVAL Message"'`'" =~ \
  '"         DEBUG >echo \"#11 THIS IS A DBG_EVAL Message\"++
               -- #11 THIS IS A DBG_EVAL Message++"'

Assert "'`INFO_EVAL 'echo "#12 THIS IS A INFO_EVAL\\a Message"'`'" =~ \
  '"          INFO >echo \"#12 THIS IS A INFO_EVAL\\a Message\"++
                -- #12 THIS IS A INFO_EVAL\a Message++"'

Assert "'`DBG_EVAL  'echo "#13 THIS IS A DBG_EVAL Message"' 'ls clean_list'`'" =~ \
  '"         DEBUG >echo \"#13 THIS IS A DBG_EVAL Message\"++
                -- #13 THIS IS A DBG_EVAL Message++
             DEBUG >ls clean_list++
                -- clean_list++"'

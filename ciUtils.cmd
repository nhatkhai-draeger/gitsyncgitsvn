@SET _version=1.03.2222-df57fb245a
@SET _ciUtils_url=https://artifactory.draeger.com/artifactory/andover-test-tools-artifacts/ciUtils/lastbuild/ciUtils.cmd
@REM
@REM This script designed to help start run CI jobs/complex CI bash script
@REM in a minimal Windows OS environment (no bash available). Follow is the
@REM syntax
@REM
@REM ciUtils.cmd COMMAND [COMMAND_ARGUMENT...]
@REM ciUtils.cmd [/?|help|--help|-h] [COMMAND]
@REM
@REM The second command form show this help message or a specified command
@REM documentation
@REM
@REM ENVIRONMENT VARIABLES (OPTIONAL):
@REM   cacheL1     point to local folder for cache downloaded files.
@REM               Otherwise, current directory will be use.
@REM   cacheL2     point to share cache folder for downloaded files
@REM   cacheL3     Point to Artifacts cache folder for downloaded files.
@REM   cacheL3_key For write access token to Artifacts
@REM
@REM   ci_proxy    for http/https proxy server if http_proxy not specified
@REM   http_proxy  for http/https proxy server (doCurl, getCygPkg)
@REM   https_proxy for https proxy server (doCurl, getCygPkg)
@REM   no_proxy    a comma separated list of domains name not need proxy
@REM
@REM   threadGrp   Use when need to run and wait on difference group of
@REM               threads. Used by joinThread command.
@REM
@REM   CURL        specify full path of curl command
@REM   curl_cab    location of curl executable package in case curl command
@REM               not available. Can be obtain from:
@REM          * https://curl.haxx.se/dlwiz/?type=bin&os=Win32&flav=-&ver=*
@REM          * Pre-download share folder
@REM
@REM   CYGCHECK_CMD specify location of cygwin cygcheck.exe
@REM   cygwin_url  specify cygwin setup URL use for installation
@REM   cyg_mirror  point to cygwin mirror URL
@REM   cyg_cache   point to share folder cygwin downloaded pkgs.
@REM
@REM   BASH_CMD    specify location of bash.exe command
@REM
@REM COMMANDS:
@ECHO OFF
:_main

  REM Insert line trace information if CIUTILS_TRACE set
  SET _arg=%*
  CALL :escPercent _arg
  IF "%CIUTILS_TRACE%" NEQ "" IF /I "%~1"=="traceCmd" (
    SET "_traceFile=%~0" && CALL :traceCmd %_arg%
    GOTO :EOF
  )

  REM Download and run updated version of the script if it newer than one
  REM hour. Assume the _ciUtils_url are set within this file
  IF "%_ciUtils_url%" == "" GOTO :_mainSKipSelfUpdate
    SETLOCAL
    FOR %%a IN ("%~sdp0.ciutils.up.cmd") DO SET "upTime=%%~ta "
    FOR %%a IN ("%~s0"                 ) DO SET "fTime=%%~ta "
    ENDLOCAL && IF "%upTime:~,14%"=="%fTime:~,14%" GOTO :_mainSKipSelfUpdate

    IF DEFINED DEF_ENV_URL CALL :setEnvUrl "%DEF_ENV_URL%" 1>&2
    CALL :updateFile %~sdp0.ciutils.up.cmd "%_ciUtils_url%" >/NUL
    IF NOT DEFINED _ret ENDLOCAL && GOTO :_mainSKipSelfUpdate

    %~sdp0.ciutils.up.cmd %* && COPY /Y %~sdp0.ciutils.up.cmd %~s0 >/NUL
    EXIT /B 255
  :_mainSKipSelfUpdate

  IF "%~1" == ""       GOTO :_help
  IF "%~1" == "/?"     GOTO :_help
  IF "%~1" == "help"   GOTO :_help
  IF "%~1" == "-h"     GOTO :_help
  IF "%~1" == "--help" GOTO :_help

  SET _ciutils=%~s0
  CALL :%_arg% && EXIT /B 0

  IF "%http_proxy%%ci_proxy%"=="" ECHO WARN: %%http_proxy%% or %%ci_proxy%% may need
  IF "%cacheL2%%cacheL3%"    =="" ECHO WARN: %%cacheL2%% or %%cacheL3%% may need
  EXIT /B %ERRORLEVEL%


@REM   runBash    [BASH_FN_STR...]
REM FN runBash: Run a bash command
REM
REM If bash not installed in the system, it automatically install cygwin
REM bash. All to post console message before execute bash would re-direct
REM to stderr, and allow caller capture bash command output only from
REM stdout.
REM
REM @param %* bash command string
REM
REM @param %BASH_CMD%    (optional) specify location of bash.exe command.
REM                       If empty, would try look in the PATH. 
REM                       If not exist will try use Cygwin bash.
REM
REM @param %BASH_OPTS%   (optional) specify bash argument before pass
REM                      command
REM
REM @param %cygwin_url%  (optional) specify cygwin setup URL use for
REM         installation
REM @param %cyg_mirror%  (optional) point to cygwin mirror URL
REM @param %cyg_cache%   (optional) point to share folder cygwin downloaded
REM         pkgs.
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%     (optional) point to share cache folder for
REM         downloaded files
REM @param %cacheL3%     (optional) Point to Artifacts cache folder for
REM         downloaded files.
REM @param %cacheL3_key% (optional) For write access token to Artifacts
REM
REM @param %ci_proxy%    (optional) use when http_proxy not specified
REM @param %http_proxy%  (optional) for http/https proxy server for
REM @param %https_proxy% (optional) for https proxy server for
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @param %DEF_ENV_URL% (optional) URL to file provide addition
REM         environment setting. This might contribute to the installation
REM         of cygwin when needed.
REM
REM @exception exit with error code 1 if cannot find bash.exe.
REM   Otherwise, exit with error code result from executed bash command
REM
REM @return bash.exe full path that use to execute bash command in %_ret%
REM
REM @test CALL :runBash ls -al "/cygdrive/c/Program Files"
REM
:runBash
  SET _ret=
  SETLOCAL
  IF DEFINED DEF_ENV_URL CALL :setEnvUrl "%DEF_ENV_URL%" 1>&2 || GOTO :EOF

  IF NOT DEFINED BASH_CMD FOR %%a IN (bash.exe) DO SET BASH_CMD=%%~$PATH:a
  IF NOT EXIST "%BASH_CMD%" SET BASH_CMD=C:\cygwin\bin\bash.exe
  IF NOT EXIST "%BASH_CMD%" SET BASH_CMD=C:\cygwin64\bin\bash.exe
  IF NOT EXIST "%BASH_CMD%" (
    CALL :getCygPkg "%cygwin_url%" bash curl sed 1>&2 || GOTO :EOF
    IF NOT EXIST "%BASH_CMD%" SET BASH_CMD=C:\cygwin\bin\bash.exe
  )

  IF NOT EXIST "%BASH_CMD%" (
    ECHO Cannot find Bash.exe. Please specify location in BASH_CMD 1>&2
    EXIT /B 1
  )

  IF NOT DEFINED TMPDIR SET TMPDIR=%TMP%
  IF NOT EXIST "%TMPDIR%" MKDIR "%TMPDIR%" 2>/NUL
  ENDLOCAL ^
  && "%BASH_CMD%" %BASH_OPTS% -c ^
    '[[ "$TMPDIR" ]] ^&^& export TEMP="$TMPDIR"; ^
     export TMP="$TEMP"; ^
     export PATH=".:/usr/bin:/bin:$PATH"; ^
     cd "%CD:\=/%"; %*' ^
  && SET _ret=%BASH_CMD%
GOTO :EOF


@REM   runMsiUrl  [MSI_OPTION...] MSI_FILE_URL
REM FN runMsiUrl: Install/run msiexec command on a specified MSI
REM package
REM
REM @param %1..n-1 (optional) Specify MSI run options
REM @param %n Specify URL for a MSI pakcage to be run
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%     (optional) point to share folder for cache
REM         downloaded files
REM @param %cacheL3%     (optional) Point to Artifacts cache folder for
REM         downloaded files.
REM @param %cacheL3_key% (optional) For write access token to Artifacts
REM
REM @param %ci_proxy%    (optional) use when http_proxy not specified
REM @param %http_proxy%  (optional) for proxy server for http*
REM @param %https_proxy% (optional) for proxy server for https
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %curl_opts%   (optional) use to pass over to curl command
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) for curl executable package in case
REM         native curl command not available
REM
REM @exception exit if MSI error code if error occurred
REM
REM @test CALL :runMsiUrl https://osdn.mirror.constant.com//storage/g/t/to/tortoisesvn/1.13.1/Application/TortoiseSVN-1.13.1.28686-win32-svn-1.13.0.msi
REM
:runMsiUrl
  SETLOCAL

  REM Separate MSI URL and MSI Options
  SET opts=
  SET url=
  SET arg1=
  SET arg2=
  :runMsiUrlArgLoop
    SET "arg2=%arg1%"
    SET opts=%opts% %url%
    SET url=%1
    SET "arg1=%~1"
    SHIFT
  IF NOT "%~1"=="" GOTO :runMsiUrlArgLoop

  SET _arg_url="%~0"
  IF %_arg_url%=="" EXIT /B 1

  REM Try to download and run installer
  CALL :escPercent _arg_url
  CALL :download %_arg_url%
  IF ERRORLEVEL 1 GOTO :EOF
  SET "msiSetup=%_ret%"

  SET cmd=msiexec /quiet /passive %opts%
  IF NOT DEFINED arg2 SET cmd=%cmd% /i
  SET cmd=%cmd% "%msiSetup%"

  ECHO %cmd%
  %cmd%
GOTO :EOF


@REM   runUrl     EXECUTABLE_FILE_URL [ARGUMENTS...]
@REM   runUrl     ZIP_FILE_URL [CMD] [ARGUMENTS...]
REM FN runUrl: Download, unzip and execute with ARGUMENTS
REM
REM @param %1   Specify URL for a zip file or executable file
REM @param %2.. (optional) Specify arguments to pass to executable file
REM         Or command and arguments to execute within the unzipped folder
REM         of the zip file URL
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%     (optional) point to share folder for cache
REM         downloaded files
REM @param %cacheL3%     (optional) Point to Artifacts cache folder for
REM         downloaded files.
REM @param %cacheL3_key% (optional) For write access token to Artifacts
REM
REM @param %ci_proxy%    (optional) use when http_proxy not specified
REM @param %http_proxy%  (optional) for proxy server for http*
REM @param %https_proxy% (optional) for proxy server for https
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %curl_opts%   (optional) use to pass over to curl command
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) for curl executable package in case
REM         native curl command not available
REM
REM @exception exit with executable file error code if error occurred
REM
REM @note This command use powershell
REM
REM @test CALL :runUrl https://github.com/git-for-windows/git/releases/download/v2.22.0.windows.1/Git-2.22.0-64-bit.exe /VERYSILENT
REM @test CALL :runUrl https://download.sysinternals.com/files/SysinternalsSuite.zip psexec.exe -i \\COMPUTERNAME cmd /k dir
REM
:runUrl
  SETLOCAL
  SET _arg_url="%~1"
  SET opts1st=
  SET opts=
  :_runUrl_OptsLoop
    SHIFT
    IF NOT DEFINED opts1st SET "opts1st=%~1"

    REM Check if there is no space in argument, we remove quote
    SET _tmp=%1
    SET _tmp2=%_tmp: =%
    IF .%_tmp%==.%_tmp2% SET "_tmp=%~1"
    IF NOT ""%1""=="""" SET "opts=%opts% %_tmp%" && GOTO :_runUrl_OptsLoop

  IF %_arg_url%=="" EXIT /B 1

  REM Try to download and run installer
  CALL :escPercent _arg_url
  CALL :download %_arg_url%
  IF ERRORLEVEL 1 GOTO :EOF
  FOR %%a IN ("%_ret%") DO SET "cmdPath=%%~dpsa" ^
                        && SET "cmdFile="%%~nxa"" ^
                        && SET "cmdName=%%~na" ^
                        && SET "cmdLong=%%~dfa" ^
                        && SET "cmdExt=%%~xa"

  REM Check if this it is a zip file, unzip and run command
  IF NOT "%cmdExt%"==".zip" GOTO :_runUrlSkipUnzip
    SET "cmdPath=%cmdPath%%cmdName%"
    SET PATH=%PATH%:%PS_INST_DEF%
    IF NOT EXIST "%cmdPath%\" powershell Expand-Archive ^
      -Path "%_ret%" -DestinationPath "%cmdPath%" ^
      || GOTO :EOF

    SET cmdFile=
    FOR %%a IN ("%opts1st%") DO SET cmdExt=%%~xa
  :_runUrlSkipUnzip

  REM If a batch script, we should use CALL instead of generic start
  SET preStart=START "" /WAIT /B
  IF "%cmdExt%"==".cmd" SET preStart=CALL
  IF "%cmdExt%"==".bat" SET preStart=CALL
  IF NOT DEFINED cmdExt SET preStart=%preStart% cmd /C

  REM Modify PATHEXT to force system to try execute the command
  IF NOT DEFINED cmdExt SET cmdExt=.
  SET "PATHEXT=%PATHEXT%;%cmdExt%"
  SETLOCAL EnableDelayedExpansion
  FOR %%a IN (%cmdExt%) DO SET "PATHEXT=!PATHEXT:;%%a;=!"
  ENDLOCAL && SET "PATHEXT=%PATHEXT%"

  ECHO "%cmdLong%"%opts%
  ENDLOCAL && SET "cmdPath=%cmdPath%" ^
    && SET "PATHEXT=%PATHEXT%" ^
    && SET _myCmd=%preStart% %cmdFile%%opts%

  PUSHD "%cmdPath%" || GOTO :EOF
  %_myCmd%
  POPD
GOTO :EOF


@REM   runOnce    COMMAND [OPTIONS...]
REM FN runOnce: Try the command once, and create a mark to avoid run
REM again next time calling
REM
REM @param %1   Specify function
REM @param %2.. (Optional) Function arguments
REM
REM @param %InstIdsPath% (Optional) Local file path for tracking which
REM         location to store the mark file.
REM
REM @exception exit with specified function error code if error occurred
REM
REM @note This command use certutil
REM
REM
:runOnce
  SETLOCAL
  CALL :_getPID
  DEL /F .%PID%.runOnce >/NUL 2>&1
  :_runOnce_loop
    SET "_arg=%~1"
    CALL :escapeVar _arg
    (ECHO %_arg%)>> .%PID%.runOnce
    SHIFT
    IF NOT "%~1"=="" GOTO :_runOnce_loop

  IF NOT DEFINED InstIdsPath SET InstIdsPath=%PUBLIC%
  FOR /F "tokens=1,*" %%a IN ('certutil -hashfile .%PID%.runOnce MD5'
  ) DO IF "%%b"=="" SET md5=%InstIdsPath%\.runOnce.%%a
  DEL /F .%PID%.runOnce >/NUL 2>&1
  IF EXIST "%md5%" EXIT /B 0

  SET _arg=%*
  CALL :escPercent _arg
  CALL :%_arg% || GOTO :EOF

  (ECHO.%*)> "%md5%"
  IF NOT EXIST "%md5%" ECHO WARN: Can't create file on %InstIdsPath%
  EXIT /B 0


@REM   runCmdOnce BATCH_COMMAND [OPTIONS...]
REM FN runCmdOnce: Try the batch command once, and create a mark to avoid
REM run again next time calling
REM
REM @param %1   Specify batch command
REM @param %2.. (Optional) Function arguments
REM
REM @param %InstIdsPath% (Optional) Local file path for tracking which
REM         location to store the mark file.
REM
REM @exception exit with specified function error code if error occurred
REM
REM @note This command use certutil
REM
REM
:runCmdOnce
  SETLOCAL
  CALL :_getPID
  DEL /F .%PID%.runCmdOnce >/NUL 2>&1
  :_runCmdOnce_loop
    SET "_arg=%~1"
    CALL :escapeVar _arg
    (ECHO %_arg%)>> .%PID%.runCmdOnce
    SHIFT
    IF NOT "%~1"=="" GOTO :_runCmdOnce_loop

  IF NOT DEFINED InstIdsPath SET InstIdsPath=%PUBLIC%
  FOR /F "tokens=1,*" %%a IN ('certutil -hashfile .%PID%.runCmdOnce MD5'
  ) DO IF "%%b"=="" SET md5=%InstIdsPath%\.runCmdOnce.%%a
  DEL /F .%PID%.runCmdOnce >/NUL 2>&1
  IF EXIST "%md5%" EXIT /B 0

  %* || GOTO :EOF

  (ECHO.)> "%md5%"
  IF NOT EXIST "%md5%" ECHO WARN: Can't create file on %InstIdsPath%
  EXIT /B 0


@REM
@REM   getVsPkg   Install Visual Studio Packages
REM FN getVsPkg:  Install Visual Studio Package
REM
REM @param %1     Installer URL
REM @param %2..n  (optional) Specify a set of component IDs or packages to
REM               be install. Reference for all available was listed here:
REM               https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community
REM @param %n..   (optional) installer options
REM
REM @param %vsLayout%      (optional) specific share folder for installer
REM         layout / cached download file by the installer
REM
REM @param %vsInstIdsPath% (optional) local file path for tracing which
REM         components had been installed in the local machine
REM @param %InstIdsPath%   (optional) Local file path for tracking which
REM         location to store the mark file when vsInstIdsPath did not
REM         supplied.
REM
REM @param %cacheL1%       (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%       (optional) point to share folder of downloaded
REM         files
REM @param %cacheL3%       (optional) Point to Artifacts cache folder for
REM         downloaded files.
REM @param %cacheL3_key%   (optional) For write access token to Artifacts
REM
REM @param %ci_proxy%      (optional) use when http_proxy not specified
REM @param %http_proxy%    (optional) for proxy server for http*
REM @param %https_proxy%   (optional) for proxy server for https
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %curl_opts%     (optional) use to pass over to curl command
REM @param %CURL%          (optional) specify full path of curl command
REM @param %curl_cab%      (optional) for curl executable package in case
REM         native curl command not available
REM
REM @return %_ret% array of installed packages. Otherwise, nothing had been
REM           added/installed
REM @return %_retVsID% a MD5 id base on the Installer URL
REM
REM @exception error code for failure of installation. Exit Code are
REM     defined here https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022#error-codes
REM
REM     Follow error of 1641, 3010 from vs_setup will convert to error code
REM     of 0.
REM
REM @note
REM   #  Know work for 2017, 2019 version
REM   #  Following batch command would be used:
REM   ## sort
REM   ## certutil
REM   ## powershell
REM
REM @test CALL :getVsPkg ^^
REM         "https://visualstudio.com/thank-you-downloading-visual-studio/?sku=Professional&rel=15" ^^
REM         Microsoft.Component.MSBuild  ^
REM         Microsoft.VisualStudio.Component.Roslyn.Compiler  ^
REM         Microsoft.VisualStudio.Component.TestTools.Core ^
REM         Microsoft.VisualStudio.Component.NuGet
REM
:getVsPkg
  SETLOCAL
  CALL :_getPID
  IF NOT DEFINED cacheL1 FOR %%a IN ("%TMP%") DO SET cacheL1=%%~sa\.cache
  IF NOT EXIST "%cacheL1%" MKDIR "%cacheL1%"

  REM Process function parameters
  SET _arg_vsInstallerURL="%~1"
  SET "_ech_vsInstallerURL=%~1"
  SHIFT

  REM Calculate MD5 from URL
  CALL :escapeVar _ech_vsInstallerURL
  (ECHO %_ech_vsInstallerURL%)>.%PID%.getVsPkg
  FOR /F "tokens=1,*" %%a IN ('certutil -hashfile .%PID%.getVsPkg MD5'
                             ) DO IF "%%b"=="" SET md5=%%a
  DEL /F .%PID%.getVsPkg >/NUL 2>&1
  SET _retVsID=%md5:~0,10%

  REM Fill in optional parameters using MD5 of the installer URL
  IF NOT DEFINED InstIdsPath   SET InstIdsPath=%PUBLIC%
  IF NOT DEFINED vsInstIdsPath SET vsInstIdsPath=%InstIdsPath%\vs.ids.%_retVsID%

  IF NOT DEFINED vsLayout IF DEFINED cacheL2 SET ^
    vsLayout=%cacheL2%\vs.install.%_retVsID%

  IF NOT DEFINED vsLayout IF DEFINED cacheL1 SET ^
    vsLayout=%cacheL1%\vs.install.%_retVsID%

  SET vsPkgs=
  SET vsOpts=
  SET _tmpFile=%CD%\.vs.ids.%PID%
  DEL /F "%_tmpFile%" >/NUL 2>&1
  (ECHO DEL /F "%_tmpFile%" 2^>/NUL) >> .cleanup%threadGrp%.cmd
  COPY /Y "%vsInstIdsPath%" "%_tmpFile%" >/NUL
  :_getVsPkg_parsePkg
    IF _%1==_ GOTO :_getVsPkg_parseArgDone
    SET "_tmp=%~1"
    SET "_tmp=%_tmp:~0,1%"
    IF "%_tmp%"=="-" GOTO :_getVsPkg_parseOpts
    SET vsPkgs=%vsPkgs% --add %1
    (ECHO.%~1) >> "%_tmpFile%"
    (ECHO.%~1) >> "%_tmpFile%"
    SHIFT
    GOTO :_getVsPkg_parsePkg

  :_getVsPkg_parseOpts
    IF _%1==_ GOTO :_getVsPkg_parseArgDone
    SET vsOpts=%vsOpts% "%~1"
    SHIFT
    GOTO :_getVsPkg_parseOpts

  :_getVsPkg_parseArgDone

  REM Find out weather requested package already installed or not
  REM Also generate a %_tmpFile% with sorted and unique list of packages
  "%ComSpec%\..\sort.exe" "%_tmpFile%" /O "%_tmpFile%.tmp" 2>/NUL
  (ECHO. ) >> "%_tmpFile%.tmp"
  REM If package show up exactly 2 times (not 3 or 1), it should mean we
  REM have module that had not installed
  SETLOCAL EnableDelayedExpansion
  SET _lst1=
  SET _lst2=
  SET _lst3=
  SET _delta=
  ( FOR /F "delims=" %%a IN (%_tmpFile%.tmp) DO (
      IF NOT "%%a"=="!_lst1!" (
        IF NOT "%%a"==" " ECHO.%%a
        IF NOT "!_lst1!"=="!_lst3!" IF "!_lst1!"=="!_lst2!" SET ^
          _delta=!_delta! "!_lst1!"
        SET _lst2=
        SET _lst1=
      )
      SET _lst3=!_lst2!
      SET _lst2=!_lst1!
      SET _lst1=%%a
    )
  ) 1> "%_tmpFile%"
  DEL /F "%_tmpFile%.tmp" >/NUL 2>&1

  REM No thing needed to be installed
  IF NOT DEFINED _delta EXIT /B 0
  ENDLOCAL && SET _delta=%_delta%

  REM Visual Studio install using system setting proxy if any
  REM Below call may require restart the console for proxy change apply
  CALL :configWinProxy
  IF ERRORLEVEL 1 GOTO :EOF

  REM Check if we need to create layout folder of not exist
  SET vsInstaller=%vsLayout%\vs_setup.exe
  IF EXIST "%vsInstaller%" GOTO :_getVsPkg_skip_layout
    ECHO Creating Visual Studio Layout...
    CALL :escPercent _arg_vsInstallerURL
    CALL :download %_arg_vsInstallerURL% "/vs_.*\.exe" >/NUL
    IF ERRORLEVEL 1 GOTO :EOF
    FOR %%a IN ("%_ret%") DO IF NOT "%%~xa"==".exe" (
      COPY /Y "%_ret%" "%_ret%.exe" >/NUL
      SET "_ret=%_ret%.exe"
    )
    FOR %%a IN ("%_ret%") DO SET _ret=%%~fsa
    SET vscmd=%_ret% --wait --quiet
    IF DEFINED vsLayout SET ^
      vscmd=%vscmd% --layout "%vsLayout%" --lang En-Us --locale En-Us
    SET vscmd=%vscmd% %vsPkgs%
    ECHO   %vscmd%
    START /WAIT /B "" %vscmd%
    IF ERRORLEVEL 1 GOTO :EOF
    IF NOT EXIST "%vsInstaller%" SET vsInstaller=%_ret%
  :_getVsPkg_skip_layout

  REM Update visual studio to ensure its current installed version is
  REM compatible with current layout for add addition components
  IF NOT EXIST "%vsInstIdsPath%" GOTO :_getVsPkg_skip_update
    ECHO Update Visual Studio...
    "%vsInstaller%" update --wait --quiet --norestart
    IF ERRORLEVEL 1 ECHO   Return Code: %ERRORLEVEL%
  :_getVsPkg_skip_update

  ECHO Installing Visual Studio...
  DEL /F "%TMP%\dd_installer_*" >/NUL 2>&1
  IF NOT DEFINED vsOpts SET vsOpts=--norestart
  SET vscmd="%vsInstaller%" --wait --quiet %vsPkgs% %vsOpts%
  ECHO   %vscmd%
  START /WAIT /B "" %vscmd%
  IF ERRORLEVEL 1 ECHO   Return Code: %ERRORLEVEL%

  REM Ignore some of errors
  REM 3010, 1641 - system need to restart or restarting
  IF %ERRORLEVEL% EQU 1641 GOTO :_getVsPkg_done
  IF %ERRORLEVEL% EQU 3010 GOTO :_getVsPkg_done
  IF ERRORLEVEL 1 TYPE "%TMP%\dd_installer_*" && EXIT /B %ERRORLEVEL%

  :_getVsPkg_done
  REM Update installed component IDs
  SET _ret=%_delta%
  COPY /Y "%_tmpFile%" "%vsInstIdsPath%" >/NUL
  DEL /F "%_tmpFile%" >/NUL 2>&1
  IF NOT EXIST "%vsInstIdsPath%" ECHO WARN: Can't create file %vsInstIdsPath%

  ENDLOCAL && SET _ret=%_delta% && SET "_retVsID=%_retVsID%"
  EXIT /B 0


@REM   getCygPkg  SETUP_EXE_URL [CYGWIN_PACKAGE...]
REM FN getCygPkg: Install cygwin and specified packages not needed
REM
REM @param %1    cygwin executable setup URL. When empty string, the
REM         default hard coded cygwin URL will be use.
REM @param %2.. (optional) list of cygwin packages. The list was found here:
REM         https://cygwin.com/packages/package_list.html
REM
REM @param %cyg_mirror%   (optional) point to cygwin mirror URL
REM @param %cyg_cache%    (optional) point to share folder cygwin
REM         downloaded pkgs.
REM @param %CYGCHECK_CMD% (optional) location of cygwin cygcheck.exe
REM
REM @param %cacheL1%      (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%      (optional) point to share cache folder for
REM         downloaded files
REM @param %cacheL3%      (optional) Point to Artifacts cache folder for
REM         downloaded files.
REM @param %cacheL3_key%  (optional) For write access token to Artifacts
REM
REM @param %ci_proxy%     (optional) use when http_proxy not specified
REM @param %http_proxy%   (optional) for http proxy server for
REM @param %https_proxy%  (optional) for https proxy server for
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %curl_opts%    (optional) use to pass over to curl command
REM @param %CURL%         (optional) specify full path of curl command
REM @param %curl_cab%     (optional) location of curl executable package in
REM         case curl command not available
REM
REM @exception error code for failure of installation
REM
REM @note Following batch command would be used:
REM   ## sort
REM   ## fc
REM   ## certutil
REM
REM @test CALL :getCygPkg "https://cygwin.com/setup-x86.exe" bash curl sed
REM
:getCygPkg
  SETLOCAL
  SET _arg=%*
  CALL :escPercent _arg

  REM Try to check of the Cygwin module already exist
  IF NOT DEFINED CYGCHECK_CMD   SET CYGCHECK_CMD=C:\cygwin\bin\cygcheck.exe
  IF NOT EXIST "%CYGCHECK_CMD%" SET CYGCHECK_CMD=C:\cygwin64\bin\cygcheck.exe
  IF EXIST "%CYGCHECK_CMD%" (
    DEL /F .reqsMods >/NUL 2>&1
    CALL :getCygPkgGenReqsModsLoop %_arg%
    (ECHO Cygwin)>> .reqsMods
    (ECHO Package)>> .reqsMods
    "%ComSpec%\..\sort.exe" .reqsMods /O .reqsMods

    "%CYGCHECK_CMD%" -c -d %* > .cygMods1
    (ECHO.%1)> .cygMods
    FOR /F %%a IN (.cygMods1) DO ECHO.%%a>> .cygMods
    DEL /F .cygMods1
    "%ComSpec%\..\sort.exe" .cygMods /O .cygMods

    "%ComSpec%\..\fc.exe" .reqsMods .cygMods 2>&1 1>/NUL
    IF NOT ERRORLEVEL 1 (
      DEL /F .reqsMods .cygMods
      EXIT /B 0
    )
    DEL /F .reqsMods .cygMods
  )

  REM Join remain arguments after the 1st with comma
  SET cygMods=%2
  :getCygPkgArgModsLoop
    SHIFT /2
    IF "%~2"=="" GOTO :getCygPkgArgModsLoopDone
    SET cygMods=%cygMods%,%2
    GOTO :getCygPkgArgModsLoop
  :getCygPkgArgModsLoopDone

  SET _arg_url="%~1"
  IF %_arg_url% == "" (
    IF "%PROCESSOR_ARCHITECTURE%" == "x86" (
      SET _arg_url="https://cygwin.com/setup-x86.exe"
    ) ELSE (
      SET _arg_url="https://cygwin.com/setup-x86_64.exe"
    )
  )

  REM Try to download and run installer
  CALL :escPercent _arg_url
  CALL :download %_arg_url%
  IF ERRORLEVEL 1 GOTO :EOF
  FOR %%a IN ("%_ret%") DO SET cygSetup=%%~dpsa\%%~nxa
  SET opts=--quiet-mode --no-desktop --no-shortcuts --no-startmenu --only-site

  IF NOT DEFINED http_proxy SET http_proxy=%ci_proxy%
  IF     DEFINED http_proxy SET opts=%opts% --proxy "%http_proxy%"

  IF NOT DEFINED cyg_mirror (
    SET opts=%opts% --site "http://cygwin.mirror.constant.com"
  ) ELSE (
    SET opts=%opts% --site "%cyg_mirror%"
  )

  IF NOT DEFINED cyg_cache  (
    IF     DEFINED cacheL2 SET^
    opts=%opts% --local-package-dir "%cacheL2%\cygwin"
  ) ELSE (
    SET opts=%opts% --local-package-dir "%cyg_cache%"
  )

  SET opts=%opts% -P %cygMods%
  ECHO "%cygSetup%" %opts%
  "%cygSetup%" %opts%
  GOTO :EOF

  REM Sub function for getCygPkg
  :getCygPkgGenReqsModsLoop
    (ECHO.%1)>> .reqsMods
    SHIFT
  IF NOT "%~1"=="" GOTO :getCygPkgGenReqsModsLoop
  EXIT /B 0


@REM
@REM   download   FILE_URL [REGEX_FILE_URL]
REM FN download: Try to download a file from specified url into
REM %cacheL1% or current directory
REM
REM First it will check if the file exist in %cacheL1%, then %cacheL2%,
REM then %cacheL3%, and then try to use curl command to download the
REM specified URL file
REM
REM @param %1 specified URL
REM @param %2 (optional) specify expected regex download file name to help
REM           guess the download link that embedded in the %1 URL
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded file. Otherwise, current directory will be use
REM @param %cacheL2%     (optional) point to share folder for cache
REM         downloaded files.
REM @param %cacheL3%     (optional) Point to Artifacts cache folder for
REM         downloaded files.
REM @param %cacheL3_key% (optional) For write access token to Artifacts
REM
REM @param %ci_proxy%    (optional) use when http_proxy not specified
REM @param %http_proxy%  (optional) for http proxy server for
REM @param %https_proxy% (optional) for https proxy server for
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %curl_opts%   (optional) use to pass over to curl command
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @return A full path of downloaded file saved in %_ret%.
REM @exception exit with ERRORLEVEL if fail
REM
REM @note This command use powershell
REM
REM @test CALL :download "https://cygwin.com/setup-x86.exe"
REM
:download
  SETLOCAL

  SET "url=%~1"
  SET "fileRegex=%~2"

  IF NOT DEFINED fileRegex GOTO :_download_skip_fileRegex
    REM Download the specify url into a file, and search for links that
    REM match fileRegex
    set _arg="%url%"
    CALL :escPercent _arg
    CALL :download %_arg%

    REM Search for real url from supplied %fileRegex%
    SET "new_url="
    SET "psCmd=        ("
    SET "psCmd=%psCmd%   Get-Content '%_ret%' | Select-String -Pattern"
    SET "psCmd=%psCmd%   '[''""](http[s]?://[^''""]*%fileRegex%)[''""]'"
    SET "psCmd=%psCmd% ).Matches.Groups[1].Value"

    SET PATH=%PATH%:%PS_INST_DEF%
    FOR /F "delims=" %%a IN ('powershell.exe -Command "%psCmd%"'
                            ) DO SET "new_url=%%a"
    IF "%new_url%"==" " SET "new_url="
    IF NOT DEFINED new_url (
      ECHO WARN: Cannot find "%fileRegex%" in "%url%"
      ENDLOCAL && SET "_ret=%_ret%" && EXIT /B 0
    )

    REM Real url found
    SET "url=%new_url%"
  :_download_skip_fileRegex

  REM Normalize URL to a valid file path
  SET "outFile=%url%"
  SET "outFile=%outFile:/=\%"
  SET "outFile=%outFile::=%"
  SET "outFile=%outFile:+=+0%"
  SET "outFile=%outFile:?=\+1%"
  SET "outFile=%outFile:>=+1%"
  SET "outFile=%outFile:<=+2%"
  SET "outFile=%outFile:|=+3%"
  :_download_remove_star
  FOR /F "tokens=1* delims=*" %%a IN ("%outFile%") DO (
    IF NOT "%%b"=="" SET outFile=%%a+4%%b
    IF NOT "%%b"=="" GOTO :_download_remove_star
    )
  SET "outFile=%outFile:!=+5%"
  SET "outFile=%outFile:^^=+6%"
  SET "outFile=%outFile:&=+7%"
  SET "outFile=%outFile:\\=\%"

  REM Check if the file already exist locally, then avoid download
  IF NOT DEFINED cacheL1 FOR %%a IN ("%TMP%") DO SET cacheL1=%%~sa\.cache
  FOR %%a IN ("%cacheL1%\%outFile%") DO (
    MKDIR "%%~dpa" 2>/NUL
    SET l1file=%%~dpnxa
  )
  IF EXIST "%l1file%" ENDLOCAL && SET "_ret=%l1file%" && EXIT /B 0

  SET l3file=
  IF DEFINED cacheL3 SET l3file=%cacheL3%/%outFile:\=/%

  REM Try to take file from cache L2
  SET l2file=
  IF NOT DEFINED cacheL2 GOTO :_download_SkipL2
    CALL :getLocalPath "%cacheL2%" "%cacheL2_user%" "%cacheL2_pw%"
    SET "cacheL2=%_ret%"

    FOR %%a IN ("%cacheL2%\%outFile%") DO (
      MKDIR "%%~dpa" 2>/NUL
      SET l2file=%%~dpnxa
      SET filename=%%~nxa
    )
    IF NOT EXIST "%l2file%" GOTO :_download_SkipL2

    COPY /Y "%l2file%" "%l1file%" >/NUL 2>&1 ^
      || ENDLOCAL && SET "_ret=" && GOTO :EOF
    ECHO Copy "%filename%" from "%cacheL2%" to "%l1file%"

    SET _arg="%l3file%" -T "%l1file%" -x ""
    IF DEFINED cacheL3_key SET _arg=%_arg% "-u%cacheL3_key%"
    CALL :escPercent _arg
    IF DEFINED l3file CALL :runThread %_ciutils% doCurl %_arg% ^
      && ECHO Save "%filename%" into "%l3file%"

    ENDLOCAL && SET "_ret=%l1file%" && EXIT /B 0
  :_download_SkipL2

  REM Try to take file from cache L3
  IF NOT DEFINED l3file GOTO :_download_SkipL3
    REM Check is the file exist on server
    SET _arg="%l3file%" -o nul --silent --fail -r 0-0 -m 2 -x ""
    CALL :escPercent _arg
    CALL :doCurl %_arg%
    IF ERRORLEVEL 1 GOTO :_download_SkipL3

    REM Try to download from cacheL3
    SET _arg="%l3file%" -o "%l1file%.dl" ^
      --fail -x "" %curl_opts%
    CALL :escPercent _arg
    CALL :doCurl %_arg%
    IF ERRORLEVEL 1 GOTO :_download_SkipL3
    MOVE /Y "%l1file%.dl" "%l1file%" >/NUL ^
      || ENDLOCAL && SET "_ret=" && GOTO :EOF
    ECHO Download "%filename%" from "%cacheL3%" to "%l1file%"

    REM Update cache L2
    IF DEFINED l2file COPY /Y "%l1file%" "%l2file%" >/NUL 2>&1 ^
      && ECHO Save "%filename%" into "%l2file%"
    ENDLOCAL && SET "_ret=%l1file%" && EXIT /B 0
  :_download_SkipL3

  REM Try to download the file
  REM
  REM Windows Curl seem to not able to handle the long file name, so we use
  REM short file name when pass into curl
  ECHO.> "%l1file%.dl"
  FOR %%a IN ("%l1file%.dl") DO SET _l1_dls=%%~sa
  SET _arg="%url%" -o "%_l1_dls%" --fail --location %curl_opts%

  CALL :escPercent _arg
  CALL :doCurl %_arg%
  IF ERRORLEVEL 1 ENDLOCAL && SET "_ret=" && EXIT /B %ERRORLEVEL%
  MOVE /Y "%l1file%.dl" "%l1file%" >/NUL ^
    || ENDLOCAL && SET "_ret=" && GOTO :EOF
  ECHO Download "%filename%" to "%l1file%"

  REM Update cache L2 & L3
  IF DEFINED l2file COPY /Y "%l1file%" "%l2file%" >/NUL 2>&1 ^
    && ECHO Save "%filename%" into "%l2file%"

  FOR %%a IN ("%l1file%") DO SET _l1s=%%~sa
  SET _arg="%l3file%" -T "%_l1s%" -x ""
  IF DEFINED cacheL3_key SET _arg=%_arg% "-u%cacheL3_key%"
  CALL :escPercent _arg
  IF DEFINED l3file CALL :runThread %_ciutils% doCurl %_arg% ^
    && ECHO Save "%filename%" into "%l3file%"

ENDLOCAL && SET "_ret=%l1file%" && EXIT /B 0


@REM   updateFile LOCAL_FILE [FILE_URL...]
REM FN updateFile: Try to update the content of file URLs if possible
REM
REM 1. Try curl the file into tmp, If not found goto #3
REM 2. Overwrite the local file with one in tmp
REM 3. Return error if local file not exist, otherwise no error
REM
REM
REM @param %1   specify local file
REM @param %2.. specify URLs where it can be download to update the content
REM             of local file
REM
REM @param %ci_proxy%    (optional) use when http_proxy not specified
REM @param %http_proxy%  (optional) for http proxy server for
REM @param %https_proxy% (optional) for https proxy server for
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %curl_opts%   (optional) use to pass over to curl command
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @return the URL that use to update the local file in %_ret%.
REM @exception exit with ERRORLEVEL if local file did not exist after try
REM update it
REM
REM @test CALL :updateFile test.txt "http://att/Distribution/Config/env/developer.txt"
REM
:updateFile
  SETLOCAL

  SET "localFile=%~1"
  IF "%~2"=="" GOTO :_updateFile_Loop_End
  CALL :_getPID
  SET "dl=%localFile%.%PID%.dl"
  SET "dlMark=%dl%.mark"

  REM Get current system time. Assume file time fmt: "03/08/2023 04:50 PM"
  ECHO.>"%dl%"
  FOR %%a IN ("%dl%"       ) DO SET "curTime=%%~ta "
  DEL /F "%dl%" >/NUL 2>&1

  REM Skip update if the file already been downloaded 10 minute ago
  FOR %%a IN ("%localFile%") DO SET "fTime=%%~ta "
  IF "%curTime:~,15%"=="%fTime:~,15%" ENDLOCAL && SET "_ret=" && EXIT /B 0

  REM Skip download if already failed within 10 minute ago
  FOR %%a IN ("%dlMark%") DO SET "fTime=%%~ta "
  IF "%curTime:~,15%"=="%fTime:~,15%" GOTO :_updateFile_Loop_End

  ECHO.>"%dlMark%"
  :_updateFile_Loop
    SET "url=%~2"
    SHIFT

    REM Try to download the file
    SET _arg="%url%" -o "%dl%" ^
      --fail --location --silent %curl_opts%
    CALL :escPercent _arg
    CALL :doCurl %_arg%
    IF NOT ERRORLEVEL 1 (
      MOVE /Y "%dl%" "%localFile%" >/NUL
      IF NOT ERRORLEVEL 1 (
        DEL /F "%dlMark%" >/NUL 2>&1
        ECHO Download "%url%" to "%localFile%"
        ENDLOCAL && SET "_ret=%url%" && EXIT /B 0
      )
    )

    IF NOT "%~2"=="" GOTO :_updateFile_Loop
  :_updateFile_Loop_End

  IF NOT EXIST "%localFile%" ENDLOCAL && SET "_ret=" && EXIT /B 1
ENDLOCAL && SET "_ret=" && EXIT /B 0


@REM   doCurl     URL [CURL_OPTION...]
@REM
REM FN doCurl: Run curl command
REM
REM @param %1 Specified URL for download
REM @param %2.. (Optional) addition curl arguments
REM
REM @param %ci_proxy%    (optional) use when http_proxy not specified
REM @param %http_proxy%  (optional) for http proxy server for
REM @param %https_proxy% (optional) for https proxy server for
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @param %cacheL1%     (optional) point to local folder for cache custom
REM         executable curl command. Otherwise, current directory will be
REM         use.
REM
REM @note curl_cab only support .CAB file. One can obtain CAB file from:
REM   * https://curl.haxx.se/dlwiz/?type=bin&os=Win32&flav=-&ver=*
REM   * Pre-download share folder
REM
REM @exception exit with ERRORLEVEL if fail
REM
REM @test CALL :doCurl "https://cygwin.com/setup-x86.exe" -o setup-x86.exe
REM
:doCurl
  SETLOCAL
  IF NOT DEFINED CURL FOR %%a IN (%ComSpec%\..\curl.exe
    ) DO IF EXIST %%~fa SET CURL=%%~fa
  IF NOT DEFINED CURL FOR %%a IN (curl.exe) DO SET CURL=%%~$PATH:a
  IF     DEFINED CURL GOTO :_doCurl_skipCurlCab
  IF NOT DEFINED curl_cab GOTO :_doCurl_skipCurlCab
    IF NOT DEFINED cacheL1 FOR %%a IN ("%TMP%") DO SET cacheL1=%%~sa\.cache
    IF NOT EXIST "%cacheL1%" MKDIR "%cacheL1%"

    SET CURL=%cacheL1%/curl/I386/curl.exe
    SET "PATH=%SystemRoot%\System32;%PATH%"
    IF NOT EXIST "%CURL%" (
      ECHO Extract the CAB Package and use it
      PUSHD "%cacheL1%" || GOTO :EOF

      COPY /Y "%curl_cab%" "curl.cab" >/NUL 2>&1 || POPD && GOTO :EOF

      IF NOT EXIST curl MKDIR curl || POPD && GOTO :EOF

      expand curl.cab -F:* curl || POPD && GOTO :EOF
      POPD
    )
  :_doCurl_skipCurlCab

  IF NOT EXIST "%CURL%" (
    ECHO CANNOT FIND CURL COMMAND. Please set %%CURL%%, or %%curl_cab%%
    ECHO   %%CURL%% to specified location of curl.exe
    ECHO   %%curl_cab%% to specified location of curl package for install
    EXIT /B 1
  )

  REM Determine which proxy to use
  SET "_url=%~1"

  IF NOT DEFINED no_proxy GOTO :_doCurl_skipCheckNoProxy
    SET use_proxy=
    SET no_proxy=%no_proxy:,= %
    SETLOCAL EnableDelayedExpansion
    FOR %%d IN (%no_proxy%) DO (
      SET new_url=!_url://%%d/=!
      IF NOT "!new_url!" == "!_url!" ENDLOCAL && GOTO :_doCurl_skipProxy
    )
    ENDLOCAL
  :_doCurl_skipCheckNoProxy

  IF NOT DEFINED https_proxy GOTO :_doCurl_skiphttps
    SET protocol=
    FOR /F "delims=:" %%a IN ("%_url%") DO SET protocol=%%a
    IF "%protocol:~-1%"=="s" SET http_proxy=%https_proxy%
  :_doCurl_skiphttps
  IF NOT DEFINED http_proxy SET http_proxy=%ci_proxy%
  IF     DEFINED http_proxy SET use_proxy=-x "%http_proxy%"

  :_doCurl_skipProxy
  SETLOCAL DisableDelayedExpansion
  ECHO "%CURL%" %use_proxy% %*
  "%CURL%" %use_proxy% %*
GOTO :EOF


@REM   setEnvUrl  [FILE_URL...]
REM FN setEnvUrl: Set Environment using a INI file from one of
REM specified URLs
REM
REM
REM @param %1.. specify URLs where INI file can be download
REM
REM @param %http_proxy%  (optional) for http proxy server for
REM @param %https_proxy% (optional) for https proxy server for
REM @param %no_proxy%    (optional) comma separated list of domains name
REM         should not use proxy
REM @param %curl_opts%   (optional) use to pass over to curl command
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @return %cacheL1%\.envVars file contains variables extracted from URL
REM         link.
REM         %_ret% the URLs that was downloaded and set to Environment.
REM
REM @exception exit with ERRORLEVEL if no accessible INI files
REM
REM @test CALL :setEnvUrl "http://att/Distribution/Config/env/developer.txt"
REM
:setEnvUrl
  SETLOCAL

  REM Download into a .envVars file
  IF NOT DEFINED cacheL1 FOR %%a IN ("%TMP%") DO SET cacheL1=%%~sa\.cache
  IF NOT EXIST "%cacheL1%" MKDIR "%cacheL1%"

  SET ci_proxy=
  SET _arg=%*
  CALL :escPercent _arg
  CALL :updateFile "%cacheL1%\.envVars" %_arg%
  IF ERRORLEVEL 1 GOTO :EOF

  ENDLOCAL && CALL :setEnvPropFile "%cacheL1%\.envVars" "%_ret%"
  EXIT /B 0


@REM   setEnvPropFile [PROP_FILE_PATH] [SHOW]
REM FN setEnvPropFile: Set Environment using a INI file from specified file
REM
REM
REM @param %1 specify PROP_FILE_PATH where INI file can access
REM @param %2 (optional) If not empty, print each variables name and value
REM
REM @return %_ret% the value passed from %2
REM
:setEnvPropFile
  CALL :_getPID
  SETLOCAL EnableDelayedExpansion
  FOR /F %%a in ("%~1") DO ( SET "envDir=%%~dpa" && SET "envFile=%%~snxa" )

  REM Remove special characters "\\"
  PUSHD "%envDir%" || GOTO :EOF
  DEL /F .%envFile%.%PID%.tmp >/NUL 2>&1
  FOR /F "tokens=1,* delims== " %%a IN (%envFile%) DO (
    SET val=%%b
    IF NOT "!val!"=="" SET "val=!val:\\=\!"
    IF NOT "%%~a"=="INFO" IF NOT "%%~a"=="NOTE" ECHO %%a=!val!
  ) 1>>.%envFile%.%PID%.tmp || POPD && EXIT /B 1
  POPD

  REM Pares and set them
  ENDLOCAL && PUSHD "%envDir%"
  FOR /F %%e IN ("%~1") DO (
    FOR /F "tokens=1,* delims== " %%a IN (.%%~snxe.%PID%.tmp) DO (
      SET %%a=%%b
      IF NOT "%~2"=="" ECHO.SET %%a=%%b
    )
    DEL /F .%%~snxe.%PID%.tmp >/NUL 2>&1
  )
  POPD
  SET "_ret=%~2"
  EXIT /B 0


@REM   insertPath Insert a path into PATH if new
REM FN insertPath: Insert a path into PATH only if it new
REM
REM @param %1 is path need to be added into PATH
REM
REM @remark Use to tell system flavor program in specific path first while
REM allow honoring current priority that may had configured externally.
REM
REM @note Passing multiple Paths at once would speed up the process
REM
:insertPath
  IF ""%1""=="""" EXIT /B 0
  IF "%~1"=="" SHIFT && GOTO :insertPath
  SETLOCAL EnableDelayedExpansion
  SET PATH2=!PATH:%~f1;=!
  ENDLOCAL && IF "%PATH2%"=="%PATH%" SET PATH=%~f1;%PATH%
  SHIFT
GOTO :insertPath


@REM   applyCfg   CFG_CMD [CFG_FLAG] [KEY_VALUE_PAIRS..]
REM FN applyCfg: run specify command on a list of key and value pairs
REM
REM @param %1 Config command
REM @param %2.. Specify a list of key and value pairs, or flags
REM
REM @test CALL :applyCfg "git config" --system
REM
:applyCfg
  SETLOCAL
  SET cfg_flag=
  SET cfg_cmd=%~1
  SHIFT
  :_applyCfgLoop
    IF "%~1"=="" EXIT /B 0

    SET name=%~1
    IF "%name:~0,2%"=="--" (
      SET cfg_flag= %1
    ) ELSE (
      %cfg_cmd%%cfg_flag% %1 %2 || GOTO :EOF
      SHIFT
    )
    SHIFT
  GOTO :_applyCfgLoop


@REM   showEnv    RIGTH_ALIGN [ENV_VAR_NAMEs...]
REM FN showEnv: List all specified
REM environments variables
REM
REM @param %1 Specified right alignment for each variables name (80 max)
REM @param %2.. (Optional) environment variables names
REM
REM @test CALL :showEnv 18 PATH ci_proxy "" cacheL1 cacheL2
REM
REM   Example of console display:
REM     PATH =C:\Program Files\Git\usr\bin
REM     PATH+=C:\Program Files\Python38
REM            ci_proxy = http://zscaler.xyz.com:80
REM
REM             cacheL1 = C:\Developer\Install\tmp\.cache
REM             cacheL2 = \\att\distribution\cached
REM
:showEnv
  CALL :_getPID
  (
    SETLOCAL DisableDelayedExpansion
    ECHO :loop
    ECHO SHIFT
    ECHO IF ""%%1""=="""" GOTO :EOF
    ECHO IF "%%~1"=="" ECHO. ^&^& GOTO :loop
    ECHO IF "%%~1"=="PATH" ECHO   PATH has %%PATH:;=^& ECHO   PATH has %% ^^
    ECHO   ^&^& GOTO :loop
    ECHO SETLOCAL EnableDelayedExpansion
    ECHO SET "val== !%%~1!"
    ECHO SETLOCAL DisableDelayedExpansion
    ECHO SET "name=                                                    %%~1 "
    ECHO SET name=%%name:~-%1,-1%%
    ECHO IF "%%val%%"=="= " SET val=is UNDEFINED
    ECHO ECHO %%name%% %%val%%
    ECHO ENDLOCAL ^&^& ENDLOCAL
    ECHO GOTO :loop
    ENDLOCAL
  ) 1> .tmp.showEnv.%PID%.cmd

  CALL .tmp.showEnv.%PID%.cmd %*
  DEL /F .tmp.showEnv.%PID%.cmd
  EXIT /B 0


@REM   showTool   RIGTH_ALIGN [TOOL_CMDs...]
REM FN showTool: List out of tool command with tool name
REM
REM @param %1 Specified right alignment for each variables name (80 max)
REM @param %2.. (Optional) tool command to run for extract info
REM
REM @test CALL :showToolInfo 18 "git --version"
REM
:showTool
  CALL :_getPID
  (
    ECHO SETLOCAL
    ECHO :loop
    ECHO SHIFT
    ECHO IF ""%%1""=="""" GOTO :EOF
    ECHO IF "%%~1"=="" ECHO. ^&^& GOTO :loop
    ECHO FOR /F "tokens=1" %%%%a IN ^("%%~1"^) DO SET ^^
    ECHO   "name=                                                    %%%%~a "
    ECHO SET name=%%name:~-%1,-1%%

    ECHO %%~1 ^> .tmp.showToolInfo.%PID%.info 2^>^&1
    ECHO SET error=%%ERRORLEVEL%%

    ECHO SET info=ERROR
    ECHO IF %%error%%==9009 SET info=NOT FOUND
    ECHO IF NOT %%error%%==0 ECHO.%%name%% = %%info%% ^&^& GOTO :loop

    ECHO FOR /F "delims=" %%%%a IN ^(
    ECHO   .tmp.showToolInfo.%PID%.info^) DO ECHO.%%name%% = %%%%a
    ECHO GOTO :loop
  ) 1> .tmp.showToolInfo.%PID%.cmd

  CALL .tmp.showToolInfo.%PID%.cmd %*
  DEL /F .tmp.showToolInfo.%PID%.cmd
  DEL /F .tmp.showToolInfo.%PID%.info
  EXIT /B 0


@REM
@REM   gitFetchCache BRANCH GIT_URL [CACHE_PATH...]
REM FN gitFetchCache: run git fetch to all cached repositories.
REM
REM @param %1     Specified the branch to cached. Empty will cached all
REM         branches
REM @param %2     Specified the root git repository URL
REM @param %3..   (Optional) Specified absolute git cache path
REM
REM @param %GIT_CMD% (optional) path of git.exe for use as git command.
REM         Otherwise default git command would be use.
REM
REM @param %DEF_ENV_URL% (optional) Point to a URL file that contains a set
REM         of environment variable's name and it's value.
REM
REM @param %GIT_INST_DEF% (optional) Point to a path where git.exe tool
REM         could be found.
REM @param %GIT_INST_URL% (optional) Point to a URL to download git
REM         installer if needed.
REM @param %GIT_CONFIGS%  (optional) Specify a set of configuration for git
REM         command. This value would be pass into applyCfg command. See
REM         help message for applyCfg command for detail.
REM
REM @param %SSH_KEY%      (optional) Specify ssh private key to use in
REM         GIT_SSH_COMMAND. This could be use under Jenkins.
REM
REM @param %DEL_DOTGIT_FILES% (optional) A set of search pattern using will
REM         card to be deleted under .git folder. This could be use to
REM         clean up left over git locked files when run under Jenkins.
REM
REM @return .ret file contains all loaded variable NAME=VALUE pars
REM         including the actual GIT_URL that used for fetch. Loaded
REM         variables should be from DEF_ENV_URL if any. GIT_URL can be
REM         difference than the %2 param for the case it been replace with
REM         mirror server.
REM
REM @exception exit with ERRORLEVEL if fail
REM
REM @remark It will skip any cache path that passed in %3.. who has invalid
REM name, or permission issue to create the path.
REM
REM @example Below show how to speed up download by cached each git
REM repository in a share network folder at \\l2, and a local reference
REM repos c:\l1\RefRepos that contains objects of all the git repos:
REM
REM   ciutils.cmd gitFetchCache master ssh://git@stash/sp1/repoA ^^
REM     \\l2 c:\l1\RefRepos
REM   git clone ssh://git@stash/sp1/repoA --reference c:\l1\RefRepos
REM
REM @note This command use git.exe.
REM
REM Below are step this command would do:
REM 1. Auto load environment from %DEF_ENV_URL%
REM 2. Auto install Git if not exist using the %GIT_INST_URL%,
REM    %GIT_INST_DEF%, then restart the machine. While script exit with
REM    error.
REM 3. Auto run git config on %GIT_CONFIGS%
REM 4. Auto add "-i %SSH_KEY%" into %GIT_SSH_COMMAND%
REM 5. Auto fix to mirror stash URL using %STASH_URL_ORG% and
REM    %STASH_URL_NEW%. Save the result into .ret file in form of
REM    GIT_URL=XYZ
REM
REM This command useful to call before Jenkins checkout step to taking care
REM of flowing things:
REM *  Clean up leftover git locked files
REM *  Resolve the mirror URL of the git repository
REM *  Update the git reference that could be use in clone reference to
REM    reduce network usages.
REM *  Update recursively all the submodules into git reference folder.
REM
REM @test CALL :gitFetchCache master ^^
REM   ssh://git@stash.xyz.com:7999/att/ciutils.git ^^
REM   c:\l1
REM
:gitFetchCache
  SETLOCAL EnableDelayedExpansion
  DEL /F .ret >/NUL 2>&1
  REM Auto load environment from DEF_ENV_URL
  SET _ret=A
  IF NOT DEFINED cacheL1 FOR %%a IN ("%TMP%") DO SET cacheL1=%%~sa\.cache
  IF     DEFINED DEF_ENV_URL CALL :setEnvUrl "%DEF_ENV_URL%" || GOTO :EOF
  SET _cfg_git=A
  IF EXIST "%HOME%\.git.configured" SET _cfg_git=%_ret%
  IF NOT EXIST "%cacheL1%" MKDIR "%cacheL1%"

  IF NOT DEFINED InstIdsPath SET InstIdsPath=%PUBLIC%
  MKDIR "%InstIdsPath%" 2>/NUL

  REM Auto install Git if not exist using the GIT_INST_URL,
  REM GIT_INST_DEF, then restart the machine
  FOR %%a IN ("%GIT_CMD%") DO SET GIT_CMD=%%~sa
  IF DEFINED GIT_CMD GOTO :_gitFetchCache_GitCmd
  :_gitFetchCache_GitInstall

    IF DEFINED GIT_INST_DEF SET "PATH=%PATH%;%GIT_INST_DEF%"
    FOR %%a IN (git.exe) DO FOR %%b IN ("%%~$PATH:a") DO SET GIT_CMD=%%~sb
    IF DEFINED GIT_CMD GOTO :_gitFetchCache_GitCmd

    IF NOT DEFINED GIT_INST_URL ECHO ERROR: GIT.EXE not found && EXIT /B 1

    SET "_arg=%GIT_INST_URL%"
    CALL :escPercent _arg
    ( REM ENSURE ONE GIT INSTALLATION RUN AT ONCE GIVEN TIME
      REM NOTE: GIT_INST_URL also include install flags DONOT quote it.
      ECHO Installing GIT from "%GIT_INST_URL%"...
      CALL :runUrl %_arg% ^
      || ECHO ERROR: GIT Installation FAILED && GOTO :EOF

      REM Make sure all running process are finished
      CALL :joinThread

      ECHO THERE MIGHT BE A LOT OF ERRORS UNTIL MACHINE REBOOT COMPLETED
      SHUTDOWN /r /t 2
      EXIT /B 1
    ) 9>"%InstIdsPath%\.INSTALL.LOCK" || ECHO %TIME% Retry in 10sec ^
    && 1>/NUL ping -n 11 "::1" && GOTO :_gitFetchCache_GitInstall
    DEL /F "%InstIdsPath%\.INSTALL.LOCK" >/NUL 2>&1
  :_gitFetchCache_GitCmd

  REM To save time, only cfg git if new DEF_ENV_URL loaded, or first time
  IF NOT DEFINED _cfg_git GOTO :_gitFetchCache_GitCfg_Done
  :_gitFetchCache_GitCfg
  REM Auto apply git config from GIT_CONFIGS
  ( REM ENSURE ONE GIT CONFIG RUN AT ONCE GIVEN TIME
    REM Use pre-configured ca-bundle files
    IF DEFINED GIT_SSL_CAINFO (
      COPY /Y "%GIT_SSL_CAINFO%" "%cacheL1%\ca-bundle.crt" >/NUL
    )

    REM Use pre-configured ssh files (config for ssh proxy, known_hosts etc.)
    IF DEFINED SSH_CFG_DIR (
      robocopy "%SSH_CFG_DIR%" "%cacheL1%\.ssh" /R:0 /MIR /NFL /NDL /NP /NJH /NJS
      FOR %%a IN ("%HOME%" %ADDITION_HOMES%) DO IF NOT "%%~a"=="" robocopy ^
          "%cacheL1%\.ssh" "%%~a\.ssh" /MIR /NFL /NDL /NP /NJH /NJS
    )

    REM Use pre-configured credentials
    IF DEFINED GIT_CFG_FILE (
      COPY /Y "%GIT_CFG_FILE%" "%cacheL1%\.gitconfig" >/NUL
      FOR %%a IN ("%HOME%" %ADDITION_HOMES%) DO IF NOT "%%~a"=="" COPY ^
        /Y "%cacheL1%\.gitconfig" "%%~a\.gitconfig" >/NUL
    )

    REM Use pre-configured credentials
    IF DEFINED GIT_CREDENTIALS (
      COPY /Y "%GIT_CREDENTIALS%" "%cacheL1%\.git-credentials" >/NUL
      FOR %%a IN ("%HOME%" %ADDITION_HOMES%) DO IF NOT "%%~a"=="" COPY ^
        /Y "%cacheL1%\.git-credentials" "%%~a\.git-credentials" >/NUL
    )

    CALL :applyCfg "%GIT_CMD% config" %GIT_CONFIGS%

    ECHO.> "%HOME%\.git.configured"
  ) 9>"%InstIdsPath%\.gitconfig.LOCK" || ECHO %TIME% Retry in 3sec ^
  && 1>/NUL ping -n 4 "::1" && GOTO :_gitFetchCache_GitCfg
  DEL /F "%InstIdsPath%\.gitconfig.LOCK" >/NUL 2>&1
  :_gitFetchCache_GitCfg_Done

  IF EXIST "%cacheL1%\ca-bundle.crt" SET "GIT_SSL_CAINFO=%cacheL1%\ca-bundle.crt"

  REM Delete files specified in DEL_DOTGIT_FILES in .git folder
  FOR /R ".git" %%a IN (%DEL_DOTGIT_FILES%) DO (
    DEL /F "%%~a" && ECHO DELETE "%%~a"
  )

  REM Auto add "-i SSH_KEY" into GIT_SSH_COMMAND
  IF DEFINED SSH_KEY SET "GIT_SSH_COMMAND=%GIT_SSH_COMMAND% -i '%SSH_KEY%'"

  REM Normalize repos URL path (removing relative part of `..`)
  FOR /F "tokens=1,2,* delims=/" %%a IN ("%~2") DO (
    FOR /F %%d IN ("c:/%%c") DO SET "gitUrl=%%a//%%b%%~pnxd"
  )
  SET "gitUrl=%gitUrl:\=/%"
  CALL :_gitFetchCache_AdjRepoUrl_Into_srcRepo "%gitUrl%"

  REM Loop through all the specified cache path
  SET indent=
  SET referenceOpt=
  :_gitFetchCache_Loop
    SET desRepo=%~3
    IF NOT DEFINED desRepo (
      DEL /F .ret >/NUL 2>&1
      IF EXIST "%cacheL1%\.envVars" COPY "%cacheL1%\.envVars" .ret >/NUL
      IF DEFINED srcRepo (ECHO GIT_URL=%srcRepo%) >>.ret
      IF DEFINED GIT_SSL_CAINFO (ECHO GIT_SSL_CAINFO=%GIT_SSL_CAINFO:\=\\%) >>.ret
      EXIT /B 0
    )

    MKDIR "%desRepo%" 2>/NUL
    REM Skip if the cache path still not exist may be due to
    REM Invalid cache path name, or permission issue
    IF NOT EXIST "%desRepo%\" SHIFT /3 && GOTO :_gitFetchCache_Loop

    REM If the cache folder do not exists, run a git clone first
    IF NOT EXIST "%desRepo%\objects" (
      ECHO %TIME%  Initialize "%desRepo%" cache for "%srcRepo%"...
      SET cloneOpts=
      IF DEFINED branch SET cloneOpts=-b "%branch%"

      RMDIR /Q /S "%desRepo%"
      %GIT_CMD% clone --bare %cloneOpts% "%srcRepo%" "%desRepo%" %referenceOpt%

      IF ERRORLEVEL 1 IF EXIST "%desRepo%\" (
        ECHO %TIME%  WARN: Clone failed, will try again...
        1>/NUL ping -n 2 "::1"
        GOTO :_gitFetchCache_Loop
      ) ELSE EXIT /B %ERRORLEVEL%
    )

    ( REM ENSURE Only fetch one physical cache path at any given time
      CALL :_gitFetchCache_Inner %1 "%gitUrl%" "%desRepo%"
      SET referenceOpt=--reference "%desRepo%"
      SHIFT /3
    ) 9>"%desRepo%\.tmp.gitFetchCache.lock" || ECHO %TIME% Retry in 10sec ^
    && 1>/NUL ping -n 11 "::1"
    DEL /F "%desRepo%\.tmp.gitFetchCache.lock" >/NUL 2>&1
  GOTO :_gitFetchCache_Loop


REM This sub-function adjust %1 URL for mirror server if apply, then set
REM the result into srcRepo variable. Also verify if mirror server contains
REM the repo if %STASH_URL_CHECK% set.
:_gitFetchCache_AdjRepoUrl_Into_srcRepo
  SET "srcRepo=%~1"
  IF DEFINED STASH_URL_ORG IF DEFINED STASH_URL_NEW (
    SET "srcRepo=!srcRepo:%STASH_URL_ORG%=%STASH_URL_NEW%!"
    IF "!srcRepo!"=="%~1" EXIT /B 0
    IF DEFINED STASH_URL_CHECK (
      %GIT_CMD% ls-remote "!srcRepo!" -h || SET "srcRepo=%~1"
    )
  )
  EXIT /B 0


REM This sub-function fetch branch %1 of git repo %2 into %desRepo% cache
REM folder Is also return the actual git repos URL into srcRepo variable
:_gitFetchCache_Inner
  SETLOCAL EnableDelayedExpansion
  SET branch=%~1
  CALL :_gitFetchCache_AdjRepoUrl_Into_srcRepo %2
  SET desRemote=%~n2
  SET desRepo=%~3
  SET "indent=%indent%  "

  PUSHD "%desRepo%"
  IF ERRORLEVEL 1 GOTO :EOF

  REM Add remote url, and verify if the URL are the same
  %GIT_CMD% remote add "%desRemote%" "%srcRepo%" 2>/NUL
  IF ERRORLEVEL 1 (
    %GIT_CMD% remote get-url "%desRemote%" > .tmp.gitFetchCache 2>/NUL
    %GIT_CMD% remote remove "%desRemote%" 2>/NUL
    %GIT_CMD% remote add "%desRemote%" "%srcRepo%"
    IF ERRORLEVEL 1 (
      ECHO %TIME%%indent%ERROR: Cannot set remote "%desRemote%" to "%srcRepo%"
      POPD && EXIT /B 1
    )
    FOR /F "delims=" %%a IN (.tmp.gitFetchCache) DO (
      IF /I NOT "%%~a"=="%srcRepo%" (
        ECHO %TIME%%indent%WARN: Remote "%desRemote%" was "%%a", now replaced with "%srcRepo%"
      )
    )
  )

  IF NOT DEFINED branch (
    ECHO %TIME%%indent%Fetching "%desRepo%" from "%srcRepo%"...
    SET fetchOpts=--prune "%desRemote%"
  ) ELSE (
    ECHO %TIME%%indent%Fetching "%desRepo%" at "%branch%" from "%srcRepo%"...
    SET fetchOpts="%desRemote%" "%branch%"
  )
  %GIT_CMD% fetch %fetchOpts%
  IF ERRORLEVEL 1 ECHO ERROR: fetch "%desRemote%" && POPD && EXIT /B 1

  REM Normalize %branch% to a commit SHA1
  IF DEFINED branch FOR /F %%a IN (
    '%GIT_CMD% ls-remote "%desRemote%" "%branch%"') DO SET branch=%%~a

  REM Check if there are filter.lfs defined before do LFS fetch
  %GIT_CMD% config --get-regex ^^filter\.lfs 1>/NUL
  IF NOT ERRORLEVEL 1 (
    ECHO %TIME%%indent%  Fetch LFS
    SET fetchLFSOpts="%desRemote%" "%branch%"
    IF NOT DEFINED branch SET fetchLFSOpts=--recent "%desRemote%"

    REM To respect the repo setting (specially lfs.url) we change master
    REM branch point to fetching branch
    %GIT_CMD% branch -f master "%branch%"

    %GIT_CMD% lfs fetch !fetchLFSOpts! ^
    || (ECHO %TIME%%indent%ERROR: fetch "%desRemote%" lfs) && POPD && EXIT /B 1
  )

  REM Find and fetch all submodule
  IF DEFINED branch (
    REM Search for .gitmodule files
    (ECHO.)>.tmp.gitFetchCache.args
    FOR /F "delims=" %%a IN (
      '%GIT_CMD% ls-tree -r --full-tree --name-only "%branch%"'
    ) DO IF "%%~a"==".gitmodules" (
      SET modFile=%%~a
      ECHO %TIME%%indent%  Check "!modFile!" for submodules at "%branch% (%desRemote%)"

      REM Get list of submodule names
      %GIT_CMD% show "%branch%":"!modFile!" >.tmp.gitFetchCache.mod 2>/NUL

      %GIT_CMD% config -f .tmp.gitFetchCache.mod --name-only ^
        --get-regexp "^submodule\.(.+)\.url" >.tmp.gitFetchCache.name 2>/NUL

      REM Get list of submodule branch and url
      FOR /F "delims=" %%a IN (.tmp.gitFetchCache.name) DO (
        SET cfgName=%%~a
        SET cfgName=!cfgName:~0,-3!
        SET modName=!cfgName:~10,-1!

        ECHO %TIME%%indent%    Found Submodule "!modName!"

        FOR /F %%a IN ("modules/!modName!") DO IF NOT EXIST "%%~fa" (
          MKDIR "%%~dpa" 2>/NUL
          MKLINK /J "%%~dpnxa" "%CD%" 2>&1 >/NUL
        )

        REM Obtain module URL (could be relative URL)
        SET modUrlOrg=
        FOR /F "delims=" %%a IN (
          '%GIT_CMD% config -f .tmp.gitFetchCache.mod --get "!cfgName!url"'
        ) DO SET modUrlOrg=%%~a

        REM Normalize modURL to absolute URL
        SET modUrl=
        FOR /F "eol=. delims=" %%a IN ("!modUrlOrg!") DO SET modUrl=!modUrlOrg!
        IF "!modUrl!"=="" FOR /F "delims=" %%a IN ("%srcRepo%/!modUrlOrg!") DO (
          SET modUrl=%%~fa
          SET modUrl=!modUrl:%CD%\=!
          SET modUrl=!modUrl:\=/!
          SET modUrl=!modUrl::/=://!
        )

        REM Obtain submodule path, and figure out the commit SHA1
        FOR /F "delims=" %%a IN (
          '%GIT_CMD% config -f .tmp.gitFetchCache.mod --get "!cfgName!path"'
        ) DO FOR /F "tokens=3" %%c IN ('%GIT_CMD% ls-tree %branch% "%%~a"') DO (
          SET modBranch=%%~c
        )
        IF "!modBranch!"=="." SET modBranch="master"
        IF "!modBranch!"==""  SET modBranch="master"

        ( ECHO "!modName!"
          ECHO "!modBranch!"
          ECHO "!modUrl!"
          ECHO /) 1>> .tmp.gitFetchCache.args
      )
      DEL /F .tmp.gitFetchCache.mod .tmp.gitFetchCache.name
    )

    REM Save data into a local variable avoid conflict with recursive call
    REM to _gitFetchCache_Inner
    SET myArgs=
    FOR /F "delims=" %%a IN (.tmp.gitFetchCache.args) DO SET myArgs=!myArgs! "%%~a"
    DEL /F .tmp.gitFetchCache.args

    REM Call gitFetchCache for all submodule recursively
    SET "indent=%indent%    "
    FOR %%a IN (!myArgs!) DO (
      IF %%a=="/" (
        ECHO %TIME%!indent!START fetching submodule "!modName!"
        CALL :_gitFetchCache_Inner "!modBranch!" "!modUrl!" .
        ECHO %TIME%!indent!END fetching submodule "!modName!"
        IF ERRORLEVEL 1 POPD && GOTO :EOF
      )
      SET modName=!modBranch!
      SET modBranch=!modUrl!
      SET modUrl=%%~a
    )
  )
  POPD
  ENDLOCAL
  EXIT /B 0


@REM
@REM   configWinProxy  [HTTP_PROXY]
REM FN configWinProxy: Apply proxy setting into Windows System Registry
REM
REM @param %1 (optional) specify http proxy server. If not specify,
REM           %http_proxy% will be use
REM
REM @param %http_proxy% (optional) Specify http/https proxy server
REM @param %ci_proxy%   (optional) use when http_proxy not specified
REM
REM @exception exit code:
REM   * (255) - if bash required to be restart to taking effect
REM   * other - error code of reg command
REM
REM @note Addition command required:
REM   1) reg -- Windows command for edit window registry
REM
:configWinProxy
  SETLOCAL
  CALL :_getPID
  SET basePath=HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings
  FOR /F "tokens=3" %%a IN ('REG QUERY "%basePath%" /v ProxyEnable ^2^>/NUL'
                           ) DO SET oldEnb=%%a
  FOR /F "tokens=3" %%a IN ('REG QUERY "%basePath%" /v ProxyServer ^2^>/NUL'
                           ) DO SET oldSrv=%%a

  SET enb=0x1
  IF NOT "%~1"==""      SET http_proxy=%~1
  IF NOT DEFINED http_proxy SET http_proxy=%ci_proxy%
  IF NOT DEFINED http_proxy SET enb=0x0

  IF NOT "%oldEnb%"=="%enb%"        GOTO :_configWinProxy_update
  IF NOT "%oldSrv%"=="%http_proxy%" GOTO :_configWinProxy_update
  EXIT /B 0

  :_configWinProxy_update
    ECHO Current Proxy setting %oldEnb% - %oldSrv%
    ECHO   now set to          %enb% - "%http_proxy%"
    REG ADD "%basePath%" /v ProxyEnable /t REG_DWORD /d "%enb%"        /f >/NUL
    REG ADD "%basePath%" /v ProxyServer /t REG_SZ    /d "%http_proxy%" /f >/NUL
    1>&2 ECHO NEED TO RESTART THE SHELL for Proxy to work
  EXIT /B 255


@REM   getLocalPath    SHARE_FOLDER_PATH
REM FN getLocalPath: map or reuse share drive to local path if possible
REM
REM @param %1 Specified a path (local or share drive)
REM @param %2 (Optional) user name access the share
REM @param %3 (Optional) user password access the share
REM
REM @return A local path or original specified path in %_ret% , .ret file
REM and .ret%PID% file
REM
REM @note This function may ask for user name, and password. To avoid that,
REM run "net use %1 /USER:username password" before call this function. Or
REM specify %2, and %3 parameters.
REM
REM @note
REM * PUSHD command also do the network map automatically
REM * This command use batch command: findstr, net
REM
REM
REM @test CALL :getLocalPath \\share\xyz
REM       .ret%PID% should contains X: if the \\share\xyz exist
REM       .ret%PID% should contains \\share\xyz if it not exist
REM
REM @test CALL :getLocalPath c:\xyz
REM       .ret%PID% should contains c:\xyz
REM
:getLocalPath
  SETLOCAL
  DEL /F .ret%PID% >/NUL 2>&1
  DEL /F .ret >/NUL 2>&1
  SET test=%~1
  SET "_ech_test=%~1"

  REM Skip if not a share drive path, return original path
  IF "%test:~0,2%" == "\\" GOTO :_getLocalPath_share_path
    CALL :escapeVar _ech_test
    (ECHO %_ech_test%)> .ret%PID%
    (ECHO %_ech_test%)> .ret
    ENDLOCAL && SET "_ret=%test%" && EXIT /B 0
  :_getLocalPath_share_path

  REM Search of the share drive path already mapped. If found, return the
  REM drive letter
  FOR /F "tokens=1,2,*" %%a IN (
    'NET USE ^| findstr /R /B /C:"OK  *.:" ^| findstr /C:"%test% "'
  ) DO (
    ECHO %%a %%b "%%c"
    IF "%%a"=="OK" (
      (ECHO %%b)> .ret%PID%
      (ECHO %%b)> .ret
      ENDLOCAL && SET "_ret=%%b" && EXIT /B 0
    )
  )

  REM Map the share drive with a unused drive letter, and return the drive
  REM letter
  SET netOpts=NET USE * "%test%" /PERSISTENT:NO
  IF NOT "%~2" == "" SET netOpts=%netOpts% "/USER:%~2"
  IF NOT "%~3" == "" SET netOpts=%netOpts% %3
  ECHO Mapping "%test%" to a drive letter
  FOR /F "tokens=1,2,*" %%a IN ('%netOpts%') DO (
    ECHO %%a %%b "%%c"
    IF "%%a" == "Drive" (
      (ECHO %%b)> .ret%PID%
      (ECHO %%b)> .ret
      ENDLOCAL && SET "_ret=%%b" && EXIT /B 0
    )
  )

  REM Seem like share drive cannot be mapped, return original path
  CALL :escapeVar _ech_test
  (ECHO %_ech_test%)> .ret%PID%
  (ECHO %_ech_test%)> .ret
ENDLOCAL && SET "_ret=%test%" && EXIT /B 0


@REM
@REM   runThread   COMMAND [COMMAND_ARGUMENTS...]
REM FN runThread: Start a command in separate process, and schedule
REM for wait in joinThread job. It also capture the process output
REM
REM @remark joinThread expect to be called to wait, and cleanup all the
REM thread created by this function
REM
REM @param %* Command and arguments to be executed in separated thread
REM
REM @exception exit with error code if error
REM
REM @example
REM   CALL :runThread copy BigFile BigFileCopy
REM   REM Do something else
REM   ...
REM   CALL :joinThread
REM   REM Now we can work on BigFileCopy file
REM   ...
REM
:runThread
  SETLOCAL
  CALL :_getPID

  :_thread_loop
    SET lock=lock.%~nxs1.%PID%.%random%
    ((REM Make sure %lock% file not in used

      ECHO [NEW THREAD %lock%] %*
      (ECHO.%* )>.%lock%.org
      (ECHO.%* ^>.%lock%.out1 2^>^&1)>.%lock%.cmd
      START "" CMD /C .%lock%.cmd ^>.%lock%.out 2^>^&1
      IF ERRORLEVEL 1 GOTO :EOF

      (ECHO CALL %_ciutils% _waitRunThread %lock%)>>.cleanup%threadGrp%.cmd

    ) 9>.%lock% || GOTO :_thread_loop ) 2>/NUL
  EXIT /B 0


@REM   joinThread  Wait for all threads finished
REM FN joinThread: wait all for all threads finished. These threads
REM were create by runThread function
REM
REM @remark I basically run .cleanup%threadGrp%.cmd file. So if your script need
REM addition cleaning command, they can be append to this file. So the
REM cleanup job will be executed when calling this function.
REM
REM @exception exit with same error code of .cleanup%threadGrp%.cmd returned
REM
REM
:joinThread
  IF NOT EXIST .cleanup%threadGrp%.cmd GOTO :EOF
  CALL .cleanup%threadGrp%.cmd

  SETLOCAL && SET error=%ERRORLEVEL%
  DEL /F .cleanup%threadGrp%.cmd .ret .ret%PID% >/NUL 2>&1
  EXIT /B %error%


REM
REM Wait for all the lock files released
REM @param %* List of lock files created by runThread command
REM
:_waitRunThread
  SETLOCAL
  FOR %%n IN (%*) DO (
    IF EXIST ".%%n.org" (
      FOR /F "usebackq delims=" %%c IN (".%%n.org") DO (
        ECHO ## WAIT [THREAD %%n] %%c...
      )
    )
  )

  :_waitRunThreadLoop
  FOR %%n IN (%*) DO IF EXIST .%%n (
      (CALL ) 9>.%%n || 1>/NUL ping -n 2 "::1" && GOTO :_waitRunThreadLoop
  ) 2>/NUL

  FOR %%n IN (%*) DO (
    IF EXIST .%%n.out (
      FOR /F "delims=" %%c IN (.%%n.out1 .%%n.out) DO ECHO " | %%c"
      ECHO.
      DEL /F .%%n.out1 .%%n.out
    )
    DEL /F .%%n.org .%%n.cmd .%%n >/NUL 2>&1
  )
  EXIT /B 0


@REM
@REM   escapeVar  Apply escape in variables so they can be pass via ECHO
REM FN escapeVar: Insert escape `^` next to any special chars of specified
REM               variable names.
REM
REM @param %1...  Specify a name of variable need to be escape. If the
REM               value contains special character inside the double quoted
REM               part would not work.
REM
REM @return Update escaped values back into each specified variable names.
REM
REM @test SET "A=+_)(*&^^%$#@!~" && CALL :escapeVar A && ECHO %A%
REM It would display exact original content of A which was "+_)(*&^^%$#@!~"
REM
:escapeVar
  IF "%~1"=="" EXIT /B 0
  SETLOCAL
  CALL SET "VAL=%%%~1%%."
  SET "VAL=%VAL:^=^^%"
  SET "VAL=%VAL:&=^&%"
  SET "VAL=%VAL:<=^<%"
  SET "VAL=%VAL:>=^>%"
  SET "VAL=%VAL:|=^|%"
  SET "VAL=%VAL:)=^)%"
  ENDLOCAL && SET "%~1=%VAL:~0,-1%"
  SHIFT && GOTO :escapeVar


@REM   escPercent Apply escape to minimize lose when pass via CALL
REM FN escPercent: Replace `%` with `%%` in value of specified variable
REM    names.
REM
REM @param %1...  Specify a name of variable need to be search and replace.
REM               If the value contains special character inside the double
REM               quoted part would not work.
REM
REM @return Update escaped values back into each specified variable names.
REM
REM @test
REM   SET A="a&b" "1.._1,,^^B^%D^^^!E^^^!"
REM   CALL :escPercent A
REM   ECHO %A%
REM
REM It would display:
REM "a&b" "1.._1,,^^B%%D^^^!E^^^!"
REM
:escPercent
  IF "%~1"=="" EXIT /B 0
  SETLOCAL EnableDelayedExpansion
  CALL SET VAL=%%%~1%%.
  SET VAL=!VAL:%%=%%%%!
  ENDLOCAL && SET %~1=%VAL:~0,-1%
  SHIFT && GOTO :escPercent


@REM
@REM   traceCmd   Execute and trace line number
REM FN traceCmd:  Execute and trace line number
REM
REM @param %1..         Specify the argument pass into .cmd file
REM @param %_traceFile% Specify full path of .cmd file
REM
REM @note This command use powershell
REM
:traceCmd
  CALL :_getPID
  SETLOCAL
  FOR %%a IN ("%_traceFile%") DO SET _traceFile=%%~sa
  ( REM Insert ECHO on every line with line# and src code
    ECHO. $lineNo=0
    ECHO. $newLine= ''
    ECHO. $traceContent=''
    ECHO. $inside=''
    ECHO. foreach($line in Get-Content '%_traceFile%'^)
    ECHO. {
    ECHO.   $lineNo+=1
    ECHO.
    ECHO.   if ($line -match "^ *(@REM\b.*|:: .*)?$"^) {continue}
    ECHO.   $line=$line -replace "%%\w+_TRACE%%", ""
    ECHO.
    ECHO.   $tmp2=$line -replace "[\^)^(|&>]", '^^$0'
    ECHO.   $len=$tmp2.length
    ECHO.   if ($len -gt 80^) {$tmp2=$tmp2.Substring(0, 77^)+'...'}
    ECHO.   $traceContent+='@^>^&3ECHO %%TIME%% {0,-6}:{1}' -f $lineNo, $tmp2
    ECHO.   $traceContent+="`r`n"
    ECHO.
    ECHO.   $tmp2=$line -replace """[^""]*""|'[^']*'|``[^``]*``", ""
    ECHO.   switch ($inside^)
    ECHO.   {
    ECHO.     'for' {if ($tmp2 -match "^[^)]*\)"^) {$inside=''}}
    ECHO.   }
    ECHO.   if ($tmp2 -match "FOR [^(]* IN +\([^)]*$"^) {$inside='for'}
    ECHO.
    ECHO.   if (($line -notmatch "\^$"^) -and ($inside -eq ''^)^)
    ECHO.   {
    ECHO.     $traceContent += $newLine + $line + "`r`n"
    ECHO.     $newLine = ''
    ECHO.   } else
    ECHO.   {
    ECHO.     $newLine += $line + "`r`n"
    ECHO.   }
    ECHO. }
    ECHO. Set-Content '%_traceFile%.%PID%.trace.cmd' -Value $traceContent
  ) 1> "%_traceFile%.%PID%.trace.ps1" || GOTO :EOF
  SET PATH=%PATH%:%PS_INST_DEF%
  powershell.exe -File "%_traceFile%.%PID%.trace.ps1" || GOTO :EOF
  DEL /F "%_traceFile%.%PID%.trace.ps1" >/NUL 2>&1
  (ECHO DEL /F "%_traceFile%.%PID%.trace.cmd" 2^>/NUL) >> .cleanup%threadGrp%.cmd
  ENDLOCAL && (%_traceFile%.%PID%.trace.cmd %*)


REM Obtain current process ID and save into %PID%.
:_getPID
  IF DEFINED PID EXIT /B 0
  SETLOCAL
  SET PATH=%PATH%:%PS_INST_DEF%
  FOR /F %%a IN (
    'powershell.exe -Command ^
      "$a=(Get-WmiObject Win32_Process -Filter ProcessId=$PID).ParentProcessId;" ^
      "   (Get-WmiObject Win32_Process -Filter ProcessId=$a  ).ParentProcessId "'
  ) DO SET PID=%%a
  ENDLOCAL && SET PID=%PID%
  EXIT /B 0


@REM   showHelp   CMD_FILE [COMMAND]
REM FN showHelp: Show help message and function documentation of a
REM specified .cmd file
REM
REM @param %1 Specify a .cmd file
REM @param %2 Specify a function name
REM
:showHelp
  SETLOCAL EnableDelayedExpansion
  FOR %%a IN ("%~1") DO SET scriptFile=%%~sa

  REM Search for document of a specific function %2
  IF NOT "%~2"=="" (
    SET found=
    FOR /F "tokens=1,* delims=:" %%a IN (%scriptFile%) DO (
      SET "tmp=%%a "
      SET tmpRem=!tmp:~0,4!
      IF NOT "!tmpRem!" == "REM " (
        IF NOT "!found!"=="" EXIT /B 0
      ) ELSE (
        SET tmp=!tmp:~4,-1!
        IF "!tmp!" == "FN %2" (
          SET found=%2
          ECHO.COMMAND %2:%%b
        ) ELSE IF NOT "!found!"=="" IF "%%b"=="" (
          ECHO.  !tmp!
        ) ELSE (ECHO.  !tmp!:%%b)
      )
    )
  )

  FOR /F "tokens=1,* delims=" %%a IN (%scriptFile%) DO (
    SET "tmp=%%a "
    SET tmpRem=!tmp:~0,5!
    IF "!tmpRem!" == "@REM " ECHO.!tmp:~5!
  )
  EXIT /B 0


@REM   help       [COMMAND]
@REM              Show this help message, or specified command
REM
:_help
  IF DEFINED _version     ECHO Version %_version%
  IF DEFINED _ciUtils_url ECHO Source: %_ciUtils_url%
  CALL :showHelp %0 %2
  EXIT /B 0

@REM
@REM EXAMPLE:
@REM   ciUtils.cmd runBash ls -al
@REM   ciUtils.cmd getCygPkg https://cygwin.com/setup-x86.exe bash ssh
@REM   ciUtils.cmd download https://cygwin.com/setup-x86.exe
@REM   ciUtils.cmd doCurl https://cygwin.com/setup-x86.exe -o test.exe


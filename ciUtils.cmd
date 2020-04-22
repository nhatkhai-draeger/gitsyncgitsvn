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
@REM COMMANDS:
@REM   runBash    [BASH_COMMAND_STR...]
@REM
@REM   getCygPkg  SETUP_EXE_URL [CYGWIN_PACKAGE...]
@REM   runMsiUrl  [MSI_OPTION...] MSI_FILE_URL
@REM   runUrl     EXECUTABLE_FILE_URL [OPTION...]
@REM   runOnce    COMMANS [OPTIONS...]
@REM
@REM   download   FILE_URL
@REM   doCurl     URL OUTFILE [CURL_OPTION...]
@REM
@REM   getLocalPath SHARE_FOLDER_PATH
@REM 
@REM ENVIRONMENT VARIABLES (OPTIONAL):
@REM   cacheL1     point to local folder for cache downloaded files.
@REM               Otherwise, current directory will be use.
@REM 
@REM   cacheL2     point to share cache folder for downloaded files
@REM
@REM   http_proxy  for http proxy server
@REM
@REM   https_proxy for https proxy server
@REM
@REM   curl_cab    location of curl executable package in case curl command
@REM               not available. Can be obtain from:
@REM          * https://curl.haxx.se/dlwiz/?type=bin&os=Win32&flav=-&ver=*
@REM          * Pre-download share folder
@REM
@REM   CURL        specify full path of curl command
@REM   BASH_CMD    specify location of bash.exe command
@REM
@REM   cygwin_url  specify cygwin setup URL use for installation
@REM   cyg_mirror  point to cygwin mirror URL
@REM   cyg_cache   point to share folder cygwin downloaded pkgs.
@REM
@REM EXAMPLE:
@REM   ciUtils.cmd runBash ls -al
@REM   ciUtils.cmd getCygPkg https://cygwin.com/setup-x86.exe bash ssh
@REM   ciUtils.cmd download https://cygwin.com/setup-x86.exe
@REM   ciUtils.cmd doCurl https://cygwin.com/setup-x86.exe -o test.exe
@REM
@IF "%CIUTILS_TRACE%" == "" @ECHO off
IF "%~1" == ""       GOTO :HELP
IF "%~1" == "/?"     GOTO :HELP
IF "%~1" == "help"   GOTO :HELP
IF "%~1" == "-h"     GOTO :HELP
IF "%~1" == "--help" GOTO :HELP

IF "%http_proxy%"=="" ECHO WARN: %%http_proxy%% may need
IF "%cacheL2%"   =="" ECHO WARN: %%cacheL2%% may need

CALL :%*
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
EXIT /b 0


REM 
REM FUNCTION runBash: Run a bash command
REM
REM If bash not installed in the system, it automatically install cygwin
REM bash.
REM
REM @param %* bash command string
REM
REM @param %BASH_CMD%    (optional) specify location of bash.exe command
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
REM
REM @param %http_proxy%  (optional) for http proxy server for 
REM @param %https_proxy% (optional) for https proxy server for
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @exception exit with error code if failed
REM
REM @test CALL :runBash ls -al "/cygdrive/c/Program Files"
REM
:runBash
SETLOCAL EnableDelayedExpansion
IF NOT EXIST "%BASH_CMD%" SET BASH_CMD=C:\cygwin\bin\bash.exe
IF NOT EXIST "%BASH_CMD%" SET BASH_CMD=C:\cygwin64\bin\bash.exe
IF NOT EXIST "%BASH_CMD%" (
  CALL :getCygPkg "%cygwin_url%" bash curl sed
  IF ERRORLEVEL 1 EXIT /b !ERRORLEVEL!
  IF NOT EXIST "%BASH_CMD%" SET BASH_CMD=C:\cygwin\bin\bash.exe
)

IF NOT EXIST "%BASH_CMD%" FOR %%a IN (bash.exe) DO SET BASH_CMD=%%~$PATH:a
IF NOT EXIST "%BASH_CMD%" (
  ECHO Cannot find Bash.exe. Please specify location in BASH_CMD
  EXIT /b 1
)
"%BASH_CMD%" -l -c 'cd %CD:\=/%; %*'
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
EXIT /b 0


REM 
REM FUNCTION runMsiUrl: Install/run msiexec command on a specified MSI
REM package
REM
REM @param %1..n-1 (optional) Specify MSI run options
REM @param %n Specify URL for a MSI pakcage to be run
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%     (optional) point to share folder for cache
REM         downloaded files
REM @param %http_proxy%  (optional) for proxy server for http*
REM @param %https_proxy% (optional) for proxy server for https
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) for curl executable package in case
REM         native curl command not available
REM
REM @exception exit if MSI error code if error occurred
REM
REM @test CALL :runMsiUrl https://osdn.mirror.constant.com//storage/g/t/to/tortoisesvn/1.13.1/Application/TortoiseSVN-1.13.1.28686-win32-svn-1.13.0.msi
REM
:runMsiUrl
SETLOCAL EnableDelayedExpansion

REM Separate MSI URL and MSI Options
SET opts=
SET url=
FOR %%a IN (%*) DO (
  SET opts=!opts! !url!
  SET url=%%~a
)

IF "%url%"=="" EXIT /b 1

REM Try to download and run installer
CALL :download "%url%"
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
FOR /F %%a IN (.ret) DO SET msiSetup=%%~a

SET cmd=msiexec /quiet /passive %opts%
IF "%~2"=="" SET cmd=%cmd% /i
SET cmd=%cmd% "%msiSetup%"

ECHO %cmd%
%cmd%
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
EXIT /b 0


REM 
REM FUNCTION runUrl: Download and run executable URL file
REM
REM @param %1   Specify URL for a executable file to be run
REM @param %2.. (optional) Specify arguments to pass to executable file
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%     (optional) point to share folder for cache
REM         downloaded files
REM @param %http_proxy%  (optional) for proxy server for http*
REM @param %https_proxy% (optional) for proxy server for https
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) for curl executable package in case
REM         native curl command not available
REM
REM @exception exit with executable file error code if error occurred
REM
REM @test CALL :runUrl https://github.com/git-for-windows/git/releases/download/v2.22.0.windows.1/Git-2.22.0-64-bit.exe /VERYSILENT
REM
:runUrl
SETLOCAL
SET url=%~1
SET opts=
:runUrl_OptsLoop
  shift
  IF NOT "%~1"=="" SET opts=%opts% %1 && GOTO runUrl_OptsLoop 

IF "%url%"=="" EXIT /b 1

REM Try to download and run installer
CALL :download "%url%"
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
FOR /F %%a IN (.ret) DO SET cmd="%%~a"%opts%
ECHO %cmd%
%cmd%
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
EXIT /b 0


REM 
REM FUNCTION runOnce: Try the command once, and create a mark to avoid run
REM again next time calling
REM
REM @param %1   Specify function
REM @param %2.. (Optional) Function arguments
REM
REM @param %InstIdsPath% (Optional) Local file path for tracking which
REM         location to store the mark file.
REM
REM @return A marked file name in .ret.runOnce file
REM
REM @exception exit with specified function error code if error occurred
REM
:runOnce
SETLOCAL
DEL /F .ret.runOnce 2>/nul
:runOnce_loop
  ECHO "%~1">> .ret.runOnce
  shift
  IF NOT "%~1"=="" GOTO runOnce_loop

IF "%InstIdsPath%"=="" SET InstIdsPath=C:
FOR /F "tokens=1,*" %%a IN ('certutil -hashfile .ret.runOnce MD5') DO (
  IF "%%b"=="" SET md5=%InstIdsPath%\.runOnce.%%a
)
ECHO "%md5%"> .ret.runOnce
IF EXIST "%md5%" EXIT /b 0

CALL :%*
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%

ECHO.> "%md5%"
EXIT /b 0


REM 
REM FUNCTION getCygPkg: Install cygwin and specified packages not needed
REM
REM @param %1 cygwin executable setup URL. When empty string, the default
REM         hard coded cygwin URL will be use
REM @param %2.. (optional) list of cygwin packages
REM
REM @param %cyg_mirror%  (optional) point to cygwin mirror URL
REM @param %cyg_cache%   (optional) point to share folder cygwin downloaded
REM         pkgs.
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded files. Otherwise, current directory will be use.
REM @param %cacheL2%     (optional) point to share cache folder for
REM         downloaded files
REM
REM @param %http_proxy%  (optional) for http proxy server for 
REM @param %https_proxy% (optional) for https proxy server for
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @exception error code for failure of installation
REM 
REM @test CALL :getCygPkg "https://cygwin.com/setup-x86.exe" bash curl sed
REM
:getCygPkg
SETLOCAL EnableDelayedExpansion

REM Try to check of the Cygwin module already exist
IF "%CYGCHECK_CMD%"=="" SET CYGCHECK_CMD=C:\cygwin\bin\cygcheck.exe
IF NOT EXIST "%CYGCHECK_CMD%" SET CYGCHECK_CMD=C:\cygwin64\bin\cygcheck.exe
IF EXIST "%CYGCHECK_CMD%" (
  DEL /F .reqsMods 2>/nul
  FOR %%a IN (%*) DO ECHO %%a >> .reqsMods
  ECHO Cygwin >> .reqsMods
  ECHO Package >> .reqsMods
  "%ComSpec%\..\sort.exe" .reqsMods /O .reqsMods

  "%CYGCHECK_CMD%" -c -d %* > .cygMods1
  ECHO %1 > .cygMods
  FOR /F %%a IN (.cygMods1) DO ECHO %%a >> .cygMods
  DEL /F .cygMods1
  "%ComSpec%\..\sort.exe" .cygMods /O .cygMods

  "%ComSpec%\..\fc.exe" .reqsMods .cygMods 2>&1 1>/nul
  IF NOT ERRORLEVEL 1 (
    DEL /F .reqsMods .cygMods
    EXIT /b 0
  )
  DEL /F .reqsMods .cygMods
)

SET cygMods=%2
SET /a cnt=1
FOR %%a IN (%*) DO (
  IF !cnt! GEQ 3 SET cygMods=!cygMods!,%%a
  SET /a cnt=!cnt!+1
)

SET url=%~1
IF "%url%" == "" (
  IF "%PROCESSOR_ARCHITECTURE%" == "x86" (
    SET url=https://cygwin.com/setup-x86.exe
  ) ELSE (
    SET url=https://cygwin.com/setup-x86_64.exe
  )
)

REM Try to download and run installer
CALL :download "%url%"
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
FOR /F %%a IN (.ret) DO SET cygSetup=%%a
SET opts=--quiet-mode --no-desktop --no-shortcuts --no-startmenu --only-site

IF NOT "%http_proxy%" == "" SET opts=%opts% --proxy "%http_proxy%"

IF "%cyg_mirror%" == "" (
  SET opts=%opts% --site "http://cygwin.mirror.constant.com"
) ELSE (
  SET opts=%opts% --site "%cyg_mirror%"
)

IF "%cyg_cache%" == ""  ( 
  IF NOT "%cacheL2%" == "" SET^
  opts=%opts% --local-package-dir "%cacheL2%\cygwin"
) ELSE ( 
  SET opts=%opts% --local-package-dir "%cyg_cache%"
)

SET opts=%opts% -P %cygMods% 
ECHO %cygSetup% %opts%
"%cygSetup%" %opts%
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%

EXIT /b 0


REM 
REM FUNCTION download: Try to download a file from specified url into
REM %cacheL1% or current directory
REM
REM First it will check if the file exist in %cacheL1, then %cacheL2%, then
REM try to use curl command to download the specified URL file
REM
REM @param %1 specified URL
REM
REM @param %cacheL1%     (optional) point to local folder for cache
REM         downloaded file. Otherwise, current directory will be use
REM @param %cacheL2%     (optional) point to share folder for cache
REM         downloaded files.
REM @param %http_proxy%  (optional) for http proxy server for 
REM @param %https_proxy% (optional) for https proxy server for
REM @param %CURL%        (optional) specify full path of curl command
REM @param %curl_cab%    (optional) location of curl executable package in
REM         case curl command not available
REM
REM @return A full path of downloaded file saved in .ret file
REM @exception exit with ERRORLEVEL if fail
REM
REM @test CALL :download "https://cygwin.com/setup-x86.exe"
REM
:download
SETLOCAL EnableExtensions
IF "%cacheL1%" == "" FOR /F %%a IN ('cd') DO SET cacheL1=%%a

REM Figure out the path 
ECHO %~1> .ret
:download_RemoveCols
  FOR /F "tokens=1,* delims=:" %%a IN (.ret) DO (
    ECHO %%a%%b> .ret
    SET tmp=%%b
  )
  IF NOT "%tmp%" == "" GOTO download_RemoveCols

REM Check if the file already exist locally, then avoid download
FOR /F %%a IN (.ret) DO SET outFile=%%a
FOR %%a IN ("%cacheL1%\%outFile%") DO (
  MKDIR "%%~dpa" 2>/nul
  SET l1file=%%~dpnxa
)
echo %l1file%> .ret
IF EXIST "%l1file%" EXIT /b 0

REM Try to take file from cache L2
IF "%cacheL2%"=="" GOTO download_SkipL2
  CALL :getLocalPath "%cacheL2%" "%cacheL2_user%" "%cacheL2_pw%"
  FOR /F %%a IN (.ret) DO SET cacheL2=%%~a

  FOR %%a IN ("%cacheL2%\%outFile%") DO (
    MKDIR "%%~dpa" 2>/nul
    SET l2file=%%~dpnxa
  )
  
  echo %l1file%> .ret
  IF EXIST "%l2file%" COPY /Y "%l2file%" "%l1file%" && EXIT /b 0
:download_SkipL2

REM Try to download the file
CALL :doCurl %1 "%l1file%"
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%

IF NOT "%cacheL2%" == "" COPY /Y "%l1file%" "%l2file%" 
EXIT /b 0


REM 
REM FUNCTION doCurl: Run curl command
REM
REM @param %1 Specified URL for download
REM @param %2 Specified full file path for storage the downloaded file
REM @param %3.. (Optional) addition curl arguments
REM
REM @param %http_proxy%  (optional) for http proxy server for 
REM @param %https_proxy% (optional) for https proxy server for
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
SETLOCAL EnableDelayedExpansion
IF "%CURL%"=="" FOR %%a IN (curl.exe) DO SET CURL=%%~$PATH:a
IF "%CURL%"=="" IF NOT "%curl_cab%"=="" (
  IF "%cacheL1%" == "" FOR /F %%a IN ('cd') DO SET cacheL1=%%a

  SET CURL=!cacheL1!/curl/I386/curl.exe
  IF NOT EXIST "!CURL!" (
    ECHO Extract the CAB Package and use it
    PUSHD "!cacheL1!"
    IF ERRORLEVEL 1 EXIT /b !ERRORLEVEL!

    COPY /Y "!curl_cab!" "curl.cab"
    IF ERRORLEVEL 1 EXIT /b !ERRORLEVEL!

    IF NOT EXIST curl MKDIR curl
    IF ERRORLEVEL 1 EXIT /b !ERRORLEVEL!

    EXPAND curl.cab -F:* curl 
    IF ERRORLEVEL 1 EXIT /b !ERRORLEVEL!
    POPD
  )
)

IF NOT EXIST "%CURL%" (
  ECHO CANNOT FIND CURL COMMAND. Please set %%CURL%%, or %%curl_cab%%
  ECHO   %%CURL%% to specified location of curl.exe
  ECHO   %%curl_cab%% to specified location of curl package for install
  EXIT /b 1
)

REM Extract curl options from arguments
set /a cnt=2
SET curlOpts=
FOR %%a IN (%*) DO (
  IF !cnt! LEQ 0 (SET curlOpts=!curlOpts! %%a) ELSE (set /a cnt=!cnt!-1)
)
IF "%curlOpts%"=="" SET curlOpts= --insecure --location

REM Determine which proxy to use
SET use_proxy=%http_proxy%
IF NOT "%https_proxy%"=="" (
  SET protocol=
  FOR /F "delims=:" %%a IN ("%~1") DO SET protocol=%%a
  IF "!protocol:~-1!"=="s" SET use_proxy=%https_proxy%
)
IF NOT "%use_proxy%" == "" SET curlOpts=%curlOpts% -x "%use_proxy%"

IF NOT "%~2"=="" SET curlOpts=%curlOpts% -o %2
SET curlOpts=%curlOpts% %1

ECHO %CURL%%curlOpts%
"%CURL%"%curlOpts%
IF ERRORLEVEL 1 EXIT /b %ERRORLEVEL%
EXIT /b 0


REM 
REM FUNCTION getLocalPath: map share drive to local path if possible
REM
REM @param %1 Specified a path (local or share drive)
REM @param %2 (Optional) user name access the share
REM @param %3 (Optional) user password access the share
REM
REM @return A local path or original specified path in .ret file
REM
REM @note This function may ask for user name, and password. To avoid that,
REM run "net use %1 /USER:username password" before call this function. Or
REM specify %2, and %3 parameters.
REM
REM @test CALL :getLocalPath \\share\xyz
REM       .ret should contains X: if the \\share\xyz exist
REM       .ret should contains \\share\xyz if it not exist
REM
REM @test CALL :getLocalPath c:\xyz
REM       .ret should contains c:\xyz
REM
:getLocalPath
SETLOCAL
SET test=%~1

REM Skip if not a share drive path, return original path
IF NOT "%test:~0,2%" == "\\" (
  ECHO %test%> .ret
  EXIT /b 0
)

REM Search of the share drive path already mapped. If found, return the
REM drive letter
FOR /F "tokens=1,2,*" %%a IN (
  'net use ^| findstr /R /B /C:"OK  *.:" ^| findstr /C:"%test%"'
) DO (
  ECHO %%a %%b %%c
  IF "%%a"=="OK" (
    ECHO %%b> .ret
    EXIT /b 0
  )
)

REM Map the share drive with a unused drive letter, and return the drive
REM letter
SET netOpts=NET USE * "%test%"
IF NOT "%~2" == "" SET netOpts=%netOpts% "/USER:%~2"
IF NOT "%~3" == "" SET netOpts=%netOpts% %3
ECHO Mapping %test% to a drive letter
ECHO "%netOpts%"
FOR /F "tokens=1,2,*" %%a IN ('%netOpts%') DO (
  ECHO %%a %%b %%c
  IF "%%a" == "Drive" (
    ECHO %%b> .ret
    EXIT /b 0
  )
)

REM Seem like share drive cannot be mapped, return original path
ECHO %test%> .ret
EXIT /b 0


REM 
REM FUNCTION HELP: Show help message and function documentation
REM
REM @param %2 Specify a function name
REM
:HELP
REM Search for document of a specific function %2
IF NOT "%~2"=="" (
  SETLOCAL EnableDelayedExpansion
  SET found=
  FOR /F "tokens=1,* delims=:" %%a IN (%0) DO (
    SET tmp=%%a
    SET tmpRem=!tmp:~0,3!
    IF NOT "!tmpRem!" == "REM" (
      IF NOT "!found!"=="" EXIT /b 0
    ) ELSE (
      SET tmp=!tmp:~4!
      IF "!tmp!" == "FUNCTION %2" SET found=%2
      IF NOT "!found!"=="" IF "%%b"=="" (ECHO.  !tmp!) ELSE (ECHO.  !tmp!:%%b)
    )
  )
)

FOR /F "tokens=1,* delims=M" %%a IN (%0) DO (
  IF NOT "%%a" == "@RE" EXIT /b 0
  ECHO.%%b
)
EXIT /b 0


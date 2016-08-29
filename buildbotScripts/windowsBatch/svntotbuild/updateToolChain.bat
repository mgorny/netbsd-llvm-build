@echo off
setlocal enabledelayedexpansion
call setEnv.bat || goto :error

REM constants for directory and filenames
SET NDK_BUNDLE_ID=ndk-bundle
SET SOURCE_PROPERTIES_FILENAME=source.properties
SET tempToolchain=C:\Toolchains_stage

SET updateLib=%rootDir%\\scripts\\lldb-utils\\buildbotScripts

SET DOWNLOAD_CHANNEL=0
SET EXISTING_PKG_REVISON_NUMBER=0
SET NEW_PKG_REVISION_NUMBER=0

SET isOptionHelp=0
SET isToolchainCreationNotNeeded=0

REM main function
call :getargc argc %*

if %argc% NEQ 2 if %argc% NEQ 0 (
  if %argc% NEQ 1 call :argumentErrors || goto :error
  if %argc% EQU 1 if NOT "%1" == "--help" if NOT "%1" == "-h" call :argumentErrors || goto :error
)

call :parseargs %1 %2
if %isOptionHelp% EQU 1 goto :end
if %errorlevel% NEQ 0 goto :end
call :detectNDK
call :updateNDK
call :isToolchainCreationRequired
if %isToolchainCreationNotNeeded% EQU 1 goto :end
call :createToolchains
if %errorlevel% NEQ 0 (
  echo "FATAL ERROR: Toolchain creation process failed"
  goto :end
) else (
  call :cleanupStageDirectory
  echo "Toolchain update was successfully completed!"
)
goto :end REM the end of the main function

REM parses arguments/options entered
:parseargs
  if %argc% EQU 0 (
    SET DOWNLOAD_CHANNEL=0
    call :checkSDKDir
    goto :eof
  )

  if "%~1"=="-h" (
    call :arg_help
    SET isOptionHelp=1
    goto :eof
  )
  if "%~1"=="--help" (
    call :arg_help
    SET isOptionHelp=1
    goto :eof
  )
  if "%~1"=="-c" (
    call :arg_channel %~2 || goto :error
    goto :eof
  )
  if "%~1"=="--channel" (
    call :arg_channel %~2 || goto :error
    goto :eof
  )

  call :argumentErrors || goto: error
  goto :eof

REM handles argument errors
:argumentErrors
  echo "Invalid number of options or arguments (enter option -h or --help for detail)"
  exit /b -1

REM prints help messages
:arg_help
  echo "Usage: [-c <channel_id>] or [--channel <channel_id>] for choosing from which server to download NDK"
  echo "Example: updateToolChain.bat -c 0 or updateToolChain --channel 1"
  echo "Note: If no optional argument is given, default channel is set to 0 or the stable server"
  exit /b 0

REM sets which channel to download the NDK from if the relevant argument is given
:arg_channel

  if %~1 NEQ 0 if %~1 NEQ 1 if %~1 NEQ 2 if %~1 NEQ 3 (
    echo "Invalid argument: channel argument must be one of 0, 1, 2, and 3"
    exit /b -1
  )
  SET DOWNLOAD_CHANNEL=%~1
  call :checkSDKDir
  goto :eof

REM checks whether SDK already exists
:checkSDKDir
  if NOT EXIST %sdkDir% (
    echo "Error: Need to reset sdkDir environment variable (see setEnv.bat)"
    exit /b -1
  )
  echo checkSDKDir %DOWNLOAD_CHANNEL%
  goto :eof

REM detects NDK and print relevant messages using relevant helper functions, NDKDetected and NDKNotDetected
:detectNDK
  echo "Starting ndk update..."
  if EXIST %sdkDir%/%NDK_BUNDLE_ID%/%SOURCE_PROPERTIES_FILENAME% (
    call :NDKDetected
  ) else (
    call :NDKNotDetected
  )
  goto :eof

:NDKDetected
  call :getNDKVersion %toolchain%/%SOURCE_PROPERTIES_FILENAME% EXISTING_PKG_REVISON_NUMBER
  echo "Existing ndk-bundle detected... version-%EXISTING_PKG_REVISON_NUMBER%"
  goto :eof

:NDKNotDetected
  echo "No existing ndk-bundle detected"
  goto :eof

REM retrieves NDK version from the source.properties file
:getNDKVersion
  grep Pkg.Revision %~1 | cut -d '=' -f2 | sed 's/^ *//g' | sed 's/ *$//g' > tmp.txt
  SET /p %~2=<tmp.txt
  del tmp.txt
  goto :eof

REM updates NDK
:updateNDK
  cd %updateLib%
  java -cp "lib\repository.jar;lib\sdklib.jar;lib\commons-compress-1.0.jar;lib\common.jar;lib\guava-17.0.jar;lib\httpcore-4.4.1.jar;lib\httpclient-4.4.1.jar;lib\commons-logging-1.2.jar" com.android.sdklib.tool.SdkDownloader --channel=%DOWNLOAD_CHANNEL% %sdkDir% %NDK_BUNDLE_ID%
  cd %sdkDir%
  goto :eof

REM checks whether new toolchain creation is required
:isToolchainCreationRequired
  call :getNDKVersion %sdkDir%/%NDK_BUNDLE_ID%/%SOURCE_PROPERTIES_FILENAME% NEW_PKG_REVISION_NUMBER
  echo "New ndk-bundle installed: version-%NEW_PKG_REVISION_NUMBER%"
  if "%EXISTING_PKG_REVISON_NUMBER%" == "%NEW_PKG_REVISION_NUMBER%" if EXIST %toolchain% (
    echo "NDK and tollchains are already up to date..."
    echo "No toolchain creation required... DONE"
    SET isToolchainCreationNotNeeded=1
  )
  goto :eof

REM create toolchains using helper functions by nesting innerLoop function in itself
:createToolchains
  echo ===========================
  for /f "tokens=1,2,3 delims= " %%a in (%updateLib%/testcfg/arch_api_preset.cfg) do (
    call :innerLoop "%%a" "%%b" "%%c"
    echo ===========================
  )
  goto :eof

:installToolchain
  SET install_dir=%~2-%~3
  if %~4 EQU 0 (
    echo installing at directory: %install_dir%-clang
    bash -li %sdkDir%/%NDK_BUNDLE_ID%/build/tools/make-standalone-toolchain.sh --platform=android-%~3 --toolchain=%~1 --install-dir=%tempToolchain%/%install_dir%-clang
  )
  if %~4 EQU 1 (
    echo installing at directory: %install_dir%
    bash -li %sdkDir%/%NDK_BUNDLE_ID%/build/tools/make-standalone-toolchain.sh --platform=android-%~3 --toolchain=%~1 --install-dir=%tempToolchain%/%install_dir%
  )
  goto :eof

:executeInstallToolchain
  if NOT "%~1" == """" if NOT "%~1" == "" (
    call :installToolchain %~2 %~3 %~4 0
  ) else (
    call :installToolchain %~2 %~3 %~4 1
  )
  goto :eof

REM innerLoop of createToolchains function that calls executeInstallToolchain
:innerLoop
  for /f "tokens=1,2,3 delims=," %%i in ("%~3") do (
    SET result=""
    echo Presets: %~1  %~2  %~3, Parsed API levels: %%i %%j %%k

    echo %~1 | grep clang > tmp2.txt
    SET /p result=<tmp2.txt
    del tmp2.txt

    if NOT "%%i"=="" call :executeInstallToolchain !result! %~1 %~2 %%i
    if NOT "%%j"=="" call :executeInstallToolchain !result! %~1 %~2 %%j
    if NOT "%%k"=="" call :executeInstallToolchain !result! %~1 %~2 %%k
  )
  goto :eof

REM cleans up the temporary directory
:cleanupStageDirectory
  rmdir /s /q %toolchain%
  cd %tempToolchain%
  cd ..
  ren %tempToolchain% %toolchain%
  xcopy %sdkDir%\%NDK_BUNDLE_ID%\%SOURCE_PROPERTIES_FILENAME% %toolchain%\%SOURCE_PROPERTIES_FILENAME%*
  goto :eof

REM counts the number of arguments given to the script
:getargc
  SET getargc_v0=%1
  SET /a "%getargc_v0% = 0"
:getargc_10
  if not "%2"=="" (
      shift
      SET /a "%getargc_v0% = %getargc_v0% + 1"
      goto :getargc_10
  )
  SET getargc_v0=
  goto :eof

:error
  exit /b %errorlevel%
:end
  echo "Terminating..."
  echo "-> DEBUGGING: %errorlevel%"
  exit /b %errorlevel%

endlocal

echo on
SET testexitcode=0
FOR /F "tokens=1,2,3,4,5 delims=," %%A IN ("%*") DO (
    SET deviceId=%%A
    SET compiler=%%B
    SET arch=%%C
    SET socket=%%D
    SET categories=%%E
)

:loop
IF "%categories%"=="" goto done
FOR /F "tokens=1* delims=:" %%A IN ("%categories%") DO (
    SET category=%%A
    SET categories=%%B
)
IF "%category:~0,1%"=="-" SET switch=--skip-category
IF "%category:~0,1%"=="+" SET switch=--category
SET categoryArgs=%categoryArgs% %switch% %category:~1%
goto loop
:done

SET LLDB_TEST_THREADS=8

call taskkill /f /im "adb.exe" || true
call adb -s %deviceId% shell getprop ro.build.fingerprint
call adb -s %deviceID% shell ps | grep lldb-server | awk "{print $2}" | xargs adb -s %deviceID% shell kill
call adb -s %deviceID% shell rm -rf %remoteDir%
call adb -s %deviceID% shell mkdir %remoteDir%
call adb -s %deviceId% push %buildDir%\android-%arch%\bin\lldb-server %remoteDir%/ || goto :error
call adb -s %deviceId% shell chmod 755 %remoteDir%/lldb-server || goto :error
call adb forward --remove-all
call C:\Cygwin64\bin\screen -d -m adb -s %deviceId% shell TMPDIR=%remoteDir%/tmp %remoteDir%/lldb-server platform --listen 127.0.0.1:%port% --server || goto :error

if "clang"=="%compiler:~-5%" (
    SET toolchain=llvm
    SET compiler=clang
) else (
    if "i686-"=="%compiler:~0,5%" (
        SET toolchain=x86-4.9
    ) else if "x86_64-"=="%compiler:~0,7%" (
        SET toolchain=x86_64-4.9
    ) else (
        SET toolchain=%compiler:~0,-4%-4.9
    )
)

call %pythonHome%\python.exe %lldbDir%\test\dotest.py ^
--executable %buildDir%\bin\lldb.exe ^
-A %arch% -C %ANDROID_NDK_HOME%/toolchains/%toolchain%/prebuilt/windows-x86_64/bin/%compiler%.exe ^
-v -s c:\logs\logs-gcc-%arch% ^
--build-dir c:\logs\build ^
--platform-name remote-android ^
--platform-url adb://%deviceId%:%port% ^
--platform-working-dir %remoteDir% ^
%categoryArgs%

SET testexitcode=%errorlevel%

echo "Post Clean-Up"
SET PATH=%PATH%;C:\Cygwin64\bin
svn status %lldbDir%\test --no-ignore | grep "^[I?]" | cut -c 9- | sed 's:\\:/:g' | xargs rm
adb -s %deviceID% shell ps | grep lldb-server | awk "{print $2}" | xargs adb -s %deviceID% shell kill
adb -s %deviceID% shell rm -rf %remoteDir%
call taskkill /f /im "adb.exe"

:error
if %testexitcode% NEQ 0 (
    exit /b %testexitcode%
)
exit /b %errorlevel%

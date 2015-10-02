
SET gs_asbin_linux=gs://android-build-lldb/builds/git_lldb-%1-linux-lldb_linux
SET gs_asbin_windows=gs://android-build-lldb/builds/git_lldb-%1-windows-lldb_windows
cd ..
rm -rf build
rm -rf lldb
call gsutil cp -r %gs_asbin_windows%/%2/** . || goto :error
call gsutil cp -r %gs_asbin_linux%/%2/** . || goto :error
call unzip -o lldb-tests-* -d lldb/ || goto :error
call unzip -o lldb-android-* -d build/ || goto :error
call unzip -o lldb-windows-* -d build/ || goto :error

:error
exit /b %errorlevel%
cd %originalDir%

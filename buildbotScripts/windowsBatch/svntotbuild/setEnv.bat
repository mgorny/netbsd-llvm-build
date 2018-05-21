@echo off
SET originalDir=%cd%
SET rootDir=%~dp0..
SET llvmDir=%rootDir%\llvm
SET lldbDir=%llvmDir%\tools\lldb
SET clangDir=%llvmDir%\tools\clang
SET buildDir=%rootDir%\build
SET pythonHome=C:\Users\lldb_build\ll\prebuilts\python-2015\x64
SET remoteDir=/data/local/tmp/lldb

SET ANDROID_NDK_HOME=C:\android-ndk-r17
SET port=5430
SET lockDir=c:\tmp\lock\lldbbuild.exclusivelock
SET PATH=%PATH%;%pythonHome%
call "%VS140COMNTOOLS%\..\..\VC\vcvarsall.bat" amd64

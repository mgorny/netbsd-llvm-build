# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# inputs
# $PROJ - project name (cmake|ninja|swig)
# $VER - project version
# $1 - name of this file
#
# this file does the following:
#
# 1) define the following env vars
#    OS - linux|darwin|windows
#    USER - username
#    CORES - numer of cores (for parallel builds)
#    PATH (with appropriate compilers)
#    CFLAGS/CXXFLAGS/LDFLAGS
#    RD - root directory for source and object files
#    INSTALL - install directory/git repo root
#    SCRIPT_FILE=absolute path to the parent build script
#    SCRIPT_DIR=absolute path to the parent build script's directory
#    COMMON_FILE=absolute path to this file
# 2) create an empty tmp directory at /tmp/$PROJ-$USER
# 3) checkout the destination git repo to /tmp/prebuilts/$PROJ/$OS-x86/$VER
# 4) cd $RD

UNAME="$(uname)"
SCRATCH=/tmp
case "$UNAME" in
Linux)
    OS='linux'
    INSTALL_VER=$VER
    ;;
Darwin)
    OS='darwin'
    OSX_MIN=10.8
    export CFLAGS="$CFLAGS -mmacosx-version-min=$OSX_MIN"
    export CXXFLAGS="$CXXFLAGS -mmacosx-version-min=$OSX_MIN -stdlib=libc++"
    INSTALL_VER=$VER
    ;;
*_NT-*)
    USER=$USERNAME
    OS='windows'
    CORES=$NUMBER_OF_PROCESSORS
    # VS2013 x64 Native Tools Command Prompt
    case "$MSVS" in
    2013)
        export PATH="$PATH_PREFIX/c/Program Files (x86)/Microsoft Visual Studio 12.0/VC/bin/amd64/":"$PATH_PREFIX/c/Program Files (x86)/Microsoft Visual Studio 12.0/Common7/IDE/":"$PATH"
        export INCLUDE="C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\INCLUDE;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\ATLMFC\\INCLUDE;C:\\Program Files (x86)\\Windows Kits\\8.1\\include\\shared;C:\\Program Files (x86)\\Windows Kits\\8.1\\include\\um;C:\\Program Files (x86)\\Windows Kits\\8.1\\include\\winrt;"
        export LIB="C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\LIB\\amd64;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\ATLMFC\\LIB\\amd64;C:\\Program Files (x86)\\Windows Kits\\8.1\\lib\\winv6.3\\um\\x64;"
        export LIBPATH="C:\\Windows\\Microsoft.NET\\Framework64\\v4.0.30319;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\LIB\\amd64;C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\ATLMFC\\LIB\\amd64;C:\\Program Files (x86)\\Windows Kits\\8.1\\References\\CommonConfiguration\\Neutral;C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v8.1\\ExtensionSDKs\\Microsoft.VCLibs\\12.0\\References\\CommonConfiguration\\neutral;"
        INSTALL_VER=${VER}_${MSVS}
        ;;
    *)
        # g++/make build
        export CC=x86_64-w64-mingw32-gcc
        export CXX=x86_64-w64-mingw32-g++
        export LD=x86_64-w64-mingw32-ld
        ;;
    esac
    ;;
*)
    exit 1
    ;;
esac

RD=$SCRATCH/$PROJ-$USER
INSTALL="$RD/install"

# OSX lacks a "realpath" bash command
realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SCRIPT_FILE=$(realpath "$0")
SCRIPT_DIR="$(dirname "$SCRIPT_FILE")"
COMMON_FILE="$SCRIPT_DIR/$1"

cd /tmp # windows can't delete if you're in the dir
rm -rf $RD
mkdir -p $INSTALL
mkdir -p $RD
cd $RD

# clone prebuilt gcc
case "$OS" in
linux)
    GCC_DIR=$RD/gcc
    GCC_LIB=$GCC_DIR/lib/gcc/x86_64-linux/4.8 # crtbegin.o and libgcc.a
    GCC_LIB2=$GCC_DIR/x86_64-linux/lib64 # libgcc_s.so

    # can't get prebuilt clang working so we're using host clang-3.5 https://b/22748915
    export CC=clang-3.5
    export CXX=clang++-3.5
    export CFLAGS="$CFLAGS -fuse-ld=gold --sysroot $GCC_DIR/sysroot -B$GCC_LIB"
    export CXXFLAGS="$CFLAGS -Ix86_64-linux/include/c++/4.8 -Ix86_64-linux/include/x86_64-linux/c++/4.8"
    export LDFLAGS="$LDFLAGS -m64 --sysroot $GCC_DIR/sysroot -L$GCC_LIB -L$GCC_LIB2"
    # lldb uses at least one function from glibc2.12
    git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8 $GCC_DIR
    ;;
esac

commit_and_push()
{
    # check into a local git clone
    rm -rf $SCRATCH/prebuilts/$PROJ/
    mkdir -p $SCRATCH/prebuilts/$PROJ/
    cd $SCRATCH/prebuilts/$PROJ/
    git clone https://android.googlesource.com/platform/prebuilts/$PROJ/$OS-x86
    GIT_REPO="$SCRATCH/prebuilts/$PROJ/$OS-x86"
    cd $GIT_REPO
    git rm -r * || true  # ignore error caused by empty directory
    mv $INSTALL/* $GIT_REPO
    cp $SCRIPT_FILE $GIT_REPO
    cp $COMMON_FILE $GIT_REPO

    git add .
    git commit -m "Adding binaries for $INSTALL_VER"

    # execute this command to upload
    #git push origin HEAD:refs/for/master

    rm -rf $RD || true  # ignore error
}
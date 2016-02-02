#!/bin/bash -ex
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# Download & build python on the local machine
# works on Linux, OSX, and Windows (Cygwin)
# leaves output in /tmp/prebuilts/python/$OS-x86

PROJ=python
VER=2.7.10
MSVS=2013

source "$(dirname "${BASH_SOURCE[0]}")/build-common.sh" "$@"

BASE=Python-$VER
TGZ=$BASE.tgz
curl -L https://www.python.org/ftp/python/$VER/$TGZ -o $TGZ
tar xzf $TGZ || cat $TGZ # if this fails, we're probably getting an http error
cd $BASE

case "$OS" in
windows)
	cp PC/pyconfig.h Include/
	devenv PCbuild/pcbuild.sln /Upgrade
        # Not all projects will build (due to missing dependencies), so we build only a selected
        # set. The rest are not needed for our purposes anyway.
	for project in _ctypes _ctypes_test _elementtree _multiprocessing _socket _testcapi \
		bdist_wininst kill_python make_buildinfo make_versioninfo pyexpat python \
		pythoncore pythonw select unicodedata w9xpopen winsound; do

		devenv PCbuild/pcbuild.sln /Build Debug /Project $project
		devenv PCbuild/pcbuild.sln /Build Release /Project $project
		devenv PCbuild/pcbuild.sln /Build "Debug^|x64" /Project $project
		devenv PCbuild/pcbuild.sln /Build "Release^|x64" /Project $project
	done
	curl -L http://llvm.org/svn/llvm-project/lldb/trunk/scripts/install_custom_python.py -o install_custom_python.py
	python install_custom_python.py --source "$(cygpath -w "$RD/$BASE")" --dest "$(cygpath -w "$INSTALL")" --overwrite --silent
	;;
linux|darwin)
	unset CFLAGS CXXFLAGS
	mkdir $RD/build
	cd $RD/build
	$RD/$BASE/configure --prefix=$INSTALL --enable-unicode=ucs4 --enable-shared
	make -j$CORES
	make install
	;;
esac

find $INSTALL '(' -name '*.pyc' -or -name '*.pyo' ')' -delete

finalize_build

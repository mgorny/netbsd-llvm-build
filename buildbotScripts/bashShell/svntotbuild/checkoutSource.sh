#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

maybeCleanUp

export llvmsvn=https://llvm.org/svn/llvm-project/llvm/trunk
export clangsvn=https://llvm.org/svn/llvm-project/cfe/trunk
export ctesvn=https://llvm.org/svn/llvm-project/clang-tools-extra/trunk
export lldbsvn=https://llvm.org/svn/llvm-project/lldb/trunk
export lldsvn=https://llvm.org/svn/llvm-project/lld/trunk
export pollysvn=https://llvm.org/svn/llvm-project/polly/trunk
export testsuitesvn=https://llvm.org/svn/llvm-project/test-suite/trunk
export openmpsvn=https://llvm.org/svn/llvm-project/openmp/trunk
export libunwindsvn=https://llvm.org/svn/llvm-project/libunwind/trunk
export libcxxabisvn=https://llvm.org/svn/llvm-project/libcxxabi/trunk
export libcxxsvn=https://llvm.org/svn/llvm-project/libcxx/trunk

if [ "$1" == "" ]; then
    export rev=HEAD
else
    export rev=$1
fi

function svnFunc {
  if [ -d "$1/.svn" ]; then
      svn cleanup $1
      svn update --non-interactive --no-auth-cache --revision $rev $1
  else
      svn checkout --non-interactive --no-auth-cache --revision $rev $2@$rev $1
  fi
}

svnFunc $llvmDir $llvmsvn
svnFunc $clangDir $clangsvn
svnFunc $cteDir $ctesvn
svnFunc $lldbDir $lldbsvn
svnFunc $lldDir $lldsvn
svnFunc $pollyDir $pollysvn
svnFunc $testsuiteDir $testsuitesvn
svnFunc $openmpDir $openmpsvn
svnFunc $libunwindDir $libunwindsvn
svnFunc $libcxxabiDir $libcxxabisvn
svnFunc $libcxxDir $libcxxsvn

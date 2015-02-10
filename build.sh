ROOT=$(pwd)
export PATH=$PATH:$ROOT/clang/bin

#ln -s external/clang llvm/tools/clang
#ln -s external/lldb llvm/tools/lldb

mkdir -p out
cd out
cmake -GNinja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_LINKER=ld.gold -DCMAKE_BUILD_TYPE=Debug ../external/llvm
ninja

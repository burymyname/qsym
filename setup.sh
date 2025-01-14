#!/bin/bash

# check ptrace_scope for PIN
if ! grep -qF "0" /proc/sys/kernel/yama/ptrace_scope; then
  echo "Please run 'echo 0|sudo tee /proc/sys/kernel/yama/ptrace_scope'"
  exit -1
fi

git submodule init
git submodule update

# install system deps
sudo apt-get update
sudo apt-get install -y libc6 libstdc++6 linux-libc-dev gcc-multilib \
  llvm-dev g++ g++-multilib python python-pip \
  lsb-release

# install z3
pushd third_party/z3
rm -rf build
./configure
pushd build
make -j$(nproc)
sudo make install
popd
rm -rf build
./configure --x86
cd build
make -j$(nproc)
sudo cp libz3.so /usr/lib32/
popd

# build test directories
pushd tests
python build.py
popd

pushd third_party
wget http://sourceforge.net/projects/boost/files/boost/1.58.0/boost_1_58_0.tar.gz
tar -xvf boost_1_58_0.tar.gz
cd boost_1_58_0
./bootstrap.sh --with-libraries=graph --with-toolset=gcc
./b2 --libdir=/usr/lib32 define=_GLIBCXX_USE_CXX11_ABI=0 architecture=x86 address-model=32 -j$(nproc) install
./b2 --clean-all -n
./b2 --prefix=/usr define=_GLIBCXX_USE_CXX11_ABI=0 -j$(nproc) install
popd

cat <<EOM
Please install qsym by using (or check README.md):

  $ virtualenv venv
  $ source venv/bin/activate
  $ pip install .
EOM

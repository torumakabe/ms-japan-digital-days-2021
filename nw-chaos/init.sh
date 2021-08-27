#!/bin/bash
set -eo pipefail

apt update
apt -y install wget unzip
wget https://github.com/microsoft/ethr/releases/latest/download/ethr_linux.zip
unzip ethr_linux.zip
chmod +x ethr
mv ethr /usr/local/bin
rm ethr_linux.zip

apt -y install bison build-essential cmake flex git libedit-dev \
  libllvm6.0 llvm-6.0-dev libclang-6.0-dev python zlib1g-dev libelf-dev \
  libfl-dev python3-distutils
mkdir -p /tmp/bcc
pushd /tmp/bcc
git clone https://github.com/iovisor/bcc.git
mkdir bcc/build; cd bcc/build
cmake ..
make
make install
cmake -DPYTHON_CMD=python3 .. # build python3 binding
pushd src/python/
make
make install
popd
popd

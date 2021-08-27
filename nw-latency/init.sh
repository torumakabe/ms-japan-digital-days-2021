#!/bin/bash
apt update
apt -y install wget unzip
wget https://github.com/microsoft/ethr/releases/latest/download/ethr_linux.zip
unzip ethr_linux.zip
chmod +x ethr
mv ethr /usr/local/bin
rm ethr_linux.zip

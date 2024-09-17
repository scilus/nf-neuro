#!/usr/bin/env bash

# Setup for NF-CORE

npm install -g --save-dev --save-exact prettier
npm install -g --save-dev editorconfig
npm install -g --save-dev editorconfig-checker

mkdir -p $XDG_CONFIG_HOME/nf-neuro
touch $XDG_CONFIG_HOME/nf-neuro/.env
echo "source $XDG_CONFIG_HOME/nf-neuro/.env" >> ~/.bashrc

mkdir -p /nf-test/bin
cd /nf-test/bin/
curl -fsSL https://code.askimed.com/install/nf-test | bash -s ${NFTEST_VERSION}
echo "PATH=$PATH:/nf-test/bin" >> ~/.bashrc

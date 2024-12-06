#!/usr/bin/env bash

# Setup for NF-CORE

mkdir -p $XDG_CONFIG_HOME/nf-neuro
touch $XDG_CONFIG_HOME/nf-neuro/.env
echo "source $XDG_CONFIG_HOME/nf-neuro/.env" >> ~/.bashrc

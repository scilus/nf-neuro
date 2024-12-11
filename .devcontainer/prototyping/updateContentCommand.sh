#!/usr/bin/env bash


maxmem=$(grep MemTotal /proc/meminfo | awk '{print $2}')

cat <<EOF > $XDG_CONFIG_HOME/nf-neuro/.env
# This file is used to store environment variables for the project.
# It is sourced by the shell on startup of every terminals.

export PROFILE=docker
export NFCORE_MODULES_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_MODULES_BRANCH=main
export NFCORE_SUBWORKFLOWS_GIT_REMOTE=https://github.com/scilus/nf-neuro.git
export NFCORE_SUBWORKFLOWS_BRANCH=main

export DEVCONTAINER_RAM_LIMIT_GB=$((maxmem / 1024 / 1024))
export DEVCONTAINER_CPU_LIMIT=$(grep -c ^processor /proc/cpuinfo)

EOF

unset maxmem
NFCORE_VERSION=2.14.1

if [ -f poetry.lock ] && [ -f pyproject.toml ]
then
    poetry install --no-root
elif [ -f requirements.txt ]
then
    python3 -m pip install -r requirements.txt
else
    echo "No requirements file found, installing nf-core to version $NFCORE_VERSION using pip"
    python3 -m pip install nf-core==$NFCORE_VERSION
fi

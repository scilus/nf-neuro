#!/usr/bin/env bash

# Setup for NF-CORE

mkdir -p $XDG_CONFIG_HOME/nf-neuro
touch $XDG_CONFIG_HOME/nf-neuro/.env
echo "source $XDG_CONFIG_HOME/nf-neuro/.env" >> ~/.bashrc

# Try to download nf-neuro setup with poetry. If it fails, we defer to pip
{
    NFNEURO_RAW_REPOSITORY=https://raw.githubusercontent.com/scilus/nf-neuro/main
    NFCORE_VERSION=2.14.1
    wget -N $NFNEURO_RAW_REPOSITORY/pyproject.toml \
            $NFNEURO_RAW_REPOSITORY/poetry.toml \
            $NFNEURO_RAW_REPOSITORY/poetry.lock
} || {
    echo "Failed to download nf-neuro base project configuration. Creating requirements.txt for pip"
    echo "nf-core==$NFCORE_VERSION" > requirements.txt
}

# Try to download VSCode settings from nf-neuro
{
    NFNEURO_RAW_REPOSITORY=https://raw.githubusercontent.com/scilus/nf-neuro/main
    mkdir -p .vscode
    wget -N -P .vscode $NFNEURO_RAW_REPOSITORY/.vscode/settings.json
} || {
    echo "Could not fetch default extension settings from nf-neuro"
}

# Initial setup for a pipeline prototyping environment
#  - nf-core requires a .nf-core.yml file present, else it bugs out (issue nfcore/tools#3340)
touch .nf-core.yml

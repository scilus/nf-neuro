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

    poetry install --no-root
} || {
    echo "Failed to download nf-neuro base project configuration."
    echo "Installing nf-core version $NFCORE_VERSION in the current python"
    echo "interpreter using pip"
    python3 -m pip install nf-core==$NFCORE_VERSION
}

# Initial setup for a pipeline prototyping environment
#  - nf-core requires a .nf-core.yml file present, else it bugs out (issue nfcore/tools#3340)
touch .nf-core.yml

#!/usr/bin/env bash


GIT_REMOTE=$(git remote get-url origin)
CURRENT_BRANCH=
# Get tracked remote branch associated to current branch (default to main)
{
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null &&
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name HEAD 2>/dev/null)
} || {
    CURRENT_BRANCH="main"
}

maxmem=$(grep MemTotal /proc/meminfo | awk '{print $2}')

cat <<EOF > $XDG_CONFIG_HOME/nf-neuro/.env
# This file is used to store environment variables for the project.
# It is sourced by the shell on startup of every terminals.

export PROFILE=docker
export NFCORE_MODULES_GIT_REMOTE="$GIT_REMOTE"
export NFCORE_MODULES_BRANCH=$CURRENT_BRANCH
export NFCORE_SUBWORKFLOWS_GIT_REMOTE="$GIT_REMOTE"
export NFCORE_SUBWORKFLOWS_BRANCH=$CURRENT_BRANCH

export DEVCONTAINER_RAM_LIMIT_GB=$((maxmem / 1024 / 1024))
export DEVCONTAINER_CPU_LIMIT=$(grep -c ^processor /proc/cpuinfo)

EOF

unset maxmem

poetry install --no-root

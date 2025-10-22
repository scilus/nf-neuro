#!/usr/bin/env bash

# Update nf-neuro configuration : remote URLs, branches, resource limits
echo "🔄 Updating nf-neuro configuration..."
GIT_REMOTE=$(git remote get-url origin)
CURRENT_BRANCH=
# Get tracked remote branch associated to current branch (default to main)
{
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null &&
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name HEAD 2>/dev/null)
} || {
    CURRENT_BRANCH="main"
}
echo "🐙 Using GitHub remote: $GIT_REMOTE on branch: $CURRENT_BRANCH"

maxmem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
cpulimits=$(grep -c ^processor /proc/cpuinfo)
echo "🖥️ Detected system memory: $((maxmem / 1024 / 1024)) GB"
echo "🧠 Detected CPU cores: $cpulimits"

cat <<EOF > $XDG_CONFIG_HOME/nf-neuro/.env
# This file is used to store environment variables for the project.
# It is sourced by the shell on startup of every terminals.

export PROFILE=docker
export NFCORE_MODULES_GIT_REMOTE="$GIT_REMOTE"
export NFCORE_MODULES_BRANCH=$CURRENT_BRANCH
export NFCORE_SUBWORKFLOWS_GIT_REMOTE="$GIT_REMOTE"
export NFCORE_SUBWORKFLOWS_BRANCH=$CURRENT_BRANCH

export DEVCONTAINER_RAM_LIMIT_GB=$((maxmem / 1024 / 1024))
export DEVCONTAINER_CPU_LIMIT=$cpulimits

EOF

unset maxmem

# Reinstall Python dependencies
echo "📦 Reinstalling Python dependencies..."
poetry install --no-root

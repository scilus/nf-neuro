#!/usr/bin/env bash

# Setup for NF-CORE

npm install -g --save-dev --save-exact prettier
npm install -g --save-dev editorconfig
npm install -g --save-dev editorconfig-checker

mkdir -p $XDG_CONFIG_HOME/nf-neuro
touch $XDG_CONFIG_HOME/nf-neuro/.env
echo "source $XDG_CONFIG_HOME/nf-neuro/.env" >> ~/.bashrc

curl -fsSL https://code.askimed.com/install/nf-test | bash -s ${NFTEST_VERSION}
mv nf-test /usr/local/bin/.

# Setup GitHub Actions testing environment
echo "🎭 Setting up GitHub Actions testing tools..."

# Add GitHub Actions aliases to bashrc
cat <<'EOF' >> ~/.bashrc

# GitHub Actions Development Aliases
alias act-list='act -l'
alias act-lint='actionlint .github/workflows/*.yml'
alias act-dry='act --dryrun'

alias ga-test='echo "🧪 GitHub Actions Testing Commands:"; echo "  act-list     - List all workflows and jobs"; echo "  act-lint     - Lint workflow files"; echo "  act-dry      - Dry run workflows"'

EOF

echo "✅ GitHub Actions testing environment setup complete!"
echo "Run 'ga-test' to see available testing commands."

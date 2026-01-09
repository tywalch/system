#!/bin/bash

set -euo pipefail

# Ensure a GitHub org name is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <github-org-name> [destination]" 
  exit 1
fi

ORG="$1"
DEST="${2:-.}"

# default DEST to be working directory


# ensure gh is installed
if ! command -v gh &>/dev/null; then
  echo "Installing gh..."
  brew install gh
fi

# Ensure `gh` is authenticated
if ! gh auth status &>/dev/null; then
  
  # authenticate with gh
  echo "Authenticating with gh..."
  gh auth login

  # check if authentication is successful
  if ! gh auth status &>/dev/null; then
    echo "Authentication failed. Please try again."
    exit 1
  fi

  echo "Authentication successful."
fi

echo "Fetching repositories for organization: $ORG"

# Get all repository names (handling pagination)
REPOS=$(gh repo list "$ORG" --limit 1000 --json nameWithOwner -q '.[].nameWithOwner')

if [ -z "$REPOS" ]; then
  echo "No repositories found for organization: $ORG"
  exit 0
fi

# Clone each repository
for REPO in $REPOS; do
  echo "Cloning $REPO..."
  git clone "https://github.com/$REPO.git" "$DEST/$REPO"
done

echo "Done cloning repositories for $ORG."
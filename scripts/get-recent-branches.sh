#! /bin/bash

set -euo pipefail

if [ -z "$1" ]; then
  echo "Usage: $0 [-n <line_count>, --select]"
  exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -n)
            line_count="$2"
            shift 2
            ;;
        --select)
            select_flag="true"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

line_count="${line_count:-10}"
select_flag="${select_flag:-false}"

# list branches sorted by last commit date including branch name and commit date
recent_branches=$(git branch --sort=-committerdate --format='%(committerdate:short) %(refname:short)' | head -n "$line_count")

# if select flag is not present then print the branches
if [ "$select_flag" == "false" ]; then
    echo "$recent_branches"
    exit 0
fi

# if select flag is present then allow user to select and checkout the selected branch
# do not allow multi-select

# Convert branches to array for selection
IFS=$'\n' read -d '' -r -a branch_array <<< "$recent_branches"

echo "Select a branch to checkout:"
select branch in "${branch_array[@]}"; do
    if [[ -n "$branch" ]]; then
        selected_branche="$branch"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

# extract the branch name from the selected branch, split on whitespace
selected_branch_name=$(echo "$selected_branche" | sed 's/^\s*//' | cut -d ' ' -f 2)

git checkout "$selected_branch_name"

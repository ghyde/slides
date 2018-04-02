#!/bin/bash

set -ex

function merge_upstream() {
    local current_branch
    local stashed
    local response

    # Check if temporary branches already exist
    if [[ "$(git branch)" =~ (rename_branch|merge_branch) ]]; then
        echo "Remove temporary branches before running this script:"
        echo "    git branch -D rename_branch merge_branch"
        exit
    fi

    # Save current work
    current_branch="$(basename "$(git symbolic-ref HEAD)")"
    stashed="$(git stash)"

    # Update reveal.js master branch
    git checkout reveal-master
    git pull

    # Rename reveal.js files
    git checkout -b rename_branch
    git mv index.html template.html
    for f in LICENSE README.md CONTRIBUTING.md; do
        git mv {,REVEAL_}$f
    done
    git commit -m "(squash) Rename files"

    # Merge upstream changes
    git checkout gh-pages
    git checkout -b merge_branch
    git merge --squash -X theirs --allow-unrelated-histories rename_branch
    # Make sure swap files are ignored by Git
    if ! grep -q '*.swp' .gitignore; then
        sed -ir '/^\*\.eml$/a *.swp' .gitignore
        git add .gitignore
    fi
    git commit -m "Merge with upstream"

    read -r -p "Edit merge commit message? [y/N] " response
    response="$(echo "$response" | awk '{print tolower($0)}')"
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        git commit --amend  # Enter commit message
    fi

    read -r -p "Merge commits onto gh-pages branch? [y/N] " response
    response="$(echo "$response" | awk '{print tolower($0)}')"
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        git checkout gh-pages
        git merge merge_branch
    fi

    read -r -p "Delete temporary branches? [y/N] " response
    response="$(echo "$response" | awk '{print tolower($0)}')"
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        git checkout gh-pages
        git branch -D rename_branch merge_branch
    fi

    # Go back to work
    git checkout "$current_branch"
    if [[ "$stashed" != "No local changes to save" ]]; then
        git stash pop
    fi
}

merge_upstream

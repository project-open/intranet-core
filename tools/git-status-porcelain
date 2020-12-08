#!/bin/bash

# find "$(pwd -P)" -maxdepth 1 -mindepth 1 -type d -exec bash -c "cd {}; pwd; git status --porcelain" \;

# No directory has been provided, use current
dir="$1"
if [ -z "$dir" ]
then
    dir="`pwd`"
fi

# Make sure directory ends with "/"
if [[ $dir != */ ]]
then
    dir="$dir/*"
else
    dir="$dir*"
fi

# Loop all sub-directories
for f in $dir
do
    # Only interested in directories
    [ -d "${f}" ] || continue
    
    # Only interested in GIT repositories
    [ -d "$f/.git" ] || continue

    cd $f
    if [ $(git status --porcelain | wc -l) -eq 0 ]
    then
        continue
    fi

    # Format the output - use colors only in terminal
    if test -t 1; then
	echo ""
	echo -en "\033[0;35m"
	echo "${f}"
	echo -en "\033[0m"
    else
	echo "${f}"
    fi
    git status --porcelain
done

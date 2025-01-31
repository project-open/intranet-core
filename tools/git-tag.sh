#!/bin/bash

tag="$1"

# Make sure directory ends with "/"
dir="`pwd`"
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
    [ -f "$f/.git" ] || [ -d "$f/.git" ] || continue

    cd $f

    # Format the output - use colors only in terminal
    if test -t 1; then
	echo ""
	echo -en "\033[0;35m"
	echo "git-tag.sh: ${f}"
	echo -en "\033[0m"
    else
	echo "git-tag.sh: ${f}"
    fi

    git tag "${tag}"
done

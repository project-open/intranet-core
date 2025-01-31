#!/bin/bash

dir="`pwd`"

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
    [ -f "$f/.git" ] || [ -d "$f/.git" ] || continue

    cd $f

    # Format the output - use colors only in terminal
    if test -t 1; then
	echo ""
	echo -en "\033[0;35m"
	echo "${f}"
	echo -en "\033[0m"
    else
	echo "${f}"
    fi

    git push
done

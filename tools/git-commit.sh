#!/bin/bash

# expects a commit message as first argument
message="$1"

# Work in current directory
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

    # Check for changes
    modified=0
    if [ $(git diff | wc -l) -ne 0 ]
    then
        modified=1
    fi
    if [ $modified -eq 0 ]
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

    echo "git add ."
    git add .
    
    echo "git commit -m '$message'"
    git commit -m "$message"
    
done

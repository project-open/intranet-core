#!/bin/bash

# Install precommit hook for GIT
# Replaces:
# cd ~/packages/; git submodule foreach 'cp ~/packages/tools/pre-commit ~/packages/.git/modules/$name/hooks/'
# cd ~/packages/; git submodule foreach 'chmod ug+x ~/packages/.git/modules/$name/hooks/pre-commit'

# We assume that we are in ~/packages/ (submodules) or ~/packages-all/ (individual packages)
# Make sure directory ends with "/"
dir="`pwd`"
if [[ $dir != */ ]]
then
    dir="$dir/*"
else
    dir="$dir*"
fi


# Locate the pre-commit
# Assume it's 
precommit="~/packages/tools/pre-commit"
if [ ! -f "$precommit" ]; then
    echo "git-install-hooks.sh: Precommit not found: ${precommit}"
    exit 1
fi

echo "precommit found"
exit 0


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

    package=$(basename $f)

    # Check if .git is a folder - copy directly into .git/hooks/???
    if [ -d "${package}/.git" ]; then
	echo "git-install-hooks.sh: ${package}/.git is a folder, not implemented yet"
	exit 1
    fi

    # Check if ../.git/modules/$package/ is a folder - copy into 
    if [ -d "${package}/.git" ]; then
	echo "git-install-hooks.sh: ${package}/.git is a folder, not implemented yet"
	exit 1
    fi



# cd ~/packages/; git submodule foreach 'cp ~/packages/tools/pre-commit ~/packages/.git/modules/$name/hooks/'
# cd ~/packages/; git submodule foreach 'chmod ug+x ~/packages/.git/modules/$name/hooks/pre-commit'


    # cp ~/packages/tools/pre-commit ~/packages/.git/modules/$name/hooks/'
    # cd ~/packages/; git submodule foreach 'chmod ug+x ~/packages/.git/modules/$name/hooks/pre-commit'

    
    
done

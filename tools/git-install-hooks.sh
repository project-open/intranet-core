#!/bin/bash

# Install precommit hook for GIT
# Replaces:
# cd ~/packages/; git submodule foreach 'cp ~/packages/tools/pre-commit ~/packages/.git/modules/$name/hooks/'
# cd ~/packages/; git submodule foreach 'chmod ug+x ~/packages/.git/modules/$name/hooks/pre-commit'

# We assume that we are in ~/packages/ (submodules) or ~/packages-all/ (individual packages)
# Make sure directory ends with "/"
packages_folder="`pwd`"
if [[ $packages_folder != */ ]]
then
    packages_folder="$packages_folder/"
fi


# Locate the pre-commit
# Assume it's ~/packages/tools/pre-commit
precommit="${packages_folder}tools/pre-commit"
if [ ! -f "$precommit" ]; then
    echo "git-install-hooks.sh: Precommit not found: ${precommit}"
    exit 1
fi

# Loop all sub-directories
folders="${packages_folder}*"
for f in $folders
do
    # Only interested in directories
    [ -d "${f}" ] || continue

    # Only interested in GIT repositories
    [ -f "$f/.git" ] || [ -d "$f/.git" ] || continue

    echo "git-install-hooks.sh: found git folder $f"
    cd $f

    # Format the output - use colors only in terminal
    if test -t 1; then
	# echo ""
	echo -en "\033[0;35m"
	echo "git-install-hooks.sh: f=${f}"
	echo -en "\033[0m"
    else
	echo "git-install-hooks.sh: f=${f}"
    fi

    package=$(basename $f)
    echo "git-install-hooks.sh: package=$package"

    # Check if .git is a folder - copy directly into .git/hooks/???
    if [ -d "${f}/.git" ]; then
	echo "git-install-hooks.sh: found folder ${f}/.git"
	echo "git-install-hooks.sh: cp $precommit ${f}/.git/hooks/"
	cp $precommit ${f}/.git/hooks/
	echo "git-install-hooks.sh: chmod ug+x ${f}/.git/hooks/pre-commit"
	chmod ug+x ${f}/.git/hooks/pre-commit
    fi

    # Check if ../.git/modules/$package/ is a folder - copy into 
    if [ -f "${f}/.git" ]; then
	echo "git-install-hooks.sh: found file ${package}/.git"
	cp $precommit ${packages_folder}/.git/modules/${package}/hooks/
	chmod ug+x ${packages_folder}/.git/modules/${package}/hooks/pre-commit
    fi
    
done

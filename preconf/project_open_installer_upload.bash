#!/bin/bash
BASE=`echo "$1" | xargs basename`

# echo 'rsync -avP -e ssh "$1" "fraber,project-open\@frs.sourceforge.net:/home/frs/project/p/pr/project-open/project-open/V5.0/"'

echo rsync -avP -e ssh /cygdrive/c/download/$BASE "fraber,project-open\@frs.sourceforge.net:/home/frs/project/p/pr/project-open/project-open/V5.0/"


exit 0

################################################################
#   v0.1  - USE WITH CAUTION
#   Last changed: 2016-10-12
################################################################
# 
# Drops ]po[ 4.x and ]po[ 5.x servers   
#
################################################################
# ToDo:
################################################################

# defaults

# function usage () {
#        cat <<EOF
#            Usage: createserver.sh [options] user [password]
#            -h, --help          help
#            Example: dropserver.sh worldbank
#        EOF
#    exit
# }

# Must run as root so that we can shutdown backuppc and mount drives 
if [ $(whoami) != "root" ]; then
    echo "You need to run this script as root."
    echo "Use 'sudo ./$script_name' then enter your password when prompted."
    exit 1
fi

POUSER=$1

if [ $? != 0 ] ; then
    echo "wrong option..." >&2 ;
    # usage
fi

if test "$POUSER" = ""; then
    echo "param missing"
    # usage
fi

#
# directories
#

WEBDIR=/web
HOMEDIR=$WEBDIR/$POUSER
SERVICEDIR=/web/service/$POUSER

GRAVEYARD=/web/garbage/backup_canceled_servers

echo "drop server for '$POUSER'"
read -p "Continue (y/n)?"

if [ $REPLY == "n" ]; then
    exit 1
fi

echo "Remove ]po[ v4 (PostgreSQL 8.4) or v5 (PostgreSQL 9.x)? "
echo "]po[ Server (4/5)?"
read pgversion

if [ $pgversion = 4 ]; then
    echo "Setting executables for PostgreSQL 8.4"
    PGDUMP=/usr/bin/pg_dump
    DROPDB=/usr/bin/dropdb
    DROPUSER=/usr/bin/dropuser
elif [ $pgversion = 5 ]; then
    echo "Setting executables for PostgreSQL 9.x"
    PGDUMP="/usr/local/pgsql95/bin/pg_dump -p 5433"
    DROPDB="/usr/local/pgsql95/bin/dropdb -p 5433"
    DROPUSER="/usr/bin/dropuser -p 5433"
else
    echo "Unable to set executables. Quitting"
    exit 1
fi

# Alternatives:
# PGDUMP="/usr/local/pgsql/bin/pg_dump -p 5433"
# DROPDB="/usr/local/pgsql/bin/dropdb -p 5433"
# DROPUSER="/usr/local/pgsql/bin/dropuser -p 5433"

NOW=$(date +"%y%m%d%H%M%S")
echo "Creating unique folder in /tmp: $NOW"
mkdir /tmp/$NOW

if ! test -e $SCRIPTDIR/$DBDUMP; then
    echo "$SCRIPTDIR/$DBDUMP doesn't exist (SCRIPTDIR=$SCRIPTDIR)"
    exit
fi

# shut down service
# svc -d /web/service/$POUSER

# delete old backups & dump database

echo ""

echo "Now Shut down server ..."
echo "svc -d /web/service/$POUSER"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    svc -d /web/service/$POUSER
    echo "server shut down"
fi

echo ""

echo "Now move old backups to temp folder ...."
echo "mv /web/$POUSER/filestorage/backup/*.sql /tmp/$NOW/"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    mv /web/$POUSER/filestorage/backup/*.sql /tmp/$NOW/
    echo "moved files to tmp folder"
fi

echo ""

echo "Creating DB dump:"
echo "/bin/su --login $POUSER --command $PGDUMP --no-owner --clean --disable-dollar-quoting --format=p --file=/web/$POUSER/filestorage/backup/pg_dump.aachen.project-open.net.$POUSER.final.sql"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    /bin/su --login $POUSER --command "$PGDUMP --no-owner --clean --disable-dollar-quoting --format=p --file=/web/$POUSER/filestorage/backup/pg_dump.aachen.project-open.net.$POUSER.final.sql"
    echo "created new db_dump"
fi

echo ""

echo "Drop DB:"

echo "/bin/su --login $POUSER --command '$DROPDB $POUSER'"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    /bin/su --login $POUSER --command "$DROPDB $POUSER"
    echo "dropped db"
fi

echo ""

echo "Now tar filstorage and move to grave yard ..."
echo "tar czvf $GRAVEYARD/filestorage_$POUSER.tgz /web/$POUSER/filestorage"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    tar czvf $GRAVEYARD/filestorage_$POUSER.tgz /web/$POUSER/filestorage
    echo "Filestorage moved to grave yard"
fi

echo ""

echo "Now removing server:"
echo "mv /web/$POUSER /tmp/$NOW/"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    mv /web/$POUSER /tmp/$NOW/
    echo "Moved server to tmp folder"
fi

echo ""

# echo "Now removing service ..."
# echo "mv /web/service/$POUSER /tmp/$NOW"
# read -p "Continue (y/n)?"
# if [ $REPLY == "y" ]; then
#    mv /web/service/$POUSER /tmp/$NOW
#    echo "Moved server to tmp folder"
# fi
# echo ""

echo "Now delete user ..."
echo "userdel $POUSER"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    userdel $POUSER
    echo "User deleted"
fi

echo ""

echo " /bin/su --login postgres --command '$DROPUSER $POUSER'"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    /bin/su --login postgres --command "$DROPUSER $POUSER"
    echo "db user dropped"
fi

echo "Now removing service ..."
echo "mv /web/service/$POUSER /tmp/$NOW/ttt"
read -p "Continue (y/n)?"
if [ $REPLY == "y" ]; then
    mv /web/service/$POUSER /tmp/$NOW/ttt
    echo "Moved service directory to tmp folder"
fi

echo ""
echo ""
echo ""
echo "*** Finished script ***"
echo ""
echo ""

exit 0


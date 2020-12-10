################################################################
# c christof.Damian@project-open.com
#   klaus.hofeditz@project-open.com
#
#   v0.7  - USE WITH CAUTION
#
#   Last changed: 20131204
#
################################################################
#
# required software:
# - pwgen       for random password if not supplied
# - htpasswd2   to change the cvs passwd file, this comes with
#               the apache2 rpm
################################################################
# ToDo: 
# 
# To check with next install:
# 	- Check update of parameter SystemURL 
#	- UPDATE apm_parameter_values SET attr_value='/web/$POUSER/filestorage/projects/internal/template_logo/logo.gif' WHERE value_id = 515; changed intranet-core::BackupBasePathUnix 
################################################################

# defaults
POPORT=0
CVS_SERVER=cvs.project-open.net
COM_FREELANCE=0
COM_FIN_REPORTS=0
COM_TRANS_REPORTS=0
BRANCH=HEAD
REMOTE=0
DBDUMP=dump_4_0_with_commercial_packages.sql.gz


function usage () {
    cat <<EOF
Usage: createserver.sh [options] user [password]

  -h, --help          help
  -f, --freelance     check out commercial freelance modules
  -i, --finance       check out commercial finance modules
  -t, --translation   check out commercial
  -p, --port=port     define port for webservice
  -r, --remote        don't create the db & db rights & service
  -b, --branch=tag    branch to check out (default=$BRANCH)

Examples:

  createserver.sh --port=80 --finance testuser secret
  createserver.sh -ifr -p 9000 anotheruser

EOF
    exit
}

#
# option parsing
#

TEMP=`getopt -o fitp:hrb: --long "freelance,finance,translation,port:,help,remote,branch" \
     -n $0 -- "$@"`


if [ $? != 0 ] ; then
    echo "wrong option..." >&2 ;
    usage
fi

eval set -- "$TEMP"

while true ; do
    case "$1" in
        -f|--freelance)
            COM_FREELANCE=1
            shift
            ;;
        -i|--finance)
            COM_FIN_REPORTS=1
            shift
            ;;
        -t|--translation)
            COM_TRANS_REPORTS=1
            shift
            ;;
        -p|--port)
            POPORT=$2
            shift 2
            ;;
        -b|--branch)
            BRANCH=$2
            shift 2
            ;;
        -r|--remote)
            REMOTE=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        --) shift ; break ;;
        *) echo "Internal error!"; exit ;;
    esac
done

POUSER=$1
POPASS=$2

if test "$POUSER" = ""; then
    usage
fi

if test "$POPASS" = ""; then
    if ! test -x "/usr/bin/pwgen"; then
        echo "pwgen not found, please specify a password"
        usage
    fi

    POPASS=`pwgen 8 1`
fi


#
# directories
#

WEBDIR=/web
CVS_ROOT=/var/cvsd/home/cvsroot/
HOMEDIR=$WEBDIR/$POUSER
SERVICEDIR=/web/service/$POUSER
CVS_ROOT_PAR=:pserver:$POUSER:$POPASS@$CVS_SERVER:/home/cvsroot

# find the directory which contains the inital home tar and
# sql dump
tmp=`dirname $0`
SCRIPTDIR=`( cd $tmp; pwd )`

cat <<EOF
creating server for '$POUSER'
  password    : $POPASS
  home        : $HOMEDIR
  service     : $SERVICEDIR
  port        : $POPORT
  freelance   : $COM_FREELANCE
  finance     : $COM_FIN_REPORTS
  translation : $COM_TRANS_REPORTS
  remote      : $REMOTE
  branch      : $BRANCH
  scriptdir   : $SCRIPTDIR
EOF

#
# sanity checks
#

if ! test -e $SCRIPTDIR/$DBDUMP; then
    echo "$SCRIPTDIR/$DBDUMP doesn't exist (SCRIPTDIR=$SCRIPTDIR)"
    exit
fi

# if ! test -e $CVSROOT; then
#    echo "CVSROOT doesn't exist (CVSROOT=$CVSROOT)"
#    exit
# fi

################################################################
# create users / groups
################################################################
# echo "- creating user + group"

mkdir -p $HOMEDIR
groupadd $POUSER
useradd -g $POUSER -d $HOMEDIR $POUSER
# it might be an idea to use '-m' to create the homedir with
# useradd, this also creates the default dot files

# change permissions
echo "- changing home directory permissions"
chown -R $POUSER:$POUSER $HOMEDIR

# ################################################################
# # set .bashrc
# ################################################################

echo "- configuring .bash_profile"
cat >> $HOMEDIR/.bash_profile <<EOF
export CVSROOT=":pserver:$POUSER:$POPASS@$CVS_SERVER:/home/cvsroot"
export CVSREAD="yes"
export CVS_RSH="ssh"
export PATH=$PATH:/usr/bin/psql
PS1="[\u@\h \w]\\$ "

EOF

/bin/su --login $POUSER --command "source  $HOMEDIR/.profile"

# ################################################################
# # create db
# ################################################################

if test "$REMOTE" = "0"; then
     echo "- creating db"
     /bin/su --login postgres --command "createuser --adduser --createdb $POUSER"
     /bin/su --login postgres --command "createdb --owner $POUSER $POUSER"
     /bin/su --login postgres --command "createlang plpgsql --dbname $POUSER"

     echo "- loading db"
     /bin/su --login $POUSER --command "zcat $SCRIPTDIR/$DBDUMP | /usr/bin/psql --quiet --dbname $POUSER > $HOMEDIR/db-init.log 2>&1 "

     sleep 360 

     echo "- replacing attributes"

     /bin/su --login $POUSER --command "/usr/bin/psql --quiet --dbname $POUSER -c \"UPDATE apm_parameter_values SET attr_value=REPLACE(attr_value,'/web/pttgc/','/web/$POUSER/') WHERE attr_value LIKE '/web/%';\"";
     /bin/su --login $POUSER --command "/usr/bin/psql --quiet --dbname $POUSER -c \"UPDATE apm_parameter_values SET attr_value='http://$POUSER.project-open.net' WHERE attr_value LIKE '%http://pttgc.project-open.net%';\"";


#    fix menu 
#    /bin/su --login $POUSER --command "/usr/bin/psql --quiet --dbname $POUSER -c \"update im_menus set url='/intranet-reporting-cubes/timesheet-cube?' where menu_id = 28152;\"";

else
     echo "- copying sql file into home"
     cp $SCRIPTDIR/$DBDUMP $HOMEDIR
fi

# ################################################################


# ################################################################
# # Create dir/files
# ################################################################

echo "- unpacking home directory"
tar xfz $SCRIPTDIR/home.tgz -C $HOMEDIR

echo "- configuring config.tcl"
sed "s/@@POUSER@@/$POUSER/g; s/@@POPORT@@/$POPORT/g;" < $SCRIPTDIR/config40.tcl > $WEBDIR/$POUSER/etc/config.tcl

ln -s $HOMEDIR/filestorage/projects/internal/template_logo/logo.gif $HOMEDIR/www/logo.gif 

# change permissions
echo "- changing home directory permissions"
chown -R $POUSER:$POUSER $HOMEDIR

mv $HOMEDIR/packages $HOMEDIR/packages.old

# create sym link
ln -s /web/po40patches/packages/ $HOMEDIR/packages

# ################################################################
# # daemon tools
# ################################################################


if test "$REMOTE" = "0"; then
    echo "- daemontools setup"

    echo "  - creating service dir: $SERVICEDIR"
    mkdir -p $SERVICEDIR
    cat > $SERVICEDIR/run <<EOF
#!/bin/sh
# give time for Postgres to come up
sleep 20
exec /usr/local/aolserver45/bin/nsd-postgres -it $HOMEDIR/etc/config.tcl -u $POUSER -g $POUSER
EOF
    chmod 755 $SERVICEDIR $SERVICEDIR/run
    echo "  - starting service"
    svc -d $SERVICEDIR
    svc -u $SERVICEDIR
fi

exit 0

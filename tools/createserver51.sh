################################################################
# (c) christof.Damian@project-open.com
#     klaus.hofeditz@project-open.com
#     frank.bergmann@project-open.com
#
#   v0.9  - USE WITH CAUTION
#
#   Last changed: 2020-12-10
#
################################################################
# Required software:
# - pwgen       for random password if not supplied
# - htpasswd2   to change the cvs passwd file, this comes with
#               the apache2 rpm
################################################################
# Configuration changes required (not part of current dump)
#   - Change SuppressHttpPort to 1
#   - various update scripts
#
################################################################

echo "##########################################################"
echo "# Defaults and parameters"
echo "##########################################################"

#
# Parameters
#
DRY=0
PGPORT=5432
COM_FREELANCE=0
COM_FIN_REPORTS=0
COM_TRANS_REPORTS=0
BRANCH=master
TIMESTAMP=`date +"%Y-%m-%d.%H-%M-%S"`
GIT_SERVER=gitlab.project-open.net
GIT_BASE=https://$GIT_SERVER/project-open/

#
# Directories
#
PGDIR=/usr/bin
PGDUMP=/web/po51patches/pg_dump.5.1.0.0.0.enterprise.sql.gz
HOMEDUMP=/web/po51patches/home51.tgz
CONFFILE=/web/po51patches/config51.conf
PACKAGES_DIR=packages
NGINX_CONF_DIR=/etc/nginx/config.d

function usage () {
    cat <<EOF
Usage: createserver.sh [options] user [password]

  -h, --help          help
  -d, --dry           dry run, no actions taken
  -f, --freelance     clone commercial freelance packages
  -i, --finance       clone commercial finance packages
  -t, --translation   clone commercial translation packages
  -p, --port=port     define port for webservice
  -b, --branch=tag    branch to clone (default=$BRANCH)

Examples:

  createserver51.sh --port=80 --finance testuser secret
  createserver51.sh -ifr -p 9000 anotheruser

EOF
    exit
}

#
# option parsing
#
TEMP=`getopt -o dfitp:hrb: --long "dry,freelance,finance,translation,port:,help,branch" -n $0 -- "$@"`

if [ $? != 0 ] ; then
    echo "wrong option..." >&2 ;
    usage
fi
eval set -- "$TEMP"
while true ; do
    case "$1" in
        -d|--dry)
            DRY=1
            shift
            ;;
        -f|--freelance)
            COM_FREELANCE=1
            shift
            ;;
        -i|--finance)
            COM_FIN_REPORTS=1
            shift
            ;;
        -t|--translation)
	    PACKAGES_DIR=packages-trans
	    PGDUMP=dump_5_0_translation_with_commercial_packages.sql.gz
            COM_TRANS_REPORTS=1
            shift
            ;;
        -p|--port)
            PGPORT=$2
            shift 2
            ;;
        -b|--branch)
            BRANCH=$2
            shift 2
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


# find the directory which contains the inital home tar and sql dump
tmp=`dirname $0`
SCRIPTDIR=`( cd $tmp; pwd )`

cat <<EOF

creating server for '$POUSER'
  dry-run     : $DRY
  password    : $POPASS
  home        : $HOMEDIR
  port        : $PGPORT
  freelance   : $COM_FREELANCE
  finance     : $COM_FIN_REPORTS
  translation : $COM_TRANS_REPORTS
  branch      : $BRANCH
  scriptdir   : $SCRIPTDIR
  pgdump      : $PGDUMP
  timestamp   : $TIMESTAMP
EOF

#
# sanity checks
#
if ! test -e $PGDUMP; then
    echo "pgdump $PGDUMP doesn't exist"
    exit
fi


echo ""
echo "##########################################################"
echo "# Create users / groups"
echo "##########################################################"
echo ""


HOMEDIR=/web/$POUSER

echo "- groupadd $POUSER"
echo "- useradd -m -g $POUSER -d $HOMEDIR $POUSER"
echo "- chown -R $POUSER:$POUSER $HOMEDIR"

if [ $DRY != 1 ] ; then
    groupadd $POUSER
    useradd -m -g $POUSER -d $HOMEDIR $POUSER
    # chown -R $POUSER:$POUSER $HOMEDIR
fi

# echo "- /bin/su --login $POUSER --command 'source  $HOMEDIR/.bash_profile'"
# /bin/su --login $POUSER --command "source  $HOMEDIR/.bash_profile"



# Check if the database exists and perform a backup
DB_EXISTS_P= `su - postgres -c "psql -lqt | cut -d \| -f 1 | grep $POUSER | wc -l"`
echo "- DB_EXISTS_P=$DB_EXISTS_P"
if [ $DB_EXISTS_P != 1 ] ; then

    echo ""
    echo "##########################################################"
    echo "# Dropping DB"
    echo "##########################################################"
    echo ""

    echo "- Creating a database backup - just in case..."
    echo "- /bin/su --login $POUSER --command 'pg_dump --no-owner --clean --disable-dollar-quoting --format=p --file=$HOMEDIR/pg_dump.$TIMESTAMP.sql'"
    /bin/su --login $POUSER --command "pg_dump --no-owner --clean --disable-dollar-quoting --format=p --file=$HOMEDIR/pg_dump.$TIMESTAMP.sql"
   
    echo "- Creating database backup - just in case..."
    echo "- dropping database $POUSER"
    echo "- dropdb $POUSER"
    dropdb $POUSER
fi



echo ""
echo "##########################################################"
echo "# creating db"
echo "##########################################################"

echo ""
echo "- /bin/su --login postgres --command "$PGDIR/createuser $POUSER""
echo "- /bin/su --login postgres --command '$PGDIR/createdb --owner $POUSER --encoding=utf8 $POUSER'"
echo "- /bin/su --login $POUSER --command 'zcat $PGDUMP | $PGDIR/psql --quiet --dbname $POUSER > $HOMEDIR/db-init.log 2>&1'"

if [ $DRY != 1 ] ; then
    /bin/su --login postgres --command "$PGDIR/createuser $POUSER"
    /bin/su --login postgres --command "$PGDIR/createdb --owner $POUSER --encoding=utf8 $POUSER"



    echo "- 
    /bin/su --login $POUSER --command "zcat $PGDUMP | $PGDIR/psql --quiet --dbname $POUSER > $HOMEDIR/db-init.log 2>&1 "
fi


echo ""
echo "##########################################################"
echo "# Replacing database parameters"
echo "##########################################################"
echo ""


echo "- Set /web/*"
echo "- Set Localhost"
echo "- Fix issues"

if [ $DRY != 1 ] ; then
    /bin/su --login $POUSER --command "$PGDIR/psql --quiet -c \"UPDATE apm_parameter_values SET attr_value=REPLACE(attr_value,'/web/projop/','/web/$POUSER/') WHERE attr_value LIKE '/web/%';\"";

    /bin/su --login $POUSER --command "$PGDIR/psql --quiet -c \"UPDATE apm_parameter_values SET attr_value='http://$POUSER.project-open.net' where parameter_id in (select parameter_id from apm_parameters where package_key = 'acs-kernel' and parameter_name = 'SystemURL');\"";

    /bin/su --login $POUSER --command "$PGDIR/psql --quiet -c \"update im_menus set (url, label, parent_menu_id) = ('/intranet-reporting/timesheet-productivity-calendar-view-workdays-simple.tcl', 'timesheet-productivity-calendar-view-workdays-simple', 25975) where menu_id = 30178;\"";
fi



echo ""
echo "##########################################################"
echo "# Create dir/files"
echo "##########################################################"

echo ""
echo "- unpacking home directory"
echo "- tar -zxf $HOMEDUMP -C $HOMEDIR"
echo ""
echo "- creating ~/packages"
echo "- mv $HOMEDIR/packages $HOMEDIR/packages.$TIMESTAMP"
echo "- ln -s /web/po51patches/$PACKAGES_DIR/ $HOMEDIR/packages"

if [ $DRY != 1 ] ; then
    tar -zxf $HOMEDUMP -C $HOMEDIR
    mv $HOMEDIR/packages $HOMEDIR/packages.$TIMESTAMP
    ln -s /web/po51patches/$PACKAGES_DIR/ $HOMEDIR/packages
fi


echo ""
echo "##########################################################"
echo "# Create config: NaviServer: ~/etc/config.tcl"
echo "##########################################################"
echo ""

echo "- sed 's/@POUSER@/$POUSER/g; s/@PGPORT@/$PGPORT/g;' < $CONFFILE > /web/$POUSER/etc/config.tcl"

if [ $DRY != 1 ] ; then
    sed "s/@POUSER@/$POUSER/g; s/@PGPORT@/$PGPORT/g;" < $CONFFILE > /web/$POUSER/etc/config.tcl
fi


echo ""
echo "##########################################################"
echo "# Creating config: NGINX: /etc/nginx/conf.d/$POUSER.conf"
echo "##########################################################"
echo ""

echo "- creating config in $NGINX_CONF_DIR/$POUSER.conf"
echo "- chmod 644 $NGINX_CONF_DIR/$POUSER.conf"
echo "- systemctl restart nginx"

if [ $DRY != 1 ] ; then
    cat > $NGINX_CONF_DIR/$POUSER.conf <<EOF
server {
    listen 80;
    listen 443 ssl;
    server_name ponet $POUSER.*;
    location / {
        proxy_pass           http://127.0.0.1:$PORT;
        proxy_set_header     X-Forwarded-For \$remote_addr;
        proxy_set_header     Host \$host;
        client_max_body_size 1024M;
    }
    ssl_certificate /etc/nginx/certificates/fullchain.pem;
    ssl_certificate_key /etc/nginx/certificates/privkey.pem;
    error_page    500 502 503 504 /err/50x.html;
    error_page    404             /err/404.html;
    location /err/ {
	root /etc/nginx/html;
    }
    rewrite_log on;
    # if (\$scheme != "https") { return 301 https://\$host\$request_uri; }
}
EOF
    systemctl restart nginx
fi

echo ""
echo "##########################################################"
echo "# Changing ownership of $HOMEDIR"
echo "##########################################################"
echo ""

echo "- changing home directory ownership"
echo "- chown -R $POUSER:$POUSER $HOMEDIR"

if [ $DRY != 1 ] ; then
    chown -R $POUSER:$POUSER $HOMEDIR
fi



echo ""
echo "##########################################################"
echo "# Enable and start service using systemctl"
echo "##########################################################"
echo ""

echo "- systemctl enable po@$POUSER"
echo "- systemctl start po@$POUSER"

if [ $DRY != 1 ] ; then
    systemctl enable po@$POUSER
    systemctl start po@$POUSER
fi


echo ""
echo "##########################################################"
echo "# Finished"
echo "##########################################################"
echo ""


exit 0

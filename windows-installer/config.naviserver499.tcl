######################################################################
#
# Config parameter for an OpenACS site using AOLserver/NaviServer.
#
# These default settings will only work in limited circumstances.
# Two servers with default settings cannot run on the same host
#
######################################################################

ns_log notice "nsd.tcl: starting to read config file..."

#---------------------------------------------------------------------
# change to 80 and 443 for production use
#
set httpport			8000
set httpsport			8443

# The hostname and address should be set to actual values.
# setting the address to 0.0.0.0 means aolserver listens on all interfaces
set hostname			localhost
set address			0.0.0.0

# Note: If port is privileged (usually < 1024), OpenACS must be
# started by root, and the run script must contain the flag
# '-b address:port' which matches the address and port
# as specified above.

set installdir			"c:/project-open"
set server			"projop"
set servername			"\]project-open\[ V5.0"

# Are we runnng behind a proxy?
set proxy_mode			false

# if debug is false, all debugging will be turned off
set debug			false
set dev				$debug


#---------------------------------------------------------------------
# Location of NaviServer
#
set homedir			"$installdir/usr/local/naviserver499"
set bindir			$homedir/bin
set serverroot			"$installdir/servers/$server"


#---------------------------------------------------------------------
# which database do you want? postgres is only option here.

set database			postgres
set db_name			$server
set db_host			localhost
set db_port			""
set db_user			$server


set max_file_upload_mb		20
set max_file_upload_min		5


#---------------------------------------------------------------------
# set environment variables HOME and LANG

set env(HOME)			$homedir
set env(LANG)			en_US.UTF-8

######################################################################
#
# End of instance-specific settings
#
# Nothing below this point need be changed in a default install.
#
######################################################################


#---------------------------------------------------------------------
#
# AOLserver's directories. Autoconfigurable.
#
#---------------------------------------------------------------------
# Where are your pages going to live ?
set pageroot			$serverroot/www
set directoryfile		"index.tcl index.adp index.html index.htm"
set logroot			$serverroot/log/

#---------------------------------------------------------------------
# Global server parameters
#---------------------------------------------------------------------
ns_section ns/parameters
    ns_param	home			$homedir
    ns_param	serverlog		$logroot/error.log
    ns_param	pidfile			$logroot/nsd.pid
    ns_param	logroll			on
    ns_param	logmaxbackup		10
    ns_param	maxbackup		10
    ns_param	debug			$debug
    ns_param	logdebug		$debug
    ns_param	logdev			$dev

    ns_param	mailhost		localhost

    # setting to Unicode by default
    # see http://dqd.com/~mayoff/encoding-doc.html

    # fraber 170315: Disabled, but not 100% sure...
    # ns_param	HackContentType		 1
    
    ns_param	DefaultCharset		utf-8
    ns_param	HttpOpenCharset		utf-8
    ns_param	OutputCharset		utf-8
    ns_param	URLCharset		utf-8

    # Running behind a proxy?
    ns_param	ReverseProxyMode	$proxy_mode

    # NaviServer needs a separate parameter for ns_mktemp
    ns_param	tmpdir			"$installdir/tmp"

#---------------------------------------------------------------------
# Thread library (nsthread) parameters
#---------------------------------------------------------------------
ns_section ns/threads
    ns_param	mutexmeter		true	;# measure lock contention
    # The per-thread stack size must be a multiple of 8k for AOLServer to run under MacOS X
    ns_param	stacksize		[expr {128 * 8192}]

#
# MIME types.
#
ns_section ns/mimetypes
    #  Note: AOLserver already has an exhaustive list of MIME types:
    #  see: /usr/local/src/aolserver-4.{version}/aolserver/nsd/mimetypes.c
    #  but in case something is missing you can add it here.
    ns_param	Default	 		*/*
    ns_param	NoExtension		*/*
    ns_param	.pcd			image/x-photo-cd
    ns_param	.prc			application/x-pilot
    ns_param	.xls			application/vnd.ms-excel
    ns_param	.doc			application/vnd.ms-word
    ns_param	.docm			application/vnd.ms-word.document.macroEnabled.12
    ns_param	.docx			application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ns_param	.dotm			application/vnd.ms-word.template.macroEnabled.12
    ns_param	.dotx			application/vnd.openxmlformats-officedocument.wordprocessingml.template
    ns_param	.potm			application/vnd.ms-powerpoint.template.macroEnabled.12
    ns_param	.potx			application/vnd.openxmlformats-officedocument.presentationml.template
    ns_param	.ppam			application/vnd.ms-powerpoint.addin.macroEnabled.12
    ns_param	.ppsm			application/vnd.ms-powerpoint.slideshow.macroEnabled.12
    ns_param	.ppsx			application/vnd.openxmlformats-officedocument.presentationml.slideshow
    ns_param	.pptm			application/vnd.ms-powerpoint.presentation.macroEnabled.12
    ns_param	.pptx			application/vnd.openxmlformats-officedocument.presentationml.presentation
    ns_param	.xlam			application/vnd.ms-excel.addin.macroEnabled.12
    ns_param	.xlsb			application/vnd.ms-excel.sheet.binary.macroEnabled.12
    ns_param	.xlsm			application/vnd.ms-excel.sheet.macroEnabled.12
    ns_param	.xlsx			application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    ns_param	.xltm			application/vnd.ms-excel.template.macroEnabled.12
    ns_param	.xltx			application/vnd.openxmlformats-officedocument.spreadsheetml.template



#---------------------------------------------------------------------
#
# Server-level configuration
#
#  There is only one server in AOLserver, but this is helpful when multiple
#  servers share the same configuration file.  This file assumes that only
#  one server is in use so it is set at the top in the "server" Tcl variable
#  Other host-specific values are set up above as Tcl variables, too.
#
#---------------------------------------------------------------------
ns_section ns/servers
    ns_param	$server			$servername

#
# Server parameters
#
ns_section ns/server/${server}
    ns_param	directoryfile		$directoryfile
    ns_param	pageroot		$pageroot
    ns_param	threadtimeout		120	;# Idle threads die at this rate
    ns_param	globalstats		false	;# Enable built-in statistics
    ns_param	urlstats		false	;# Enable URL statistics
    ns_param	maxurlstats		1000	;# Max number of URL's to do stats on
    # ns_param	maxdropped		0
    # ns_param	directoryadp		$pageroot/dirlist.adp ;# Choose one or the other
    # ns_param	directoryproc		_ns_dirlist	;#  ...but not both!
    # ns_param	directorylisting	fancy	;# Can be simple or fancy

    #
    # Scaling and Tuning Options
    #
    ns_param	maxconnections		100	;# Max connections to put on queue
    ns_param	maxthreads		10
    ns_param	minthreads		1
    ns_param	connsperthread		1000	;# 10000; number of conns handled before disposal
    ns_param	highwatermark		100     ;# 80; allow concurrent creates above this queue-is percentage
    						;# 100 means to disable concurrent creates

    #
    # Compress response character data: ns_return, ADP etc.
    #
    ns_param	compressenable		on	;# false, use "ns_conn compress" to override
    # ns_param	compresslevel		4	;# 4, 1-9 where 9 is high compression, high overhead
    # ns_param	compressminsize		512	;# Compress responses larger than this
    # ns_param	compresspreinit		true	;# false, if true then initialize and allocate buffers at startup


    #
    # Special HTTP pages
    #
    ns_param	NotFoundResponse	"/global/file-not-found.html"
    ns_param	ServerBusyResponse	"/global/busy.html"
    ns_param	ServerInternalErrorResponse "/global/error.html"

#---------------------------------------------------------------------
#
# ADP (AOLserver Dynamic Page) configuration
#
#---------------------------------------------------------------------

ns_section ns/server/${server}/adp
    ns_param	map			/*.adp	;# Extensions to parse as ADP's
    # ns_param	map			/*.html	;# Any extension can be mapped
    ns_param	enableexpire		false	;# Set "Expires: now" on all ADP's
    ns_param	enabledebug		$debug	;# Allow Tclpro debugging with "?debug"
    ns_param	defaultparser		fancy

ns_section ns/server/${server}/adp/parsers
    ns_param	fancy			".adp"

ns_section ns/server/${server}/redirects
    ns_param	403			"global/forbidden.html"
    ns_param	404			"global/file-not-found.html"
    ns_param	500			"/global/error.html"
    ns_param	503			"/global/busy.html"

#
# Tcl Configuration
#
ns_section ns/server/${server}/tcl
    ns_param	library	$serverroot/tcl
    ns_param	autoclose		on
    ns_param	debug			$debug

ns_section "ns/server/$server/fastpath"
    ns_param	serverdir		$homedir
    ns_param	pagedir			$pageroot
    #
    # Directory listing options
    #
    # ns_param	directoryfile		"index.adp index.tcl index.html index.htm"
    # ns_param	directoryadp		$pageroot/dirlist.adp ;# Choose one or the other
    # ns_param	directoryproc		_ns_dirlist           ;#  ...but not both!
    # ns_param	directorylisting	fancy                 ;# Can be simple or fancy
    #


#---------------------------------------------------------------------
#
# Rollout email support
#
# These procs help manage differing email behavior on 
# dev/staging/production.
#
#---------------------------------------------------------------------
ns_section ns/server/${server}/acs/acs-rollout-support

	# EmailDeliveryMode can be:
	#	 default:	Email messages are sent in the usual manner.
	#	 log:		Email messages are written to the server's error log.
	#	 redirect: Email messages are redirected to the addresses specified 
	#	by the EmailRedirectTo parameter.	If this list is absent 
	#	or empty, email messages are written to the server's error log.
	#	 filter:	 Email messages are sent to in the usual manner if the 
	#	recipient appears in the EmailAllow parameter, otherwise they 
	#	are logged.

#	ns_param	 EmailDeliveryMode 	redirect
#	ns_param	 EmailRedirectTo	somenerd@yourdomain.test, othernerd@yourdomain.test
#	ns_param	 EmailAllow		somenerd@yourdomain.test,othernerd@yourdomain.test


#---------------------------------------------------------------------
#
# WebDAV Support (optional, requires oacs-dav package to be installed
#
#---------------------------------------------------------------------
ns_section ns/server/${server}/tdav
    ns_param	propdir			$serverroot/data/dav/properties
    ns_param	lockdir			$serverroot/data/dav/locks
    ns_param	defaultlocktimeout	300

ns_section ns/server/${server}/tdav/shares
    ns_param	share1			"OpenACS"
    #ns_param	share2			"Share 2 description"

ns_section ns/server/${server}/tdav/share/share1
    ns_param	uri			"/dav/*"
    # all WebDAV options
    ns_param	options			"OPTIONS COPY GET PUT MOVE DELETE HEAD MKCOL POST PROPFIND PROPPATCH LOCK UNLOCK"

#ns_section ns/server/${server}/tdav/share/share2
    #ns_param	uri			"/share2/path/*"
    # read-only WebDAV options
    #ns_param	options			"OPTIONS COPY GET HEAD MKCOL POST PROPFIND PROPPATCH"


#---------------------------------------------------------------------
#
# Socket driver module (HTTP)  -- nssock
#
#---------------------------------------------------------------------
ns_section ns/server/${server}/module/nssock
    ns_param	timeout			120
    ns_param	address			$address
    ns_param	hostname		$hostname
    ns_param	port			$httpport
# setting maxinput higher than practical may leave the server vulnerable to resource DoS attacks
# see http://www.panoptic.com/wiki/aolserver/166
    ns_param	maxinput		[expr {$max_file_upload_mb * 1024 * 1024}] ;# Maximum File Size for uploads in bytes
    ns_param	maxpost			[expr {$max_file_upload_mb * 1024 * 1024}] ;# Maximum File Size for uploads in bytes
    ns_param	recvwait		[expr {$max_file_upload_min * 60}] ;# Maximum request time in minutes

# maxsock will limit the number of simultanously returned pages,
# regardless of what maxthreads is saying
    ns_param	maxsock		   100	;# 100 = default

# On Windows you need to set this parameter to define the number of
# connections as well (it seems).
    ns_param	backlog			5  ;# if < 1 == 5

# Optional params with defaults:
    ns_param	bufsize			16000
    ns_param	rcvbuf			0
    ns_param	sndbuf			0
    ns_param	socktimeout		30	;# if < 1 == 30
    ns_param	sendwait		30	;# if < 1 == socktimeout
    ns_param	recvwait		30	;# if < 1 == socktimeout
    ns_param	closewait		2	;# if < 0 == 2
    ns_param	keepwait		30	;# if < 0 == 30
    ns_param	readtimeoutlogging	false
    ns_param	serverrejectlogging	false
    ns_param	sockerrorlogging	false
    ns_param	sockshuterrorlogging	false

#---------------------------------------------------------------------
#
# Access log -- nslog
#
#---------------------------------------------------------------------

ns_section ns/server/${server}/module/nslog
    ns_param	file			$logroot/$server.log
    ns_param	rollfmt			%Y-%m-%d-%H:%M
    ns_param	logpartialtimes		true
    ns_param	checkforproxy		$proxy_mode

    #ns_param	debug			$debug
    #ns_param	dev			$dev
    #ns_param	enablehostnamelookup	false
    #ns_param	logcombined		true
    #ns_param	extendedheaders		COOKIE
    #ns_param	logrefer		false
    #ns_param	loguseragent		false
    #ns_param	logreqtime		true
    #ns_param	maxbackup		1000
    #ns_param	rollday			*
    #ns_param	rollhour		0
    #ns_param	rollonsignal		true
    #ns_param	rolllog			true


#---------------------------------------------------------------------
#
# PAM authentication
#
#---------------------------------------------------------------------
ns_section ns/server/${server}/module/nspam
    ns_param	PamDomain		"pam_domain"


#---------------------------------------------------------------------
#
# SSL
#
#---------------------------------------------------------------------
ns_section "ns/server/test/module/nsssl"
ns_param	port			$httpsport
ns_param	hostname		$hostname
ns_param	address			$address
ns_param	ciphers	"ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!RC4"
ns_param	protocols		"!SSLv2"
ns_param	certificate		$homedir/servers/$server/etc/server.pem
ns_param	verify			0
ns_param	writerthreads		2
ns_param	writersize		2048


#---------------------------------------------------------------------
#
# Database drivers
# The database driver is specified here.
# Make sure you have the driver compiled and put it in {aolserverdir}/bin
#
#---------------------------------------------------------------------
ns_section "ns/db/drivers"
    ns_param	postgres		$bindir/nsdbpg.dll  ;# Load PostgreSQL driver

ns_section "ns/db/driver/postgres"
    ns_param	pgbin			"c:/project-open/pgsql/bin"	    ;# Path for psql binary


# Database Pools: This is how AOLserver  ``talks'' to the RDBMS. You need
# three for OpenACS: main, log, subquery. Make sure to replace ``yourdb''
# and ``yourpassword'' with the actual values for your db name and the
# password for it, if needed.

ns_section ns/db/pools
    ns_param	pool1			"Pool 1"
    ns_param	pool2			"Pool 2"
    ns_param	pool3			"Pool 3"

ns_section ns/db/pool/pool1
    ns_param	maxidle			0
    ns_param	maxopen			0
    ns_param	connections		15
    ns_param	verbose			$debug
    ns_param	extendedtableinfo	true
    ns_param	logsqlerrors		$debug
    ns_param	driver			postgres
    ns_param	datasource		$db_host:$db_port:$db_name
    ns_param	user			$db_user
    ns_param	password		""

ns_section ns/db/pool/pool2
    ns_param	maxidle			0
    ns_param	maxopen			0
    ns_param	connections		5
    ns_param	verbose			$debug
    ns_param	extendedtableinfo	true
    ns_param	logsqlerrors		$debug
    ns_param	driver			postgres
    ns_param	datasource		$db_host:$db_port:$db_name
    ns_param	user			$db_user
    ns_param	password		""

ns_section ns/db/pool/pool3
    ns_param	maxidle			0
    ns_param	maxopen			0
    ns_param	connections		5
    ns_param	verbose			$debug
    ns_param	extendedtableinfo	true
    ns_param	logsqlerrors		$debug
    ns_param	driver			postgres
    ns_param	datasource		$db_host:$db_port:$db_name
    ns_param	user			$db_user
    ns_param	password		""

ns_section ns/server/${server}/db
    ns_param	pools			pool1,pool2,pool3
    ns_param	defaultpool		pool1


#---------------------------------------------------------------------
# which modules should be loaded?  Missing modules break the server, so
# don't uncomment modules unless they have been installed.
ns_section ns/server/${server}/modules
    ns_param	nssock			$bindir/nssock.dll
    ns_param	nslog			$bindir/nslog.dll
    ns_param	nsdb			$bindir/nsdb.dll
    # ns_param	nssha1			$bindir/nssha1.dll

    #---------------------------------------------------------------------
    # nsssl will fail unless the cert files are present as specified
    # later in this file, so it's disabled by default
    # ns_param	nsssl			$bindir/nsssl.dll

    # authorize-gateway package requires dqd_utils
    # ns_param	dqd_utils		dqd_utils[expr {int($tcl_version)}].so

    # Full Text Search
    #ns_param	nsfts			$bindir/nsfts.so

    # PAM authentication
    #ns_param	nspam			$bindir/nspam.so

    # LDAP authentication
    #ns_param	nsldap			$bindir/nsldap.so

    # These modules aren't used in standard OpenACS installs
    #ns_param	nsperm			$bindir/nsperm.so
    #ns_param	nscgi			$bindir/nscgi.so
    #ns_param	nsjava			$bindir/libnsjava.so
    #ns_param	nsrewrite		$bindir/nsrewrite.so


#
# nsproxy configuration
#

ns_section ns/server/${server}/module/nsproxy
	# ns_param	maxslaves          8
	# ns_param	sendtimeout        5000
	# ns_param	recvtimeout        5000
	# ns_param	waittimeout        1000
	# ns_param	idletimeout        300000


ns_log notice "nsd.tcl: using threadsafe tcl: [info exists tcl_platform(threaded)]"
ns_log notice "nsd.tcl: finished reading config file."

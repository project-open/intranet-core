# /packages/intranet-core/www/admin/pg_dump.tcl

ad_page_contract {
    Performs a PostgreSQL pg_dump command to backup
    all data to a .sql file
    @author frank.bergmann@project-open.com

    @param format pg_dump output format (p=plain_sql, c=custom or t=tar)
    @param user_id Only works together with auto_login
    @param auto_login Auto-login token as returned by /intranet/admin/auto-login.
    @param download_p indicates that the script should return the backup file directly.
           This is useful for remote backups.
} {
    { format "p" }
    { return_url "/intranet/admin/backup/index" }
    { disable_dollar_quoting "--disable-dollar-quoting" }
    { user_id:integer 0}
    { auto_login "" }
    { download_p 0}
    { gzip_p 0 }
}

# ------------------------------------------------------------
# Security: Either go with Auto-Login OR go with normal user
# ------------------------------------------------------------

if {0 == $user_id} {
    set user_id [auth::require_login]
}
set backup_prefix "pg_dump"


# Check if the auto-login token was correct
set valid_auto_login [im_valid_auto_login_p -check_user_requires_manual_login_p 0 -user_id $user_id -auto_login $auto_login]

set page_title "PostgreSQL Full Database Dump"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HH24MISS') from dual"]
set path [im_backup_path]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

# ------------------------------------------------------------
# determine file ending depending on format

switch $format {
    c { set filename_ending "pgdmp" }
    t { set filename_ending "tar" }
    p { set filename_ending "sql" }
    default { set filename_ending "default" }
}

set servername [ns_info server]
set hostname [ns_info hostname]

set filename "$backup_prefix.$hostname.$servername.$today.$filename_ending"


# ------------------------------------------------------------
# Return the page header.
#

if {!$download_p} {

    ad_return_top_of_page "[im_header]\n[im_navbar]"
    ns_write "<H1>$page_title</H1>\n"
    ns_write "<ul>\n"
    ns_write "<li>Path = $path\n"
    ns_write "<li>Filename = $filename\n"
    ns_write "<li>Preparing to perform a full PostgreSQL database backup to: 
          <br><tt>$path/$filename</tt></li>\n"

    ns_write "</ul>\n<ul>\n"

    # Prepare the path for the export
    #
    ns_write "<li>Checking if $path exists\n"
    if {![file isdirectory $path]} {
	if { [catch {
	    ns_write "<li>Creating directory $path:<br> <tt>/bin/mkdir $path</tt>\n"
	    ns_log Notice "file mkdir $path"
	    file mkdir $path
	} err_msg] } {
	    ns_write "<li>
		<font color=red>
			Error creating subfolder $path:<br>
			<pre>$err_msg\n</pre>
		</font>
		Using '/tmp' as a default
	    "
	    set path "/tmp"
	}
    } else {
	ns_write "<li>Already there: $path\n"
    }

    ns_write "</ul>\n<ul>\n"
    
    ns_write "<li>Checking if $path exists\n"
    if {![file isdirectory "$path"]} {
	if { [catch {
	    ns_write "<li>Creating directory $path:<br> <tt>/bin/mkdir $path/</tt>\n"
	    ns_log Notice "/bin/mkdir $path/"
	    file mkdir $path
	} err_msg] } {
	    ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\n</pre>"
	    return
	}
    } else {
	ns_write "<li>Already there: $path\n"
    }

    ns_write "</ul>\n<ul>\n"

}

# ------------------------------------------------------------
# Parameters
#
set dest_file "$path/$filename"
global tcl_platform
set platform [lindex $tcl_platform(platform) 0]

# Where are the PostgreSQL binaries located?
set pgbin [db_get_pgbin]
set pgbin_param [parameter::get_from_package_key -package_key "intranet-core" -parameter "PgPathUnix" -default ""]
if {"" != $pgbin_param} { set pgbin $pgbin_param }
set pgbin_last_char [string range $pgbin end end]
if {"" ne $pgbin && "/" ne $pgbin_last_char} { set pgbin "$pgbin/" }

# Do we need to use special connection parameters for PgDump?
set pg_host [parameter::get_from_package_key -package_key "intranet-core" -parameter "PgDumpHost" -default ""]
set pg_user [parameter::get_from_package_key -package_key "intranet-core" -parameter "PgDumpUser" -default ""]
set pg_port [parameter::get_from_package_key -package_key "intranet-core" -parameter "PgDumpPort" -default ""]
# set pg_pass [parameter::get_from_package_key -package_key "intranet-core" -parameter "PgDumpPass" -default ""]
set pg_db ""

if { [catch {
    ns_log Notice "/intranet/admin/pg_dump/pg_dump: writing report to $path"

    switch $platform {
	windows {
	    # Windows
	    if {"" eq $pg_host} { set pg_host "localhost" }
	    if {"" eq $pg_user} { set pg_user "projop" }
	    set pg_db "projop"
	    set cmd [list im_exec ${pgbin}pg_dump -i --no-owner --clean $disable_dollar_quoting --format=$format --file=$dest_file]
	}
	default {
	    # Probably Linux or some kind of Unix derivate
	    set cmd [list im_exec ${pgbin}pg_dump --no-owner --clean $disable_dollar_quoting --format=$format --file=$dest_file]
	}
    }

    if {"" ne $pg_port} { 
	lappend cmd "-p"
	lappend cmd $pg_port
    }
    
    if {"" ne $pg_host} { 
	lappend cmd "-h"
	lappend cmd $pg_host
    }

    if {"" ne $pg_user} { 
	lappend cmd "-U"
	lappend cmd $pg_user
    }

    if {"" ne $pg_db} { 
	lappend cmd $pg_db
    }


    if {!$download_p} {
	ns_write "<li>PosgreSQL dump command:<br>\n<tt>$cmd\n</tt>\n"
	ns_write "</ul>\n"
    }

    # Execute the command
    eval $cmd

    if {$gzip_p} {
	im_exec gzip $dest_file
	set dest_file "$dest_file.gz"
    }

} err_msg] } {
    ns_write "<p>Error writing report to file $path/$filename:<p>
    <br><pre>'$err_msg'\n</pre>"
    return
}

if {$download_p} {
    rp_serve_concrete_file $dest_file
    ad_script_abort
}

ns_write "<p>Finished.
<a href=$return_url>return to list</a>
</p>
"

ns_write [im_footer]

# /packages/intranet-core/www/admin/pg_dump.tcl

ad_page_contract {
    Performs a PostgreSQL pg_dump command to backup
    all data to a .sql file
} {
    { format "p" }
    { return_url "index" }
    { disable_dollar_quoting "--disable-dollar-quoting" }
}


set user_id [ad_maybe_redirect_for_registration]
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

set filename "pg_dump.$hostname.$servername.$today.$filename_ending"


# ------------------------------------------------------------
# Return the page header.
#

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
	ns_log Notice "/bin/mkdir $path"
	exec /bin/mkdir "$path"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\n</pre>"
	return
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
	exec /bin/mkdir "$path"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\n</pre>"
	return
    }
} else {
    ns_write "<li>Already there: $path\n"
}

ns_write "</ul>\n<ul>\n"


set pgbin [db_get_pgbin]
set dest_file "$path/$filename"

global tcl_platform
set platform [lindex $tcl_platform(platform) 0]

# get the PSQL PostgreSQL version
set psql_version "0.0.0"
set err_msg ""
catch {
    set psql_string [exec psql --version]
    regexp {([0-9])\.([0-9])\.([0-9])} $psql_string match psql_major psql_minor psql_pathc
} err_msg


# Disable "dollar quoting" on 7.4.x
if {"7" == $psql_major} { 
    # Disabling quoting - we can't just set it to "" because
    # otherwise pg_dump complains. So we use a double "--now-owner"...
    set disable_dollar_quoting "--no-owner" 
}


if { [catch {
    ns_log Notice "/intranet/admin/pg_dump/pg_dump: writing report to $path"

    switch $platform {
	windows {
	    # Windows CygWin default
	    ns_write "<li>Preparing to execute PosgreSQL dump command:<br>\n<tt>
	    exec ${pgbin}pg_dump projop -h localhost -U projop --no-owner --clean $disable_dollar_quoting --format=$format --file=$dest_file
                      </tt>\n"
	    ns_write "</ul>\n"

	    exec ${pgbin}pg_dump projop -h localhost -U projop --no-owner --clean $disable_dollar_quoting --format=$format --file=$dest_file
	}

	default {
	    # Probably Linux or some kind of Unix derivate
	    ns_write "<li>Preparing to execute PosgreSQL dump command:<br>\n<tt>
	    exec /usr/bin/pg_dump --no-owner --clean $disable_dollar_quoting --format=$format --file=$dest_file
                      </tt>\n"
	    ns_write "</ul>\n"

	    exec pg_dump --no-owner --clean $disable_dollar_quoting --format=$format --file=$dest_file
	}
    }

} err_msg] } {
    ns_write "<p>Error writing report to file $path/$filename:<p>
    <br><pre>'$err_msg'\n</pre>"
    return
}

ns_write "
<p>
Finished.

<a href=$return_url>return to list</a>
</p>
"

ns_write [im_footer]

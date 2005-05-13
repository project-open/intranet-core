# /packages/intranet-core/www/admin/pg_dump.tcl

ad_page_contract {
    Performs a PostgreSQL pg_dump command to backup
    all data to a .sql file
} {
    { return_url "index" }
}


set user_id [ad_maybe_redirect_for_registration]
set page_title "PostgreSQL Full Database Dump"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HHmmSS') from dual"]
set path [im_backup_path]
set filename "pg_dump.$today.sql"

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}


# ------------------------------------------------------------
# Return the page header.
#

ad_return_top_of_page "[im_header]\n[im_navbar]"
ns_write "<H1>$page_title</H1>\n"
ns_write "<ul>\n"
ns_write "<li>Path = $path/$today\n"
ns_write "<li>Filename = $filename\n"
ns_write "<li>Preparing to perform a full PostgreSQL database backup to: 
          <br><tt>$path/$today/$filename</tt></li>\n"

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

ns_write "<li>Checking if $path/$today exists\n"
if {![file isdirectory "$path/$today"]} {
    if { [catch {
	ns_write "<li>Creating directory $path/$today:<br> <tt>/bin/mkdir $path/$today/</tt>\n"
	ns_log Notice "/bin/mkdir $path/$today/"
	exec /bin/mkdir "$path/$today"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\n</pre>"
	return
    }
} else {
    ns_write "<li>Already there: $path/$today\n"
}

ns_write "</ul>\n<ul>\n"


set dest_file "$path/$today/$filename"
ns_write "<li>Preparing to execute PosgreSQL dump command:<br>\n<tt>/usr/bin/pg_dump -c -O -F p -f $dest_file</tt>\n"

ns_write "</ul>\n"

if { [catch {
    ns_log Notice "/intranet/admin/pg_dump/pg_dump: writing report to $path/$today"
	
    exec /usr/bin/pg_dump -c -O -F p -f $dest_file

} err_msg] } {
    ns_write "<p>Error writing report to file $path/$today/$filename:<p>
    <br><pre>'$err_msg'\n</pre>"
    return
}

ns_write "
<p>
Finished
</p>
"

ns_write [im_footer]


# /packages/intranet-core/www/admin/backup.tcl

ad_page_contract {
    Changes all clients, users, prices etc to allow
    to convert a productive system into a demo.
} {
    view:array
    { return_url "index" }
}


set user_id [ad_maybe_redirect_for_registration]
set page_title "Backup"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HHmm') from dual"]
set path [im_backup_path]

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
ns_write "<p>Exporting to path: <tt>$path/$today/</tt></p>\n"

set joined_ids [join [array names view] ","]

set sql "
select
	v.*
from 
	im_views v
where 
	v.view_id in ($joined_ids)
"

# Prepare the path for the export
#
if {![file isdirectory $path]} {
    if { [catch {
	ns_log Notice "/bin/mkdir $path"
	exec /bin/mkdir "$path"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\m</pre>"
	return
    }
}

append path "/$today/"
if {![file isdirectory $path]} {
    if { [catch {
	ns_log Notice "/bin/mkdir $path"
	exec /bin/mkdir "$path"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\m</pre>"
	return
    }
}

ns_write "<ul>\n"
ns_log Notice "backup-2: $sql"
db_foreach foreach_report $sql {
    ns_write "<li>Exporting $view_name ..."
    ns_log Notice "backup-2: im_backup_report $view_id"

    set report [im_backup_report $view_id]
    
    if { [catch {
	ns_log Notice "/intranet/admin/backup/backup: writing report to $path"
	
	set stream_name "$path$view_name.csv"
	set stream [open $stream_name w]
	puts $stream $report
	close $stream
	
    } err_msg] } {
	ad_return_complaint 1 "Error writing report to file $stream_name:<br><pre>$err_msg\m</pre>"
	return
    }
}

ns_write "
</ul>
Successfully finished
"

ns_write [im_footer]



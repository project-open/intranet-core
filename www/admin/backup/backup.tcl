# /packages/intranet-core/www/admin/backup.tcl

ad_page_contract {
    Changes all clients, users, prices etc to allow
    to convert a productive system into a demo.
} {
    { path "/tmp/" }
    { return_url "" }
}


set user_id [ad_maybe_redirect_for_registration]
set page_title "Backup"
set context_bar [ad_context_bar $page_title]
set page_body "<H1>$page_title</H1>"
set today [db_string today "select to_char(sysdate, 'YYYY-MM-DD') from dual"]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}


set sql "
select
	v.*
from 
	im_views v
where 
	view_id >= 100
	and view_id < 200
	and view_id in (152)
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

append path "$today/"
if {![file isdirectory $path]} {
    if { [catch {
	ns_log Notice "/bin/mkdir $path"
	exec /bin/mkdir "$path"
    } err_msg] } {
	ad_return_complaint 1 "Error creating subfolder $path:<br><pre>$err_msg\m</pre>"
	return
    }
}

append page_body "<ul>\n"
db_foreach foreach_report $sql {
    append page_body "<li>Exporting $view_name ..."
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

append page_body "
</ul>
Successfully finished
"


if {"" != $return_url} {
    ad_return_redirect $return_url
} else {
    doc_return  200 text/html [im_return_template]
}


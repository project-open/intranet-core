# /packages/intranet-core/www/admin/backup.tcl

ad_page_contract {
    Changes all clients, users, prices etc to allow
    to convert a productive system into a demo.
} {
    { path "/tmp/" }
    { return_url "" }
}


set user_id [ad_get_user_id]
set page_title "Backup"
set context_bar [ad_context_bar_ws $page_title]
set page_body "<H1>$page_title</H1>"

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
"

append page_body "<ul>\n"
db_foreach foreach_report $sql {
    append page_body "<li>Exporting $view_name ..."
    set report [im_backup_report $view_id]
    set stream [open /tmp/$view_name.csv w]
    puts $stream $report
    close $stream
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


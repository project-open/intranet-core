# /packages/intranet-core/www/admin/restore.tcl

ad_page_contract {
    Go through all know backup "reports" and try to
    load the corresponding backup file from the 
    specified directory.
} {
    path
    { return_url "" }
}


set user_id [ad_maybe_redirect_for_registration]
set page_title "Restore"
set context_bar [im_context_bar $page_title]
set context ""
set page_body "<H1>$page_title</H1>"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"
set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}


# get the list of all backups of business objects i
# in the backup set
#
set file_list [exec $find_cmd $path -type f]
foreach line $file_list {
    set files [split $line "/"]
    set last_file_idx [expr [llength $files] - 1]
    set file [lindex $files $last_file_idx]
    regexp {([^\.]*)\.[^\.]} $file ttt file_body

    set existant_files($file_body) $file_body
    ns_log Notice "backup/restore.tcl: found file: $file_body"
}

set sql "
select
        v.*
from
        im_views v
where
        v.view_type_id = [im_dynview_type_backup]
order by
	sort_order
"

set object_list_html ""
set ctr 0
db_foreach foreach_report $sql {
    append object_list_html "
      <tr $bgcolor([expr $ctr % 2])>
        <td>$view_id</td>
        <td>$view_name</td>
    "

    if {[info exists existant_files($view_name)]} {
	append object_list_html "
            <td>
              <input type=checkbox name=view.$view_id checked>
            </td>
        "
    } else {
	append object_list_html "
            <td>
            </td>
        "
    }

    append object_list_html "</tr>\n"
    incr ctr
}

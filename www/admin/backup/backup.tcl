# /packages/intranet-core/www/admin/backup.tcl

ad_page_contract {
    Changes all clients, users, prices etc to allow
    to convert a productive system into a demo.
} {
    { return_url "" }
}


set user_id [ad_maybe_redirect_for_registration]
set page_title "Backup"
set context_bar [im_context_bar $page_title]
set context ""
set page_body "<H1>$page_title</H1>"
set today [db_string today "select to_char(sysdate, 'YYYY-MM-DD') from dual"]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

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
	v.view_type_id = [im_dynview_type_backup]
order by
	v.view_id
"

set object_list_html ""
set ctr 0
db_foreach foreach_report $sql {
    append object_list_html "
      <tr $bgcolor([expr $ctr % 2])>
	<td>$view_id</td>
	<td>$view_name</td>
	<td>
	  <input type=checkbox name=view.$view_id checked>
	</td>
      </tr>
    "
    incr ctr
}

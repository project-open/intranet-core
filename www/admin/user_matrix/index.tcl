# /packages/subsite/www/admin/groups/index.tcl

ad_page_contract {

    Shows all groups on the left hand side with the management
    privileges of the groups on the top

    @author fraber@fraber.de
}


set context [list "Groups"]
set this_url [ad_conn url]
set package_id [ad_conn package_id]
set package_id 400

set group_url "/intranet/admin/user_matrix/group"

set group_list_sql {
select
	g.*
from
	groups g
where
	group_id >= 0
        and group_id < 500
order by
	lower(g.group_name)
}

set group_ids [list]
set group_names [list]
set table_header "<tr><td></td>\n"
set mail_sql_select ""
db_foreach group_list $group_list_sql {
	lappend group_ids $group_id
	lappend group_names $group_name
	append main_sql_select "\tacs_permission.permission_p(g.group_id, $group_id, 'read') as p${group_id}_read,\n"
	append table_header "<td><A href=$group_url?group_id=$group_id>$group_name</A></td>\n"
}
append table_header "</th>\n"

set main_sql "
select
	g.group_id,
${main_sql_select}	g.group_name
from
	groups g
where
        group_id >= 0
        and group_id < 500
order by
        lower(g.group_name)
"

set table "
<table>
$table_header
"



db_foreach group_matrix $main_sql {
    append table "
<tr>
  <td>
    <A href=$group_url?group_id=$group_id>$group_name</A>
  </td>
"

    foreach horiz_group_id $group_ids {
	set var "\$p${horiz_group_id}_read"
	append table "
  <td>
    [expr $var]
  </td>
"
    }
    
    append table "
</tr>
"
}
append table "</table>\n"

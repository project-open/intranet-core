# /packages/subsite/www/admin/groups/index.tcl
#
# Copyright (C) 2004 Project/Open
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {

    Shows all groups on the left hand side with the management
    privileges of the groups on the top

    @author frank.bergmann@project-open.com
}

set current_user_id [ad_maybe_redirect_for_registration]
set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$current_user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set user_id [ad_maybe_redirect_for_registration]
set context [list "Groups"]
set this_url [ad_conn url]
set package_id [ad_conn package_id]
set package_id 400

set group_url "/intranet/admin/user_matrix/group"
set toggle_url "/intranet/admin/user_matrix/toggle"

set group_list_sql {
select DISTINCT
        g.group_name,
        g.group_id
from
        acs_objects o,
        groups g,
        application_group_element_map app_group,
        all_object_party_privilege_map perm
where
        perm.object_id = g.group_id
        and perm.party_id = :user_id
        and perm.privilege = 'read'
        and g.group_id = o.object_id
        and o.object_type = 'im_profile'
        and app_group.package_id = :package_id
        and app_group.element_id = g.group_id
order by lower(g.group_name)
}


set group_ids [list]
set group_names [list]
set table_header "<tr><td></td>\n"
set mail_sql_select ""
db_foreach group_list $group_list_sql {
	lappend group_ids $group_id
	lappend group_names $group_name
	append main_sql_select "\tacs_permission.permission_p(g.group_id, $group_id, 'read') as p${group_id}_read_p,\n"
	append main_sql_select "\tacs_permission.permission_p(g.group_id, $group_id, 'view') as p${group_id}_view_p,\n"
	append main_sql_select "\tacs_permission.permission_p(g.group_id, $group_id, 'write') as p${group_id}_write_p,\n"
	append main_sql_select "\tacs_permission.permission_p(g.group_id, $group_id, 'admin') as p${group_id}_admin_p,\n"
	append table_header "<td><A href=$group_url?group_id=$group_id>$group_name</A></td>\n"
}
append table_header "</th>\n"

set main_sql_old "
select DISTINCT
        g.group_id,
${main_sql_select}	g.group_name
from
        acs_objects o,
        groups g,
        application_group_element_map app_group,
        all_object_party_privilege_map perm
where
        perm.object_id = g.group_id
        and perm.party_id = :user_id
        and perm.privilege = 'read'
        and g.group_id = o.object_id
        and o.object_type = 'im_profile'
        and app_group.package_id = :package_id
        and app_group.element_id = g.group_id
order by lower(g.group_name)
"

set main_sql "
select DISTINCT
        g.group_id,
${main_sql_select}	g.group_name
from
        acs_objects o,
        groups g
where
        g.group_id = o.object_id
        and o.object_type = 'im_profile'
order by lower(g.group_name)
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
	set read_p [expr "\$p${horiz_group_id}_read_p"]
	set read "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=add_readable>r</A>\n"
	if {$read_p == "t"} { 
	    set read "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=remove_readable><b>R</b></A>\n"
	}

	set view_p [expr "\$p${horiz_group_id}_view_p"]
	set view "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=add_viewable>v</A>\n"
	if {$view_p == "t"} { 
	    set view "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=remove_viewable><b>V</b></A>\n"
	}

	set write_p [expr "\$p${horiz_group_id}_write_p"]
	set write "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=add_writeable>w</A>\n"
	if {$write_p == "t"} { 
	    set write "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=remove_writeable><b>W</b></A>\n"
	}

	set admin_p [expr "\$p${horiz_group_id}_admin_p"]
	set admin "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=add_administratable>a</A>\n"
	if {$admin_p == "t"} { 
	    set admin "<A href=$toggle_url?horiz_group_id=$horiz_group_id&vert_group_id=$group_id&action=remove_administratable><B>A</b></A>\n"
	}

	append table "
  <td align=center>
    $view $read $write $admin
  </td>
"
    }
    
    append table "
</tr>
"
}
append table "</table>\n"

# /packages/intranet-core/www/admin/menus/index.tcl
#
# Copyright (C) 2004 Project/Open
# The code is based on ArsDigita ACS 3.4
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
    Show the permissions for all menus in the system

    @author frank.bergmann@project-open.com
} {
    { return_url "/intranet/admin/menus/index" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "Menu Permissions"
set context_bar [ad_context_bar $page_title]
set context ""

set menu_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/menus/toggle"
set group_url "/admin/groups/one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# ------------------------------------------------------
# Get the list of all relevant "Profiles"
# and generate the dynamic part of the SQL
# ------------------------------------------------------

set group_list_sql {
select DISTINCT
        g.group_name,
        g.group_id,
	p.profile_gif
from
        acs_objects o,
        groups g,
	im_profiles p
where
        g.group_id = o.object_id
	and g.group_id = p.profile_id
        and o.object_type = 'im_profile'
order by lower(g.group_name)
}


set group_ids [list]
set group_names [list]
set table_header "
<tr>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td width=20></td>
  <td class=rowtitle>Package</td>\n"

set main_sql_select ""
set num_profiles 0
db_foreach group_list $group_list_sql {
    lappend group_ids $group_id
    lappend group_names $group_name
    append main_sql_select "\tacs_permission.permission_p(m.menu_id, $group_id, 'read') as p${group_id}_read_p,\n"
    append table_header "
      <td class=rowtitle><A href=$group_url?group_id=$group_id>
      [im_gif $profile_gif $group_name]
    </A></td>\n"
    incr num_profiles
}
append table_header "
  <td class=rowtitle>[im_gif del "Delete Menu"]</td>
</tr>
"


# ------------------------------------------------------
# Main SQL: Extract the permissions for all Menus
# ------------------------------------------------------

set start_menu_id [db_string start_menu_id "select menu_id from im_menus where label='top'" -default 0]

set main_sql "
select
${main_sql_select}	m.*,
	level,
	(level-1) as indent_level,
	(6-level) as colspan_level
from
	im_menus m
start with
        menu_id = :start_menu_id
connect by
        parent_menu_id = PRIOR menu_id
"

# ad_return_complaint 1 "<li><pre>$main_sql</pre>"


set table "
<form action=menu-action method=post>
[export_form_vars return_url]
<table>
$table_header\n"

set ctr 0
set old_package_name ""
db_foreach menus $main_sql {
    incr ctr

    append table "\n<tr$bgcolor([expr $ctr % 2])>\n"

    if {0 != $indent_level} {
	append table "\n<td colspan=$indent_level>&nbsp;</td>"
    }

    append table "
  <td colspan=$colspan_level>
    <A href=$menu_url?menu_id=$menu_id>$name</A><br>$label
  </td>
  <td>$package_name</td>
"

    foreach horiz_group_id $group_ids {
        set read_p [expr "\$p${horiz_group_id}_read_p"]
        set read "<A href=$toggle_url?horiz_group_id=$horiz_group_id&object_id=$menu_id&action=add_readable>r</A>\n"
        if {$read_p == "t"} {
            set read "<A href=$toggle_url?horiz_group_id=$horiz_group_id&object_id=$menu_id&action=remove_readable><b>R</b></A>\n"
        }

        append table "
  <td align=center>
    $read
  </td>
"
    }

    append table "
  <td>
    <input type=checkbox name=menu_id.$menu_id>
  </td>
</tr>
"
}

append table "
<tr>
  <td colspan=[expr $num_profiles + 5]>&nbsp;</td>
  <td>
    <input type=submit value='Del'>
  </td>
</tr>
</table>
</form>
"

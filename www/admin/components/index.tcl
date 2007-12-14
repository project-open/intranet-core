# /packages/intranet-core/www/admin/components/index.tcl
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
  Home page for component administration.

  @author alwin.egger@gmx.net
  @author frank.bergmann@project-open.com
} {
    { return_url ""}
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

set page_title "Components"
set context_bar [im_context_bar $page_title]
set context ""

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

if {"" == $return_url} { set return_url [ad_conn url] }

set component_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"



# ------------------------------------------------------
# List of available groups
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
}

set group_ids [list]
set group_names [list]
set table_header "
<tr>
  <td class=rowtitle>Component</td>
  <td class=rowtitle>Package</td>
  <td class=rowtitle>Enable</td>
  <td class=rowtitle>Pos</td>
  <td class=rowtitle>URL</td>
"

set main_sql_select ""
set num_profiles 0
db_foreach group_list $group_list_sql {
    lappend group_ids $group_id
    lappend group_names $group_name
    append main_sql_select "\tim_object_permission_p(c.plugin_id, $group_id, 'read') as p${group_id}_read_p,\n"
    append table_header "
      <td class=rowtitle><A href=$group_url?group_id=$group_id>
      [im_gif $profile_gif $group_name]
    </A></td>\n"
    incr num_profiles
}
append table_header "\n</tr>\n"


# ------------------------------------------------------
# Main SQL
# ------------------------------------------------------

# Generate the sql query
set criteria [list]
set bind_vars [ns_set create]

set component_select_sql "
select
	${main_sql_select}
	c.plugin_id, 
	c.plugin_name, 
	c.package_name, 
	c.location, 
	c.page_url,
	c.enabled_p
from 
	im_component_plugins c
order by
	package_name,
	plugin_name
"

set ctr 1
set table ""
db_foreach all_component_of_type $component_select_sql {

    append table "
<tr $bgcolor([expr $ctr % 2])>
  <td>
    <a href=\"edit.tcl?[export_url_vars plugin_id]\">
      $plugin_name
    </a>
  </td>
  <td>$package_name</td>
  <td>$enabled_p</td>
  <td>$location</td>
  <td>$page_url</td>
"
    foreach horiz_group_id $group_ids {
        set read_p [expr "\$p${horiz_group_id}_read_p"]
	set object_id $plugin_id
	set action "add_readable"
	set letter "r"
        if {$read_p == "t"} {
            set read "<A href=$toggle_url?object_id=$plugin_id&action=remove_readable&[export_url_vars horiz_group_id return_url]><b>R</b></A>\n"
	    set action "remove_readable"
	    set letter "<b>R</b>"
        }
	set read "<A href=$toggle_url?[export_url_vars horiz_group_id object_id action return_url]>$letter</A>\n"

        append table "
  <td align=center>
    $read
  </td>\n"
    }

    append table "\n</tr>\n"
    incr ctr
}

append table "
</table>
</form>
"

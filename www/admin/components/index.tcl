# /packages/intranet-core/www/admin/components/index.tcl
#
# Copyright (C) 2004 ]project-open[
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
    { package_key_form "none"}
    { component_location ""}
    { component_page ""}
    { plugin_id ""}
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

set return_url [im_url_with_query]

set current_url [im_url_with_query]
set component_url "/intranet/admin/menus/new"
set toggle_url "/intranet/admin/toggle"
set group_url "/admin/groups/one"

# ------------------------------------------------------
# Options for Package Select
# ------------------------------------------------------

set package_options [db_list_of_lists package_options "
	select	package_key as pack_key, 
		package_key as pack_key2
	from	apm_packages
	order by package_key
"]
set package_options [linsert $package_options 0 [list "All" ""]]


set location_options [db_list_of_lists location_options "
	select	distinct location, location
	from	im_component_plugins
	order by location
"]
set location_options [linsert $location_options 0 [list "All" ""]]


set page_options [db_list_of_lists page_options "
	select	distinct page_url, page_url
	from	im_component_plugins
	order by page_url
"]
set page_options [linsert $page_options 0 [list "All" ""]]


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
  <td class=rowtitle>En</td>
  <td class=rowtitle>Package</td>
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

set component_where ""




if {"none" != $package_key_form && "" != $package_key_form} { append component_where "\t and package_name = :package_key_form \n" }

if {"" != $component_location} { append component_where "\tand location = :component_location\n" }
if {"" != $plugin_id} { append component_where "\tand plugin_id = :plugin_id\n" }
if {"" != $component_page} { 
    set component_page [ns_urldecode $component_page]
    append component_where "\tand page_url = :component_page\n" 
}

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
	where	
		1=1
		$component_where
	order by
		package_name,
		plugin_name
"

#ad_return_complaint 1 $component_select_sql

set ctr 1
set table ""
db_foreach all_component_of_type $component_select_sql {

    if {"t" == $enabled_p} { 
	set enabled_html "<b><font>$enabled_p</font></b>"
    } else {
	set enabled_html "<b><font color=red>$enabled_p</font></b>"
    }

    append table "
<tr $bgcolor([expr $ctr % 2])>
  <td>
    <nobr><a href=\"[export_vars -base "edit" {{return_url $current_url} plugin_id}]\">$plugin_name</a></nobr>
  </td>
  <td><a href=[export_vars -base "/intranet/admin/toggle-enabled" {plugin_id return_url}]>$enabled_html</a></td>
  <td>$package_name</td>
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

# ------------------------------------------------------
# Filters & Navbar
# ------------------------------------------------------

if { "" == $package_key_form } { set package_key_form "All" }
set package_select [im_select -ad_form_option_list_style_p 1 package_key_form $package_options $package_key_form]

set left_navbar_html "
	<table>
	<form action=index method=GET>
	<tr>
	<td>[lang::message::lookup "" intranet-core.Package "Package"]</td>
	<td>$package_select</td>
	</tr>

	<tr>
	<td>[lang::message::lookup "" intranet-core.Location "Location"]</td>
	<td>[im_select -translate_p 0 -ad_form_option_list_style_p 1 component_location $location_options $component_location]</td>
	</tr>

	<tr>
	<td>[lang::message::lookup "" intranet-core.Component_Page "Page"]</td>
	<td>[im_select -translate_p 0 -ad_form_option_list_style_p 1 component_page $page_options $component_page]</td>
	</tr>

	<tr><td></td><td><input type=submit></td></tr>
	</form>
	</table>
"

set left_navbar_html "
        <div class='filter-block'>
                <div class='filter-title'>
	           [lang::message::lookup "" intranet-core.Filter_Components "Filter Components"]
                </div>
                $left_navbar_html
        </div>
      <hr/>
"
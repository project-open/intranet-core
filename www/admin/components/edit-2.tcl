# /packages/intranet-core/www/admin/components/edit-2.tcl
#
# Copyright (C) 1998-2004 various parties
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

  Saves changes in given component-plugin.

  @param plugin_id            ID of plugin to change
  @param location             location of the plugin (can be either left, right, bottom or none (invisible))

  @author sskracic@arsdigita.com
  @author michael@yoon.org
  @author frank.bergmann@project-open.com
  @author mai-bee@gmx.net
} {
    plugin_id:naturalnum
    {plugin_name:trim ""}
    {sort_order:integer ""}
    {location ""}
    {page_url:trim ""}
    {title_tcl:allhtml ""}
    {component_tcl:allhtml ""}
    {enabled_p ""}
    {action "none"}
    {return_url ""}
    {menu_name ""}
    {menu_sort_order 0}
    {submit "Update"}
}


set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}


switch $submit {
    "Update" {
	set updates [list]
	if {"" != $plugin_name} { lappend updates "plugin_name = :plugin_name" }
	if {"" != $page_url} { lappend updates "page_url = :page_url" }
	if {"" != $title_tcl} { lappend updates "title_tcl = :title_tcl" }
	if {"" != $component_tcl} { lappend updates "component_tcl = :component_tcl" }
	if {"" != $location} { lappend updates "location = :location" }
	if {"" != $sort_order} { lappend updates "sort_order = :sort_order" }
	if {"" != $menu_name} { lappend updates "menu_name = :menu_name" }
	if {"" != $menu_sort_order} { lappend updates "menu_sort_order = :menu_sort_order" }
	if {"" != $enabled_p} { lappend updates "enabled_p = :enabled_p" }
	
	if {[llength $updates] > 0} {
	    if [catch {
		db_dml update_category_properties "
		UPDATE	im_component_plugins
		SET	[join $updates ",\n\t"]
		WHERE	plugin_id = :plugin_id"
	    } errmsg ] {
		ad_return_complaint "Argument Error" "<pre>$errmsg</pre>"
		return
	    }
	}

	# Delete entries from user_map that might change the location
	db_dml del_user_map "delete from im_component_plugin_user_map where plugin_id = :plugin_id"

    }
    "Delete" {

	# Delete entries from user_map that might change the location
	db_dml del_user_map "delete from im_component_plugin_user_map where plugin_id = :plugin_id"

	db_string delete_component "
		select im_component_plugin__delete(:plugin_id::integer)
	"
    }
    default {
	ad_return_complaint 1 "<b>Unknown Operations '$submit'</b><br>"
	ad_script_abort
    }
}


# Remove all cached values
# ToDo: Replace to remove only info on portlet components
im_permission_flush


db_release_unused_handles

if {"" != $return_url} {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index"
}


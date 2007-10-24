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
    {sort_order:integer ""}
    {location ""}
    {page_url:trim ""}
    {title_tcl:allhtml ""}
    {component_tcl:allhtml ""}
    {action "none"}
    {return_url ""}
    {menu_name ""}
    {menu_sort_order 0}
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

set updates [list]
if {"" != $page_url} { lappend updates "page_url = :page_url" }
if {"" != $title_tcl} { lappend updates "title_tcl = :title_tcl" }
if {"" != $component_tcl} { lappend updates "component_tcl = :component_tcl" }
if {"" != $location} { lappend updates "location = :location" }
if {"" != $sort_order} { lappend updates "sort_order = :sort_order" }
if {"" != $menu_name} { lappend updates "menu_name = :menu_name" }
if {"" != $menu_sort_order} { lappend updates "menu_sort_order = :menu_sort_order" }

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


db_release_unused_handles

if {"" != $return_url} {
    ad_returnredirect "$return_url"
} else {
    ad_returnredirect "index"
}

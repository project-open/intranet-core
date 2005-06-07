# /packages/intranet-core/www/admin/categories/category-add-2.tcl
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
    plugin_id:naturalnum,notnull
    sort_order:naturalnum,notnull
    location:notnull
    url:trim
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

set exception_count 0
set exception_text ""

if {![info exists plugin_id] || [empty_string_p $plugin_id]} {
    incr exception_count
    append exception_text "<li>Plugin_ID is somehow missing.  This is probably a bug in our software."
}

if {![info exists sort_order] || [empty_string_p $sort_order]} {
    incr exception_count
    append exception_text "<li>sort_order is somehow missing.  This is probably a bug in our software."
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

if [catch {

   db_dml update_category_properties "
UPDATE
        im_component_plugins
SET
        location = :location,
        sort_order = :sort_order,
	page_url = :url
WHERE
        plugin_id = :plugin_id"
} errmsg ] {
    ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return

}

db_release_unused_handles

if { [info exists return_url] } {
    ad_returnredirect "$return_url"
} else {
    ad_returnredirect "index"
}
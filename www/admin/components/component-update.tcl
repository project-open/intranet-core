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
    plugin_id:naturalnum
    {sort_order:integer ""}
    {location ""}
    {page_url:trim ""}
    {title_tcl:allhtml ""}
    {component_tcl:allhtml ""}
    {action "none"}
    {return_url ""}
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

# Get everything about the component
db_1row comp_info "
	select * 
	from im_component_plugins 
	where plugin_id=:plugin_id
"


# Check if there are several components with the same sort_order
# as the current one
set same_comps [db_list same_comps "
	select	plugin_id 
	from	im_component_plugins
	where	page_url = :page_url
		and location = :location
		and sort_order = :sort_order
		and plugin_id != :plugin_id
"]

if {[llength $same_comps] > 0} {

    # Update the components and add random values to their
    # sort order

    foreach pid $same_comps {
	# Generate a random number between -10 and +10
	set r [expr [ns_rand 20] - 10]
	
	db_dml rand_update "
		update im_component_plugins 
		set sort_order = sort_order + :r 
		where plugin_id = :pid
	"
    }
}


# Get everything about the current plugin
db_1row component_info "
	select	p.*
	from	im_component_plugins p
	where	plugin_id = :plugin_id
"

switch $action {
    down { 
	# get the next component further down
	set above_sort_order [db_string above "
		select	min(sort_order)
		from	im_component_plugins
		where	page_url = :page_url
			and location = :location
			and sort_order > :sort_order
	" -default ""]

	if {"" != $above_sort_order} {

	    # Get the ID of the component above
	    set above_ids [db_list above_list "
		select	plugin_id
		from	im_component_plugins
		where	page_url = :page_url
			and location = :location
			and sort_order = :above_sort_order
	    "]
	    set above_plugin_id [lindex $above_ids 0]

	    # Exchange the sort orders
	    db_dml update "
		update im_component_plugins 
		set sort_order=:above_sort_order 
		where plugin_id = :plugin_id
	    "
	    db_dml update "
		update im_component_plugins 
		set sort_order=:sort_order 
		where plugin_id = :above_plugin_id
	    "
	}
    }
    up { 
	# get the next component further up
	set below_sort_order [db_string below "
		select	max(sort_order)
		from	im_component_plugins
		where	page_url = :page_url
			and location = :location
			and sort_order < :sort_order
	" -default ""]

	if {"" != $below_sort_order} {

	    # Get the ID of the component below
	    set below_ids [db_list below_list "
		select	plugin_id
		from	im_component_plugins
		where	page_url = :page_url
			and location = :location
			and sort_order = :below_sort_order
	    "]
	    set below_plugin_id [lindex $below_ids 0]

	    # Exchange the sort orders
	    db_dml update "
		update im_component_plugins 
		set sort_order=:below_sort_order 
		where plugin_id = :plugin_id
	    "
	    db_dml update "
		update im_component_plugins 
		set sort_order=:sort_order 
		where plugin_id = :below_plugin_id
	    "
	}
    }
    left {
	db_dml left "update im_component_plugins set location='left' where plugin_id=:plugin_id"
    }
    right { 
	db_dml left "update im_component_plugins set location='right' where plugin_id=:plugin_id"
    }
}


db_release_unused_handles

if {"" != $return_url} {
    ad_returnredirect "$return_url"
} else {
    ad_returnredirect "index"
}

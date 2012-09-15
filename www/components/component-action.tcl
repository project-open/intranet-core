# /packages/intranet-core/www/admin/components/component-action.tcl
#
# Copyright (C) 2006 ]project-open[
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

    Implements component actions such as open/close
    and movements in directions up, down, left and right.

    @param plugin_id            ID of plugin to change
    @author frank.bergmann@project-open.com
} {
    plugin_id:naturalnum
    { page_url "" }
    action
    return_url
}

# -----------------------------------------------------------
#
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

# Flush the cache for the navigation bar for all users...
util_memoize_flush_regexp "db_list_of_lists navbar_components.*"


switch $action {
    reset {
	# Delete all specific settings for the given user and 
	# the give page.
	db_dml reset "
		delete from im_component_plugin_user_map
		where	user_id = :user_id
			and plugin_id in (
				select	plugin_id
				from	im_component_plugins
				where	page_url = :page_url
			)
	"

	# Special functionality on ProjectViewPage: Delete MS-Project Warning ignores
	if {"/intranet/projects/view" == $page_url && [db_table_exists im_gantt_ms_project_warning]} {
	    db_dml del_ms_project_warnings "
		delete from im_gantt_ms_project_warning
		where user_id = [ad_get_user_id]
	    "
	}

	ad_returnredirect "$return_url"
	ad_script_abort
    }
}


# -----------------------------------------------------------
# Make sure there are no components with the same sort-order
# -----------------------------------------------------------

# This is a situation that can occur due to wrong package
# setup. We just add random values to duplicate components,
# so that it will even out...

# Get everything about the component
db_1row component_info "
        select	*
	from	im_component_plugins
	where	plugin_id = :plugin_id
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
    # Update the components and add random values to their sort order
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


# -----------------------------------------------------------
# Create a copy into im_component_plugin_user_map if !Admin
# -----------------------------------------------------------

# Check if there are already values for the user


set map_count [db_string map_count "
	select	count(*) 
	from	im_component_plugin_user_map 
	where	user_id = :user_id
		and plugin_id in (
			select plugin_id
			from im_component_plugins
			where page_url = :page_url
		)
"]


if {0 == $map_count} {
    db_dml copy_map "
	insert into im_component_plugin_user_map 
	(plugin_id, user_id, sort_order, location)
	select	plugin_id, :user_id as user_id,
		sort_order, location
	from	im_component_plugins
	where	page_url = :page_url
    "
}


# Intentions not clear for above measures 
# Does not always create record in im_component_plugin_user_map
# so that actions are ignored. Following code will:  

set map_count [db_string map_count "
        select  count(*)
        from    im_component_plugin_user_map
        where   user_id = :user_id
                and plugin_id = :plugin_id
"]

if {0 == $map_count} {
    db_dml copy_map "
        insert into im_component_plugin_user_map
        (plugin_id, user_id, sort_order, location)
        select  plugin_id, :user_id as user_id,
                sort_order, location
        from    im_component_plugins
        where   plugin_id = :plugin_id
    "
}

# -----------------------------------------------------------
# Component sepecific Action!
# -----------------------------------------------------------

# We can be sure that we're working on a copy of the 
# components in the "user_map".

# Get everything about the current plugin
db_1row component_info "
        select
                c.plugin_id,
                c.plugin_name,
                c.component_tcl,
                c.title_tcl,
		c.page_url,
                coalesce(m.sort_order, c.sort_order) as sort_order,
                coalesce(m.location, c.location) as location
        from
                im_component_plugins c
                left outer join (
                        select  *
                        from    im_component_plugin_user_map
                        where   user_id = :user_id
                ) m on (c.plugin_id = m.plugin_id)
        where
                c.plugin_id = :plugin_id
"

switch $action {
    down {
	# get the "sort_order" (=position) of the next 
	# below the current one
	set below_sort_order [db_string below "
		select	min(m.sort_order)
		from	im_component_plugin_user_map m,
			im_component_plugins p
		where	m.plugin_id = p.plugin_id
			and m.user_id = :user_id
			and p.page_url = :page_url
			and m.location = :location
			and m.sort_order > :sort_order
	" -default ""]

	if {"" != $below_sort_order} {

	    # IF there is an element below the current one: 
	    # Get the ID of the component below
	    set below_ids [db_list below_list "
		select	m.plugin_id
		from	im_component_plugin_user_map m,
			im_component_plugins c
		where	m.plugin_id = c.plugin_id
			and m.user_id = :user_id
			and c.page_url = :page_url
			and m.location = :location
			and m.sort_order = :below_sort_order
	    "]
	    set below_plugin_id [lindex $below_ids 0]

	    # Exchange the sort orders of the user_map table
	    db_dml update "
			update	im_component_plugin_user_map 
			set	sort_order = :below_sort_order 
			where	plugin_id = :plugin_id
				and user_id = :user_id
	    "
	    db_dml update "
			update	im_component_plugin_user_map
			set	sort_order = :sort_order 
			where	plugin_id = :below_plugin_id
				and user_id = :user_id
	    "
	} else {

	    # Didn't find any element below the current one:
	    # Check if this is either "left" or "right" and 
	    # move the component to "bottom".

	    if {"left" == $location || "right" == $location} {

		# move to "bottom"
		db_dml send_to_bottom "
			update	im_component_plugin_user_map 
			set	location = 'bottom'
			where	plugin_id = :plugin_id
				and user_id = :user_id
		"
	    }
	}
    }
    up {
	# Get the next "sort_order" (=position) of the next
	# component further up
	set above_sort_order [db_string above "
		select	max(m.sort_order)
		from	im_component_plugin_user_map m,
			im_component_plugins p
		where	m.plugin_id = p.plugin_id
			and m.user_id = :user_id
			and p.page_url = :page_url
			and m.location = :location
			and m.sort_order < :sort_order
	" -default ""]

	if {"" != $above_sort_order} {
	    # Get the ID of the component above
	    set above_ids [db_list above_list "
		select	m.plugin_id
		from	im_component_plugin_user_map m,
			im_component_plugins c
		where	m.plugin_id = c.plugin_id
			and m.user_id = :user_id
			and c.page_url = :page_url
			and m.location = :location
			and m.sort_order = :above_sort_order
	    "]
	    set above_plugin_id [lindex $above_ids 0]

	    # Exchange the sort orders of the user_map
	    db_dml update "
			update	im_component_plugin_user_map
			set	sort_order = :above_sort_order 
			where	plugin_id = :plugin_id
				and user_id = :user_id
	    "
	    db_dml update "
			update	im_component_plugin_user_map
			set	sort_order = :sort_order 
			where	plugin_id = :above_plugin_id
				and user_id = :user_id
	    "
	} else {

	    # Didn't find any element above the current one:
	    # Check if this is "bottom" and move the component 
	    # to the "top".

	    if {"bottom" == $location} {

		# move to "right"
		db_dml send_to_right "
			update	im_component_plugin_user_map 
			set	location = 'right'
			where	plugin_id = :plugin_id
				and user_id = :user_id
		"
	    }
	}
    }
    left {
	db_dml left "
		update	im_component_plugin_user_map
		set	location='left'
		where	plugin_id = :plugin_id
			and user_id = :user_id
	"
    }
    right { 
	db_dml right "
		update	im_component_plugin_user_map
		set	location='right' 
		where	plugin_id = :plugin_id
			and user_id = :user_id
	"
    }
    minimize { 
	db_dml minimize "
		update	im_component_plugin_user_map
		set	minimized_p = 't'
		where	plugin_id = :plugin_id
			and user_id = :user_id
	"
    }
    normal { 
	db_dml minimize "
		update	im_component_plugin_user_map
		set	minimized_p = 'f'
		where	plugin_id = :plugin_id
			and user_id = :user_id
	"
    }
    close { 
	db_dml close "
		update	im_component_plugin_user_map
		set	location = 'none'
		where	plugin_id = :plugin_id
			and user_id = :user_id
	"
    }
}


ad_returnredirect "$return_url"

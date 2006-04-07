# /packages/intranet-core/tcl/intranet-component-procs.tcl
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

ad_library {
    Procedures to deal with "Plug-ins" and "Component Bays":
    "Component Bays" are places in ADP-files that contain
    calls like: im_component_bay("right") to check if there
    is are plug-ins that should be displayed in this place.

    @author frank.bergmann@project-open.com
}



ad_proc -public im_component_any_perms_set_p { } {
    Checks if any permissions at all are set 
    for the components (this is usually not the case...
} {

    set any_perms_set_p [util_memoize "db_string any_perms_set {
        select  count(*)
        from    acs_permissions ap,
                im_profiles p,
                im_component_plugins cp
        where
                ap.object_id = cp.plugin_id
                and ap.grantee_id = p.profile_id
    }"]
    return $any_perms_set_p
}

ad_proc -public im_component_bay { location {view_name ""} } {
    Checks the database for Plug-ins for this page and component
    bay.
} {
    # Get the ID of the current page
    set full_url [ns_conn url]
    set user_id [ad_get_user_id]

    # Add an "index" to the url_stub if it ends with a "/".
    # This way we simulate the brwoser behavious of showing
    # the index file when entering a directory URL.
    if {[regexp {.*\/$} $full_url]} {
	append full_url "index"
    }

    ns_log Notice "full_url=$full_url"

    # Remove the trailing ".tcl" if present by only accepting 
    # characters until a "." appears
    # This asumes that there is no "." in the main url!
    regexp {([^\.]*)} $full_url url_stub
    ns_log Notice "url_stub=$url_stub"

    # get the list of plugins for this page
    #no util_memoize yet while we are developing...
    #set plugin-list [util_memoize "im_component_page_plugins $url_stub"]

    # Check if there is atleast one permission set for im_plugin_components
    set any_perms_set_p [db_string any_perms_set "
	select	count(*) 
	from	acs_permissions ap, 
		im_profiles p, 
		im_component_plugins cp 
	where 
		ap.object_id = cp.plugin_id 
		and ap.grantee_id = p.profile_id
    "]

    set plugin_sql "
select
	c.*,
	im_object_permission_p(c.plugin_id, :user_id, 'read') as perm
from
	im_component_plugins c
where
	page_url=:url_stub
	and location=:location
	and (view_name is null or view_name = :view_name)
order by sort_order
"

    set html ""
    db_foreach get_plugins $plugin_sql {

	if {$any_perms_set_p > 0} {
	    if {"f" == $perm} {	continue }
	}

	ns_log Notice "im_component_bay: component_tcl=$component_tcl"
	    append html [uplevel 1 $component_tcl]
	if { [catch {
	    # "uplevel" evaluates the 2nd argument!!
	} err_msg] } {
	    set html "<table>\n<tr><td><pre>$err_msg</pre></td></tr></table>\n"
	    set html [im_table_with_title $plugin_name $html]

#	    ad_return_complaint 1 "<li>
#        Error evaluating component '$plugin_name' of module '$package_name':<br>
#        <pre>\n$err_msg\n</pre><br>
#        Please contact your system administrator:<br>"
	}
    }
    return $html
}


ad_proc -public im_component_insert { plugin_name } {
    Insert a particular component.
    Returns "" if the component doesn't exist.
} {
    set plugin_sql "
select
	c.*
from
	im_component_plugins c
where
	plugin_name=:plugin_name
order by sort_order
"

    set html ""
    db_foreach get_plugins $plugin_sql {
	if { [catch {
	    # "uplevel" evaluates the 2nd argument!!
	    append html [uplevel 1 $component_tcl]
	} err_msg] } {
	    ad_return_complaint 1 "<li>
        [_ intranet-core.lt_Error_evaluating_comp]:<br>
        <pre>\n$err_msg\n</pre><br>
        [_ intranet-core.lt_Please_contact_your_s]:<br>"
	}
    }
    return $html
}

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

ad_proc -public im_component_page_url { } {
    Returns the "page_url" of the current page in a normalized form
} {
    # Get the full URL of the current page
    set full_url [ns_conn url]

    # Add an "index" to the url_stub if it ends with a "/".
    # This way we simulate the brwoser behavious of showing
    # the index file when entering a directory URL.
    if {[regexp {.*\/$} $full_url]} {
	append full_url "index"
    }

    # Remove the trailing ".tcl" if present by only accepting 
    # characters until a "." appears
    # This asumes that there is no "." in the main url!
    regexp {([^\.]*)} $full_url page_url

    ns_log Notice "im_component_page_url: page_url=$page_url"
    return $page_url
}


ad_proc -public im_component_box { 
    plugin_id
    title 
    body 
} {
    Returns a two row table with background colors
} {
    if {"" == $body} { return "" }

    set user_id [ad_get_user_id]
    set page_url [im_component_page_url]
    set return_url [im_url_with_query]
    set base_url "/intranet/admin/components/component-action"

    set plugin_url [export_vars -base $base_url {plugin_id return_url}]

    set right_icons "
        <nobr>
	<a href=\"$plugin_url&action=left\">[im_gif arrow_comp_left]</a>
	<a href=\"$plugin_url&action=up\">[im_gif arrow_comp_up]</a>
	<a href=\"$plugin_url&action=down\">[im_gif arrow_comp_down]</a>
	<a href=\"$plugin_url&action=right\">[im_gif arrow_comp_right]</a>
	<a href=\"$plugin_url&action=close\">[im_gif comp_delete]</a>
        </nobr>
    "

    if {0 == $plugin_id} { set right_icons ""}


    # Only for debugging purposes!
    db_1row component_info "
	select
		c.plugin_id,
		c.plugin_name,
		c.component_tcl,
		c.title_tcl,
		m.minimized_p,
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

    if {"f" == $minimized_p} {
	set min_gif "<a href=\"$plugin_url&action=minimize\">[im_gif arrow_comp_minimize]</a>"
    } else {
	set min_gif "<a href=\"$plugin_url&action=normal\">[im_gif arrow_comp_maximize]</a>"
    }

    set header "
	<tr>
	   <td class=tableheader width=25>$min_gif</td>
	   <td class=tableheader align=left>$title</td>
	   <td class=tableheader width=100 align=right><nobr>$right_icons</td>
	</tr>
    "

    set body "
	<tr>
	  <td class=tablebody colspan=3><font size=-1>$body</font></td>
	</tr>
    "
    if {"t" == $minimized_p} { set body "" }

    return "
	<table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
        <thead>
        <tr><td class=tableheader>
          <table cellpadding=0 cellspacing=0 width='100%'>
	  $header
	  </table>
        </td></tr>
        </thead>
        <tbody>
	$body
        </tbody>
	</table><br>
    "

}



ad_proc -public im_component_bay { location {view_name ""} } {
    Checks the database for Plug-ins for this page and component
    bay.
} {
    set user_id [ad_get_user_id]

    # Get the URL of the current page
    set url_stub [im_component_page_url]

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
	select	*
	from (
		select
			c.plugin_id,
			c.plugin_name,
			c.component_tcl,
			c.title_tcl,
			coalesce(m.sort_order, c.sort_order) as sort_order,
			coalesce(m.location, c.location) as location,
			im_object_permission_p(c.plugin_id, :user_id, 'read') as perm
		from
			im_component_plugins c
			left outer join
			    (	select	* 
				from	im_component_plugin_user_map 
				where	user_id = :user_id
			    ) m
			    on (c.plugin_id = m.plugin_id)
		where
			c.page_url = :url_stub
			and (view_name is null or view_name = :view_name)
	    ) p
	where	
		location = :location
	order by 
		sort_order
    "

    set html ""
    db_foreach get_plugins $plugin_sql {

	if {$any_perms_set_p > 0 && "f" == $perm} { continue }
	
	if {"" == $sort_order} { set sort_order $default_sort_order }
	if {"" == $location} { set location $default_location }

	set component_html [uplevel 1 $component_tcl]
	set title_html $plugin_name
	if {"" != $title_tcl} {
	    set title_html [uplevel 1 $title_tcl]
	}

	if { [catch {
	    # "uplevel" evaluates the 2nd argument!!
	} err_msg] } {
	    set html "<table>\n<tr><td><pre>$err_msg</pre></td></tr></table>\n"
	    set html [im_table_with_title $plugin_name $html]
	}

	append html [im_component_box $plugin_id $title_html $component_html]

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

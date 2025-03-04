# /packages/intranet-core/tcl/intranet-component-procs.tcl
#
# Copyright (C) 2004 ]project-open[
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
    for the components (this is usually not the case...)
} {
    set any_perms_set_p [util_memoize [list db_string any_perms_set "
        select  count(*)
        from    acs_permissions ap,
                im_profiles p,
                im_component_plugins cp
        where   ap.object_id = cp.plugin_id
                and ap.grantee_id = p.profile_id
    "]]
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

#    ns_log Notice "im_component_page_url: page_url=$page_url"
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

    set user_id [ad_conn user_id]
    set page_url [im_component_page_url]
    set return_url [im_url_with_query]
    set base_url "/intranet/components/component-action"
    set plugin_url [export_vars -quotehtml -base $base_url {plugin_id return_url}]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set system_id [im_system_id]

    if {0 == $plugin_id} { set right_icons ""}

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
	set min_gif "<a href=\"$plugin_url&amp;action=minimize\"><span class=\"icon_minimize\">minimize</span></a>"
    } else {
	set min_gif "<a class=\"icon_maximize\" href=\"$plugin_url&amp;action=normal\"><span class=\"icon_maximize\">maximize</span></a>"
    }

    if {"t" == $minimized_p} { set body "" }

    set help_url [export_vars -base "https://www.project-open.net/en/portlet-[string tolower [string map {" " -} $plugin_name]]" {system_id}]
    set icons "
       $min_gif
       <div class=\"icon_seperator\"></div>
       <a class=\"icon_left\" href=\"$plugin_url&amp;action=left\"><span class=\"icon_left\">left</span></a>
       <a class=\"icon_up\" href=\"$plugin_url&amp;action=up\"><span class=\"icon_up\">up</span></a>
       <a class=\"icon_down\" href=\"$plugin_url&amp;action=down\"><span class=\"icon_down\">down</span></a>
       <a class=\"icon_right\" href=\"$plugin_url&amp;action=right\"><span class=\"icon_right\">right</span></a>
       <div class=\"icon_seperator\"></div>
       <a class=\"icon_close\" href=\"$plugin_url&amp;action=close\"><span class=\"icon_close\">close</span></a>
       <a class=\"icon_help\" target=\"_\" href=\"$help_url\"><span class=\"icon_help\">?</span></a>
    "

    # Show a wrench for the Admin
    if {$user_is_admin_p} {
	set admin_url [export_vars -base "/intranet/admin/components/index" {plugin_id}]
	append icons "
	       <a class=\"icon_wrench\" href=\"$admin_url\" target=\"_blank\"><span class=\"icon_wrench\">admin</span></a>
        "
    }

    append icons "<a class=\"icon_config\" href=\"#\"><span class=\"icon_config\">config</span></a>"

    return "[im_box_header $title $icons]$body[im_box_footer]"
}



ad_proc -public im_component_bay { 
    {-page_url ""}
    location 
    {view_name ""} 
} {
    Checks the database for Plug-ins for this page and component bay.
} {
    set user_id [ad_conn user_id]
    if {"" eq $user_id} { set user_id 0 }
    im_security_alert_check_alphanum -location "im_component_bay: location" -value $location
    im_security_alert_check_alphanum -location "im_component_bay: view_name" -value $view_name

    # Get the URL of the current page
    if {"" eq $page_url} { set page_url [im_component_page_url] }

    # Check if there is atleast one permission set for im_plugin_components
    set any_perms_set_p [im_component_any_perms_set_p]

    # Get the list of plugins and cache for 10 seconds
    set plugin_sql "
	select	*
	from (
		select	c.plugin_id,
			c.plugin_name,
			c.component_tcl,
			c.title_tcl,
			coalesce(m.sort_order, c.sort_order) as sort_order,
			coalesce(m.location, c.location) as location,
			im_object_permission_p(c.plugin_id, $user_id, 'read') as perm
		from	im_component_plugins c
			left outer join
			    (	select	* 
				from	im_component_plugin_user_map 
				where	user_id = $user_id
			    ) m
			    on (c.plugin_id = m.plugin_id)
		where
			c.page_url = '$page_url' and
			(c.enabled_p is null OR c.enabled_p = 't') and
			(view_name is null or view_name = '$view_name')
	    ) p
	where	location = '$location'
	order by 
		sort_order
    "
    set plugin_list [util_memoize [list db_list_of_lists "plugin_list_$user_id" $plugin_sql] 1000]


    set html ""
    foreach plugin_tuple $plugin_list {

	set plugin_id [lindex $plugin_tuple 0]
	set plugin_name [lindex $plugin_tuple 1]
	set component_tcl [lindex $plugin_tuple 2]
	set title_tcl [lindex $plugin_tuple 3]
	set sort_order [lindex $plugin_tuple 4]
	set location [lindex $plugin_tuple 5]
	set perm [lindex $plugin_tuple 6]

	if {$any_perms_set_p > 0 && "f" == $perm} { continue }
	
	if {"" == $sort_order} { set sort_order $default_sort_order }
	if {"" == $location} { set location $default_location }

	if { [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "GracefulErrorHandlingComponentsP" -default 1] } {
	    if {[catch {
		set component_html [uplevel 1 $component_tcl]
	    } err_msg]} {
		global errorInfo
		ns_log Error $errorInfo
		im_feedback_add_message "serious" $errorInfo "intranet-component-procs.tcl" [lang::message::lookup "" intranet-core.ErrCreatingComponent "Error in component '%plugin_name%'. This component will not be available"]
		set component_html ""
	    }
	} else {
	    set component_html [uplevel 1 $component_tcl]
	}

	regsub -all {[^0-9a-zA-Z]} $plugin_name "_" plugin_name_subs
	set plugin_name_key "intranet-core.${plugin_name_subs}"
	set plugin_name [lang::message::lookup "" $plugin_name_key $plugin_name]

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

ad_proc -public im_component_insert { 
    plugin_name 
} {
    Insert a particular component.
    Returns "" if the component doesn't exist.
} {
    set plugin_sql "
	select	c.*
	from	im_component_plugins c
	where	plugin_name = :plugin_name and
		c.enabled_p = 't'
	order by sort_order
    "
    set html ""
    db_foreach get_plugins $plugin_sql {
	if { [catch {
	    # "uplevel" evaluates the 2nd argument!!
	    append html [uplevel 1 $component_tcl]
	} err_msg] } {
	    ad_return_complaint 1 "<li>[_ intranet-core.lt_Error_evaluating_comp]:<br><pre>\n[ad_print_stack_trace]</pre><br>[_ intranet-core.lt_Please_contact_your_s]:<br>"
	}
    }
    return $html
}


ad_proc -public im_component_page { 
    -plugin_id
    -return_url
} {
    Returns a particular component, including im_box_header/footer
    Returns "" if the component doesn't exist or error
} {
    db_1row get_plugin "
	select	c.*
	from	im_component_plugins c
	where	plugin_id = :plugin_id and
		c.enabled_p = 't'
    "
    set html ""
    set icon_url [export_vars -quotehtml -base "/intranet/components/activate-component" {plugin_id return_url}]
    set icon "<a class=\"icon_maximize\" href=\"$icon_url\"><span class=\"icon_maximize\">maximize</span></a>"
	
    regsub -all {[^0-9a-zA-Z]} $plugin_name "_" plugin_name_subs
    set plugin_name_key "intranet-core.${plugin_name_subs}"
    set plugin_name [lang::message::lookup "" $plugin_name_key $plugin_name]

    # "uplevel" evaluates the 2nd argument
    set html "[im_box_header $plugin_name $icon][uplevel 1 $component_tcl][im_box_footer]"

    if { [catch {
    } err_msg] } {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_Error_evaluating_comp]:<br><pre>\n$err_msg\n</pre><br>[_ intranet-core.lt_Please_contact_your_s]:<br>"
    }

    return $html
}

# ----------------------------------------------------------------------
# Generic wrapper for mapping TCL/ADP includelets as a widget
# ---------------------------------------------------------------------

ad_proc -public im_component_includelet {
    {-includelet "/packages/intranet-core/lib/hello-world"}
    {-vars {} }
    {-params {} }
} {
    Parses an includelet and displays the includelet as a
    ]po[ portlet.
    @param includelet Full path to includelet. Working example:
	   "/packages/intranet-core/lib/hello-world"
    @param vars {key1 key2 ...} a list of variable names to pass 
	   to the includelet. The values for the vars are evaluated 
	   in the context of the calling page.
    @param params {key1 value1 key2 value2 ...} a list of key-value
	   pairs. The values specified here are determined when
	   creating the definition of the portlet at the SQL level
	   (im_component_portlet__new), so they are called fixed.
} {
    array set param_hash $params
    set inc_params [list]

    # Add parameters to includelet params
    foreach key [array names param_hash] {
	set value $param_hash($key)
	lappend inc_params [list $key $value]
    }

    # Evaluate the list of pass-through variables in the
    # context of the calling page:
    foreach key $vars {
	unset value
	upvar 1 $key value
	lappend inc_params [list $key $value]
    }

    set result [ad_parse_template -params $inc_params $includelet]
    return $result
}


# /intranet/tcl/intranet-component-procs.tcl
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
    @creation-date  27 January 2004
}


ad_proc -public im_component_bay { location {view_name ""} } {
    Checks the database for Plug-ins for this page and component
    bay.
} {
    # Get the ID of the current page
    set full_url [ns_conn url]

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

    set plugin_sql "
select
	c.*
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

	ns_log Notice "im_component_bay: component_tcl=$component_tcl"
	if { [catch {
	    # "uplevel" evaluates the 2nd argument!!
	    append html [uplevel 1 $component_tcl]
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
        Error evaluating component '$plugin_name' of module '$package_name':<br>
        <pre>\n$err_msg\n</pre><br>
        Please contact your system administrator:<br>"
	}
    }
    return $html
}

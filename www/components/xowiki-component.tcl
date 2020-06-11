
if {![info exists package_id] && ![info exists plugin_name]} {

    ad_page_contract {
	Returns the value of a portlet for the XoWiki.
	@author Frank Bergmann (frank.bergmann@project-open.com)
	@creation-date 06/05/2013
	@cvs-id $Id$
    } {
	{plugin_id:integer ""}
	{plugin_name ""}
	{package_key ""}
	{parameter_list ""}
    }
}

# -------------------------------------------------------------
# Defaults & Parameters
# -------------------------------------------------------------


if {[info exists portlet]} { set plugin_name $portlet }
if {[info exists portlet_name]} { set plugin_name $portlet_name }

if {![info exists plugin_id]} { set plugin_id "" }
if {![info exists package_key]} { set package_key "" }
if {![info exists plugin_name]} { set plugin_name "" }
if {![info exists return_url]} { set return_url [im_url_with_query] }

# Extract the name of the page
set url [ns_conn url]
set url_pieces [split $url "/"]
set last_url_piece [lindex $url_pieces end]

# Convert the name of the page into project_id, user_id or ticket_id
if {![info exists project_id]} {
    set project_id [db_string pid "select project_id from im_projects where project_nr = :last_url_piece" -default ""]
}


# -------------------------------------------------------------
# Get the plugin_id from available data
# -------------------------------------------------------------

# Find out the portlet component if specified
# by name and package
if {"" == $plugin_id} {
    set plugin_id [db_string portlet "
	select	min(plugin_id)
	from	im_component_plugins
	where	plugin_name = :plugin_name and
		package_name = :package_key
    " -default ""]
}

# Try the same, but without the package key
if {"" == $plugin_id} {
    set plugin_id [db_string portlet "
	select	min(plugin_id)
	from	im_component_plugins
	where	plugin_name = :plugin_name
    " -default ""]
}

if {"" == $plugin_id} {
    set result "<pre>
<b>[lang::message::lookup "" intranet-core.Portlet_not_Specified "Portlet Not Specified"]</b>:
[lang::message::lookup "" intranet-core.Portlet_not_Specified_msg "You need to specify either 'plugin_id' or 'plugin_name' and 'package_key'."]
"
    doc_return 200 "text/html" $result
    ad_script_abort
}

# Get everything about the portlet
if {![db_0or1row plugin_info "
	select	*
	from	im_component_plugins
	where	plugin_id = :plugin_id
"]} {
    ad_return_complaint 1 "Didn't find plugin #$plugin_id"
    ad_script_abort
}


# -------------------------------------------------------------
# Security
# -------------------------------------------------------------

set perm_p [im_object_permission -object_id $plugin_id]
if {!$perm_p} {
    set result "<pre>[lang::message::lookup "" intranet-core.You_dont_have_permissions_to_access_this_portlet "
    You don't have sufficient permissions to access this portlet"]"
    doc_return 200 "text/html" $result
    ad_script_abort
}

# -------------------------------------------------------------
# Determine the list of variables in the component_tcl and
# make sure they are specified in the HTTP session
# -------------------------------------------------------------

foreach elem $component_tcl {
    if {[regexp {^\$(.*)} $elem match varname]} {
	set $varname [im_opt_val -limit_to nohtml $varname]
    }
}


set result ""
if {[catch {
    set result [eval $component_tcl]
} err_msg]} {
    set result "Error evaluating portlet:<pre>$err_msg</pre>"
}

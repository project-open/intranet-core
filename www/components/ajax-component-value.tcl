ad_page_contract {
    Return the value of a portlet for AJAX functions.
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author David Blanco (david.blanco@grupoversia.com)
    @creation-date 06/09/2011
    @cvs-id $Id$
} {
    {plugin_id:integer ""}
    {plugin_name ""}
    {package_key ""}
    {parameter_list ""}
}

# -------------------------------------------------------------
# Defaults & Security
# -------------------------------------------------------------

# Find out the portlet component if specified
# by name and package
if {"" == $plugin_id} {
    set plugin_id [db_string portlet "
	select	plugin_id
	from	im_component_plugins
	where	plugin_name = :plugin_name and
		package_name = :package_key
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
db_1row plugin_info "
	select	*
	from	im_component_plugins
	where	plugin_id = :plugin_id
"


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

set form_vars [ns_conn form]
array set form_hash [ns_set array $form_vars]

foreach elem $component_tcl {
    if {[regexp {^\$(.*)} $elem match varname]} {
	if {![info exists form_hash($varname)]} { 
	    doc_return 200 "text/html" "<pre>Error: You have to specify variable '$varname' in the URL."
	    ad_script_abort
	}
	set $varname $form_hash($varname)
    }
}

if {[catch {
    set result [eval $component_tcl]
} err_msg]} {
    doc_return 200 "text/html" "Error:<br><pre>$err_msg</pre>"
} else {
    doc_return 200 "text/html" $result
}




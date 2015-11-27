# /packages/intranet-core/www/report-error.tcl

# Copyright (C) 2003 - 2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract { 
	
	Get err attributes from session vars if not passed

    @param error_stacktrace 
	@param error_content
	@param error_content_filename
	@param return_url

    @author klaus.hofeditz@project-open.com
} {
    { error_stacktrace "" }
    { error_content "" }
    { error_content_filename "" }
    { return_url "" }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [auth::require_login]

# ---------------------------------------------------------------
# Set Err attributes
# ---------------------------------------------------------------

if { "" == $error_content } { set error_content [ad_get_client_property intranet-core error_content] }
if { "" == $error_content_filename } { set error_content_filename [ad_get_client_property intranet-core error_content_filename] }
if { "" == $error_stacktrace } { set error_stacktrace [ad_get_client_property intranet-core error_stacktrace] }

set params [list]
lappend params [list stacktrace $error_stacktrace]
lappend params [list error_content $error_content]
lappend params [list error_content_filename $error_content_filename]
lappend params [list return_url $return_url]

ns_return 200 text/html [ad_parse_template -params $params "/packages/acs-tcl/lib/page-error"]

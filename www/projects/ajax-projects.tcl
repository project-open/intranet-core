# /packages/intranet-core/www/projects/ajax-projects.tcl
#
# Copyright (C) 2009-2024 ]project-open[
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
    Returns a komma separated key-value list of projects per company.
    @param company_id The company
    @author frank.bergmann@project-open.com
} {
    company_id:integer
    user_id:notnull,integer
    { include_empty_p "" }
    { auto_login "" }
}

# Check the auto_login token
set valid_login [im_valid_auto_login_p -check_user_requires_manual_login_p 0 -user_id $user_id -auto_login $auto_login]
if {!$valid_login} { 
    # Let the SysAdmin know what's going on here...
    im_security_alert \
	-location "ajax-offices.tcl" \
	-message "Invalid authentication" \
	-value "user_id=$user_id, auto_login=$auto_login" \
	-severity "Hard"

    set error_msg [lang::message::lookup "" intranet-core.Error "Error"]
    set invalid_auth_msg [lang::message::lookup "" intranet-core.Invalid_Authentication_for_user "Invalid Authentication for user %user_id%"]
    doc_return 200 "text/plain" "0,$error_msg: $invalid_auth_msg"
    ad_script_abort
} 

if {"" == $company_id} {
    doc_return 200 "text/plain" "0|Undefined company - no address available"
    ad_script_abort
}

set projects_sql "
	select	p.*
	from	im_projects p
	where	p.company_id = :company_id and
                p.parent_id is null and
                p.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","])
	order by p.project_name
"
set result ""
if {"" ne $include_empty_p} {
    append result "|[_ intranet-core.All]"
}

db_foreach offices $projects_sql {
    if {"" != $result} { append result "|\n" }
    append result "$project_id|$project_name"
}

doc_return 200 "text/plain" $result

# /packages/intranet-core/www/offices/ajax-offices.tcl
#
# Copyright (C) 2009 ]project-open[
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
    Returns a komma separated key-value list of offices per company.
    @param company_id The company
    @author frank.bergmann@project-open.com
} {
    company_id:integer
    user_id:notnull,integer
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
    doc_return 200 "text/plain" "0,Undefined company - no address available"
    ad_script_abort
}

set offices_sql "
	select	o.*
	from	im_offices o
	where	o.company_id = :company_id
	order by o.office_name
"
set result ""
db_foreach offices $offices_sql {
    if {"" != $result} { append result "|\n" }
    append result "$office_id|$office_name"
}

doc_return 200 "text/plain" $result

# /packages/intranet-core/www/users/ajax-company-contacts.tcl
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
    Returns a komma separated key-value list of company contacts company.
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
    doc_return 200 "text/plain" "0,Undefined company - no contacts available"
    ad_script_abort
}

set users_sql "
	select	*
	from	(
		select	u.*,
			im_name_from_user_id(u.user_id) as user_name
		from	cc_users u,
			acs_rels r
		where	r.object_id_one = :company_id and
			r.object_id_two = u.user_id and
			u.user_id not in (
				select	member_id
				from	group_distinct_member_map
				where	group_id = [im_employee_group_id]
			)
		) u
	order by lower(user_name)
"
set result ""
db_foreach users $users_sql {
    if {"" != $result} { append result "|\n" }
    append result "$user_id|$user_name"
}

doc_return 200 "text/plain" $result

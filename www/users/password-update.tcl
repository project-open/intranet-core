# /packages/intranet-core/www/users/password-update.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.

ad_page_contract {
    @cvs-id password-update.tcl,v 3.2.6.3.2.3 2000/09/22 01:36:19 kevin Exp
} {
    user_id:integer,notnull
    return_url
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
set user_admin_p [|| $user_is_admin_p $user_is_wheel_p]

set user_is_freelance_p [ad_user_group_member [im_freelance_group_id] $user_id]
set current_user_is_employee_p [im_user_is_employee_p $current_user_id]

set page_title "Change Password"
set context_bar [ad_context_bar [list /intranet/users/ "Users"] $page_title]

if {$user_admin_p || ($user_is_freelance_p && $current_user_is_employee_p)} {
    # nothing. Allow access
} else {
    ad_return_complaint "Insufficient Privileges" "<li>You must be the system administrator to pursue this operation."
}


db_1row user_info_by_id "
select
	first_names||' '||last_name as name,
	email, 
	url 
from 
	users 
where
	user_id = :user_id
"

set page_body "
<form method=POST action=\"password-update-2\">
[export_form_vars user_id name return_url]
<table cellpadding=0 cellspacing=2 border=0>
  <tr> 
    <td colspan=2 class=rowtitle align=center>Update Password</td>
  </tr>
  <tr><td colspan=2>for $name in [ad_site_home_link]</td></tr>
  <tr>
    <td>New Password</td>
    <td><input type=password name=password_1 size=15></td>
  </tr>
  <tr>
    <td>Confirm</td>
    <td><input type=password name=password_2 size=15></td>
  </tr>
  <tr>
    <td></td>
    <td><input type=submit value=\"Update\"></td>
  </tr>
</table>"

doc_return  200 text/html [im_return_template]

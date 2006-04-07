# /packages/intranet-core/www/users/password-update-2.tcl
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
# See the GNU General Public License for more details.

ad_page_contract {

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
    name:notnull
    password_1:notnull
    password_2:notnull
    return_url
}



# Check the permissions that the current_user has on user_id
set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin
if {!$admin && $user_id != $current_user_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_are_not_authorize]"
    return
}

set exception_text ""
set exception_count 0

if { ![info exists password_1] || [empty_string_p $password_1] } {
    append exception_text "<li>[_ intranet-core.lt_You_need_to_type_in_a_3]"
    incr exception_count
}

if { ![info exists password_2] || [empty_string_p $password_2] } {
    append exception_text "<li>[_ intranet-core.lt_You_need_to_confirm_t]"
    incr exception_count
}

if { [string compare $password_2 $password_1] != 0 } {
    append exception_text "<li>[_ intranet-core.lt_Your_passwords_dont_m]"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}



ad_change_password $user_id $password_1


set password $password_1
set offer_to_email_new_password_link ""
if {[ad_parameter EmailChangedPasswordP "" 1]} { 
    set offer_to_email_new_password_link "<a href=\"email-changed-password?[export_url_vars user_id password]\">[_ intranet-core.lt_Send_user_new_passwor]</a>"
}

set page_body "
[ad_admin_header "[_ intranet-core.Password_Updated]"]
<h2>[_ intranet-core.Password_Updated]</h2>
[_ intranet-core.in] [ad_site_home_link]
<hr>
[_ intranet-core.lt_You_must_inform_the_u]
[_ intranet-core.You_can_return_to] <a href=\"one?[export_url_vars user_id]\">$name</a>
<p> $offer_to_email_new_password_link
[ad_admin_footer]
"

ad_returnredirect $return_url

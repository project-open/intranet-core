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
    @cvs-id password-update-2.tcl,v 3.2.2.4.2.4 2000/09/22 01:36:19 kevin Exp
} {
    user_id:integer,notnull
    name:notnull
    password_1:notnull
    password_2:notnull
    return_url
}


set exception_text ""
set exception_count 0

if { ![info exists password_1] || [empty_string_p $password_1] } {
    append exception_text "<li>You need to type in a password\n"
    incr exception_count
}

if { ![info exists password_2] || [empty_string_p $password_2] } {
    append exception_text "<li>You need to confirm the password that you typed.  (Type the same thing again.) \n"
    incr exception_count
}

if { [string compare $password_2 $password_1] != 0 } {
    append exception_text "<li>Your passwords don't match!  Presumably, you made a typo while entering one of them.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# If we are encrypting passwords in the database, do it now.
if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set password_1 [ns_crypt $password_1 [ad_crypt_salt]]
}

set sql "update users set password = :password_1 where user_id = :user_id"

if [catch { db_dml password_update $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
	<blockquote>$errmsg</blockquote>"
    return
}

set password $password_1
set offer_to_email_new_password_link ""
if {[ad_parameter EmailChangedPasswordP "" 1]} { 
    set offer_to_email_new_password_link "<a href=\"email-changed-password?[export_url_vars user_id password]\">Send user new password by email</a>"
}

set page_body "
[ad_admin_header "Password Updated"]
<h2>Password Updated</h2>
in [ad_site_home_link]
<hr>
You must inform the user of their new password as there is currently no 
other way for the user to find out.
You can return to <a href=\"one?[export_url_vars user_id]\">$name</a>
<p> $offer_to_email_new_password_link
[ad_admin_footer]
"

ad_returnredirect $return_url

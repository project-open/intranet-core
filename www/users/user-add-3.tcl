# /packages/intranet-core/www/users/user-add-3.tcl
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
    Sends email confirmation to user after they've been created

    @cvs-id $Id$
} -query {
    email
    message
    first_names
    last_name
    user_id
    {referer "/acs-admin/users"}
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
    export_vars:onevalue
}

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id add_users]} {
    ad_return_complaint 1 "<li>You have no rights to see this page"
    return
}
    
set admin_user_id [ad_verify_and_get_user_id]

set context [list [list "./" "Users"] "New user notified"]
set export_vars [export_url_vars user_id]

set admin_email [db_string unused "select email from 
parties where party_id = :admin_user_id"]

if [catch {ns_sendmail "$email" "$admin_email" "You have been added as a user to [ad_system_name] at [ad_url]" "$message"} errmsg] {
    ad_return_error "Mail Failed" "The system was unable to send email.  Please notify the user personally.  This problem is probably caused by a misconfiguration of your email system.  Here is the error:
<blockquote><pre>
[ad_quotehtml $errmsg]
</pre></blockquote>"
    return
}

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
    submit_send:optional
    submit_nosend:optional
    { return_url "/intranet/users/" }
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
    export_vars:onevalue
}

set send_email_p [info exists submit_send]

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id add_users]} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_no_rights_to]"
    return
}
    
set ad_system_name [ad_system_name]
set ad_url [ad_url]
set admin_user_id [ad_verify_and_get_user_id]
set admin_email [db_string unused "select email from parties where party_id = :admin_user_id"] 


set page_title [_ intranet-core.lt_New_user_notifiedset_]
set context [list [list "./" [_ intranet-core.Users]] $page_title]
set export_vars [export_url_vars user_id]


if {$send_email_p} {
    if [catch {ns_sendmail "$email" "$admin_email" "You have been added as a user to [ad_system_name] at [ad_url]" "$message"} errmsg] {
	ad_return_error "[_ intranet-core.Mail_Failed]" "[_ intranet-core.lt_The_system_was_unable]<br>[_ intranet-core.Here_is_the_error]
<blockquote><pre>
[ad_quotehtml $errmsg]
</pre></blockquote>"
        return
    }
}


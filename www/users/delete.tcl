# /packages/intranet-core/www/users/delete.tcl
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
    present a form that will let an admin mark a user's account deleted
    (or ban the user)
    
    @param user_id
    @param return_url

    @author philg@mit.edu
} {
    user_id:integer,notnull
    return_url:optional
}


set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/delete.tcl?user_id=$user_id"]
    return
}



db_1row user_full_name "select first_names, last_name from users where user_id = :user_id"

set page_content "[ad_admin_header "Deleting $first_names $last_name"]

<h2>Deleting $first_names $last_name</h2>

<hr>

You have two options here:

<ul>

<li><a href=\"delete-2?[export_url_vars user_id return_url]\">just mark the account deleted</a> 
(as if the user him or herself had unsubscribed)

<p>

<li><form method=POST action=\"delete-2\">
[export_form_vars return_url]
<input type=submit value=\"Ban this user\">
[export_form_vars user_id]
<input type=hidden name=banned_p value=\"t\">
<br>
reason:  <input type=text size=60 name=banning_note>
</form>

</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content

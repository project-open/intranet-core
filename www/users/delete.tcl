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
    @author frank.bergmann@project-open.com
} {
    user_id:integer,notnull
    return_url:optional
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin

if {!$admin} {
    ad_return_complaint "You need to have administration rights for this user."
    return
}


# ---------------------------------------------------------------
# Delete
# ---------------------------------------------------------------

db_1row user_full_name "select first_names, last_name from users where user_id = :user_id"

set page_content "[ad_admin_header "[_ intranet-core.lt_Deleting_first_names_]"]

<h2>[_ intranet-core.lt_Deleting_first_names_]</h2>

<hr>

[_ intranet-core.lt_You_have_two_options_]

<ul>

<li><a href=\"delete-2?[export_url_vars user_id return_url]\">[_ intranet-core.lt_just_mark_the_account]</a> 
([_ intranet-core.lt_as_if_the_user_him_or])

<p>

<li><form method=POST action=\"delete-2\">
[export_form_vars return_url]
<input type=submit value=\"[_ intranet-core.Ban_this_user]\">
[export_form_vars user_id]
<input type=hidden name=banned_p value=\"t\">
<br>
reason:  <input type=text size=60 name=banning_note>
</form>

</ul>

[ad_admin_footer]
"

ad_return_template

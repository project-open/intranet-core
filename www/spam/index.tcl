# /packages/intranet-core/www/intranet/spam/index.tcl
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
    Let's a user write spam to people in 1 group (group_id) who 
    aren't in another (limit_to_users_in_group_id)
    We chose not to use the spam module because it's support of 
    complex sql queries is not yet bug-free

    @param group_id_list A list of group_ids to spam.
    @param description A description of the spam.
    @param all_or_any All to spam intersection of group_id_list. Any to spam union of group_id_list.

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    group_id_list:notnull,multiple
    description:optional
    {all_or_any all}    
}

set user_id [ad_maybe_redirect_for_registration]

### Create bind variables for every group id in group_id_list
set bind_vars [ns_set create]

set group_id_sql_list [im_append_list_to_ns_set $bind_vars group_id_sql [split $group_id_list ","]]

set sql_query "select count(1) from user_groups where group_id in ($group_id_sql_list)"
set exists_p [db_string intranet_spam_get_num_valid_groups $sql_query -default "" -bind $bind_vars]
	
if { $exists_p == 0 } {
    ad_return_complaint 1 "The specified group(s) (#$group_id_list) could not be found"
    return
}

#-------------------------------------
set number_users_to_spam [im_spam_number_users $group_id_list $all_or_any]

if { [string compare $all_or_any "any"] == 0 } {
    set sql_clause [im_append_list_to_ns_set $bind_vars group_id_sql [split $group_id_list ","]]
    set group_list_clause "and ugm.group_id in ($sql_clause)"
} else {
    set group_list_clause [im_spam_multi_group_exists_clause $bind_vars $group_id_list] 
}

set sql_query "
select count(distinct u.user_id)
from users_active u, user_group_map ugm
where u.user_id=ugm.user_id $group_list_clause"

set number_users_to_spam [db_string intranet_spam_num_to_spam $sql_query -bind $bind_vars]

#------------------------------------

if { $number_users_to_spam == 0 } {
    ad_return_complaint 1 "There are no active users to spam!"
    return
}

set from_address [db_string intranet_spam_get_email_address "select email from users where user_id=:user_id"]

db_release_unused_handles

if { [exists_and_not_null description] } {
    set page_title $description
} else {
    set page_title "Spam users"
}

set context_bar [ad_context_bar "Spam users"]

set page_body "
<b>This email will go to $number_users_to_spam [util_decode $number_users_to_spam 1 "user" "users"]
(<a href=users-list?[export_url_vars group_id_list description return_url all_or_any]>view</a>).</b>

<p> <form method=post action=confirm>
[export_form_vars group_id_list description return_url all_or_any]

<table>

<tr>
<td align=right>From:</td>
<td>
<input type=text size=30 name=from_address [export_form_value from_address]></td>
</tr>

<tr>
<td align=right>Subject:</td>
<td><input name=subject type=text size=50></td>
</tr>

<tr>
<td valign=top align=right>Message:</td>
<td>
<textarea name=message rows=10 cols=70 wrap=soft></textarea>
</td>
</tr>

</table>

<center>
<input type=submit value=\"Send Email\">
</center>
</form>
"
 

doc_return  200 text/html [im_return_template]





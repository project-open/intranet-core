# /packages/intranet-core/www/intranet/spam/send.tcl
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
    Sends email to users specified

    @param group_id_list A list of group_ids to spam.
    @param description A description of the spam.
    @param all_or_any Spam to all/any members in group_id_list.
    @param from_address The from address in the email.
    @param subject The subject in the email.
    @param message The message in the email.

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    group_id_list:notnull,multiple
    description:optional
    {all_or_any all}   
    from_address:notnull
    subject:notnull
    message:notnull
}

set required_vars [list \
	[list group_id_list "Missing group id(s)"] \
	[list from_address "Missing from address"] \
	[list subject "Missing subject"] \
	[list message "Missing message"]]

set errors [im_verify_form_variables $required_vars]

if { ![empty_string_p $errors] } {
    ad_return_complaint 2 $errors
    return
}

### Create bind variables for every group id in group_id_list
set bind_vars [ns_set create]

set group_id_sql_list [im_append_list_to_ns_set -integer_p t $bind_vars group_id_sql [split $group_id_list ","]]

if { ![info exists all_or_any] || [string compare $all_or_any "any"] != 0 } {
    set group_list_clause [im_spam_multi_group_exists_clause $bind_vars $group_id_list] 
} else {
    set group_list_clause "and ugm.group_id in ($group_id_sql_list)"
}

set sql_query \
"select distinct u.email 
 from users_active u, user_group_map ugm 
 where u.user_id=ugm.user_id $group_list_clause"

set email_list [db_list intranet_spam_get_email_list $sql_query -bind $bind_vars]

set sql	"select ug.group_name 
           from user_groups ug 
          where ug.group_id in ($group_id_sql_list)"

set group_string ""
set ctr 0
db_foreach select_group_names $sql -bind $bind_vars {
    append group_string "  * $group_name\n"
    incr ctr
}

db_release_unused_handles

if { [exists_and_not_null description] } {
    set description_html "<br><b>Description:</b> $description\n"
} else {
    set description_html ""
}


# Start streaming out data - we have released the db handle and are going to send email

set context_bar [im_context_bar [list index?[export_ns_set_vars url] "Spam users"] "Sending email"]
ReturnHeaders
ns_write "
[im_header]
$description_html

<p>Sending email
<ol>
"

if { $ctr == 1 } {
    set explanation "This email message was sent to people who are members of $group_name"
} else {
    set explanation "
This email message was sent to people who are members of $all_or_any of the
following groups:

$group_string
"
}

append message "


---------------------------------------------------------------------------
$explanation
---------------------------------------------------------------------------
"

foreach email $email_list {
    ns_write "  <li> $email"
    if { [catch {ns_sendmail $email $from_address $subject $message} err_msg] } {
	ns_write " Error: $err_msg"
    }
    ns_write "\n"
}

ns_write "</ol>\n"

if { [exists_and_not_null return_url] } {
    ns_write "<a href=\"$return_url\">Go back to where you were</a>\n"
}

ns_write [im_footer]

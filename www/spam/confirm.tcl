# /www/intranet/spam/confirm.tcl

ad_page_contract {
    Confirmation screen before email is sent.

    @param group_id_list A list of group_ids to spam.
    @param description A description of the spam.
    @param all_or_any Spam to all/any members in group_id_list.
    @param from_address The from address in the email.
    @param subject The subject in the email.
    @param message The message in the email.

    @author mbryzek@arsdigita.com
    @creation-date Mar 2000

    @cvs-id confirm.tcl,v 1.7.6.6 2000/09/22 01:38:48 kevin Exp
} {
    group_id_list:optional,multiple
    description:optional
    {all_or_any all}
    from_address:optional
    subject:optional
    message:optional
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

set group_id_sql_list [im_append_list_to_ns_set $bind_vars group_id_sql [split $group_id_list ","]]

set sql_query "select count(1) from user_groups where group_id in ($group_id_sql_list)"
set exists_p [db_string intranet_spam_get_num_valid_groups $sql_query -default "" -bind $bind_vars]

if { $exists_p == 0 } {
    ad_return_complaint 1 "The specified group(s) (#$group_id_list) could not be found"
    return
}

set number_users_to_spam [im_spam_number_users $group_id_list $all_or_any]

if { $number_users_to_spam == 0 } {
    ad_return_complaint 1 "There are no active users to spam!"
    return
}

db_release_unused_handles

if { [exists_and_not_null description] } {
    set description_html "<br><b>Description:</b> $description\n"
} else {
    set description_html ""
}

set page_title "Confirm email"
set context_bar [ad_context_bar [list index?[export_ns_set_vars url] "Spam users"] "Confirm email"]

set page_body "
<b>This email will go to $number_users_to_spam [util_decode $number_users_to_spam 1 "user" "users"]
(<a href=users-list?[export_url_vars group_id_list description return_url all_or_any]>view</a>).</b>
$description_html
<p> 

<pre>
From: $from_address
Subject: $subject
------------------
[wrap_string $message]
</pre>

[im_yes_no_table send cancel [list group_id_list description return_url from_address subject message all_or_any] "Send email" "Cancel"]
"
 
doc_return  200 text/html [im_return_template]

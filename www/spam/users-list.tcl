# /www/intranet/spam/users-list.tcl

ad_page_contract {
    Lists all users who are about to be spammed

    @param group_id_list A list of group_ids to spam.
    @param description A description of the spam.
    @param all_or_any Spam to all/any members in group_id_list.

    @author mbryzek@arsdigita.com
    @creation-date Mar 2000

    @cvs-id users-list.tcl,v 1.7.6.7 2000/09/22 01:38:49 kevin Exp
} {
    group_id_list:notnull,multiple
    description:optional
    {all_or_any all}
}

### Create bind variables for every group id in group_id_list
set ctr 0
set bind_vars [ns_set create]

if { [string compare $all_or_any "any"] == 0 } {
    set sql_clause [im_append_list_to_ns_set $bind_vars group_id_sql [split $group_id_list ","]]
    set group_list_clause "and ugm.group_id in ($sql_clause)"
} else {
    set group_list_clause [im_spam_multi_group_exists_clause $bind_vars $group_id_list] 
}

set sql_query "
select distinct u.user_id, u.first_names || ' ' || u.last_name as user_name, u.email
from users_active u, user_group_map ugm
where u.user_id=ugm.user_id $group_list_clause"

set page_title "Users who are about to receive your spam"
set context_bar [ad_context_bar [list index?[export_ns_set_vars url] "Spam users"] "View users"]

set page_body "<ol>\n"

db_foreach select_name_email $sql_query -bind $bind_vars {
    append page_body "  <li> <a href=../users/view?[export_url_vars user_id]>$user_name</a> - <a href=mailto:$email>$email</a>\n"
}

append page_body "</ol>\n"



doc_return  200 text/html [im_return_template]









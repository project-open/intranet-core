# /www/intranet/offices/delete.tcl

ad_page_contract {
    Offers a confirmation page asking the user if s/he's sure to delete the office
    @param group_id
    @author Tony Tseng <tony@arsdigita.com>
    @creation-date 10/26/00
    @cvs-id delete.tcl,v 1.1.2.1 2000/10/30 20:50:24 tony Exp
} {
    group_id:naturalnum
}

#check if the user is an admin
set user_id [ad_verify_and_get_user_id]
if { ![ad_permission_p site_wide "" "" $user_id] } {
    ad_return_forbidden { Access denied } { Since this action involves deleting a user group, you must be a site-wide administrator to perform it. }
    return
}

db_1row get_office_name {
    select group_name as office_name
    from user_groups
    where group_id=:group_id
}
db_release_unused_handles
set page_title "Delete office"
set context_bar [ad_context_bar [list ./ "Offices"] $page_title]
set page_body "
Are you sure you want to delete $office_name?
<form action=\"delete-2\" method=post>
[export_form_vars group_id]
<input type=\"submit\" value=\"Yes\">
"

doc_return 200 text/html [im_return_template]

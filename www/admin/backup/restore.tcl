# /packages/intranet-core/www/admin/restore.tcl

ad_page_contract {
    Go through all know backup "reports" and try to
    load the corresponding backup file from the 
    specified directory.
} {
    { path "/tmp" }
    { return_url "" }
}


set user_id [ad_get_user_id]
set page_title "Backup"
set context_bar [ad_context_bar_ws $page_title]
set page_body "<H1>$page_title</H1>"

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

set page_body "<ul>\n"

# append page_body [im_import_categories "$path/im_categories.csv"]
append page_body [im_import_users "$path/im_users.csv"]
append page_body [im_import_offices "$path/im_offices.csv"]
append page_body [im_import_customers "$path/im_customers.csv"]
append page_body [im_import_projects "$path/im_projects.csv"]
append page_body [im_import_office_members "$path/im_office_members.csv"]
append page_body [im_import_customer_members "$path/im_customer_members.csv"]
append page_body [im_import_project_members "$path/im_project_members.csv"]

append page_body [im_import_freelancers "$path/im_freelancers.csv"]
append page_body [im_import_freelance_skills "$path/im_freelance_skills.csv"]


set page_body "
<li>
<p>Finished</p>
"

doc_return  200 text/html [im_return_template]



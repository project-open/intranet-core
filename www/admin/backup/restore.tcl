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
set page_title "Restore"
set context_bar [ad_context_bar $page_title]
set page_body "<H1>$page_title</H1>"

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

set page_body "<ul>\n"

#append page_body [im_import_categories "$path/im_categories.csv"]
#append page_body [im_import_users "$path/im_users.csv"]
#append page_body [im_import_profiles "$path/im_profiles.csv"]
#append page_body [im_import_offices "$path/im_offices.csv"]
#append page_body [im_import_customers "$path/im_customers.csv"]
#append page_body [im_import_projects "$path/im_projects.csv"]
#append page_body [im_import_office_members "$path/im_office_members.csv"]
#append page_body [im_import_customer_members "$path/im_customer_members.csv"]
#append page_body [im_import_project_members "$path/im_project_members.csv"]
#append page_body [im_import_freelancers "$path/im_freelancers.csv"]
#append page_body [im_import_freelance_skills "$path/im_freelance_skills.csv"]
#append page_body [im_import_hours "$path/im_hours.csv"]
#append page_body [im_import_trans_project_details "$path/im_trans_project_details.csv"]

#append page_body [im_import_trans_tasks "$path/im_trans_tasks.csv"]
#append page_body [im_import_invoices "$path/im_invoices.csv"]
#append page_body [im_import_invoice_items "$path/im_invoice_items.csv"]

append page_body [im_import_payments "$path/im_payments.csv"]


append page_body "
<li>
<p>Finished</p>
"

doc_return  200 text/html [im_return_template]



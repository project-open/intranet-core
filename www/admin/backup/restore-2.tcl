# /packages/intranet-core/www/admin/restore-2.tcl

ad_page_contract {
    Changes all clients, users, prices etc to allow
    to convert a productive system into a demo.
} {
    path
    view:array
    { return_url "index" }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Restore"
set context_bar [im_context_bar $page_title]
set context ""
set page_body "<H1>$page_title</H1>"
set today [db_string today "select to_char(sysdate, 'YYYY-MM-DD.HH-mm') from dual"]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}

set joined_ids [join [array names view] ","]

set sql "
select
        v.*
from
        im_views v
where
        v.view_id in ($joined_ids)
"

set page_body "<ul>\n"
set ctr 0
db_foreach foreach_report $sql {

    regexp {im_(.*)} $view_name match object

    set cmd "append page_body \[im_import_$object \"$path/$view_name.csv\"]"
    append page_body "<li>$cmd<br>\n"

    if [catch { eval $cmd } errmsg] {
	append page_body "<pre>$errmsg</pre>\n"
    }
    incr ctr
}

return


append page_body [im_import_categories "$path/im_categories.csv"]
append page_body [im_import_users "$path/im_users.csv"]
append page_body [im_import_profiles "$path/im_profiles.csv"]
append page_body [im_import_offices "$path/im_offices.csv"]
append page_body [im_import_companies "$path/im_companies.csv"]
append page_body [im_import_projects "$path/im_projects.csv"]
append page_body [im_import_office_members "$path/im_office_members.csv"]
append page_body [im_import_company_members "$path/im_company_members.csv"]
append page_body [im_import_project_members "$path/im_project_members.csv"]
append page_body [im_import_freelancers "$path/im_freelancers.csv"]
append page_body [im_import_freelance_skills "$path/im_freelance_skills.csv"]
append page_body [im_import_employees "$path/im_employees.csv"]
append page_body [im_import_hours "$path/im_hours.csv"]
append page_body [im_import_user_absences "$path/im_user_absences.csv"]
append page_body [im_import_employees "$path/im_employees.csv"]
append page_body [im_import_trans_project_details "$path/im_trans_project_details.csv"]
append page_body [im_import_trans_tasks "$path/im_trans_tasks.csv"]
append page_body [im_import_costs_centers "$path/im_costs_centers.csv"]
append page_body [im_import_investments "$path/im_investments.csv"]
append page_body [im_import_costs "$path/im_costs.csv"]
append page_body [im_import_invoices "$path/im_invoices.csv"]
append page_body [im_import_invoice_items "$path/im_invoice_items.csv"]
append page_body [im_import_project_invoice_map "$path/im_project_invoice_map.csv"]
append page_body [im_import_payments "$path/im_payments.csv"]
append page_body [im_import_prices "$path/im_trans_prices.csv"]
append page_body [im_import_target_languages "$path/im_target_languages.csv"]




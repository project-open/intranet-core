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

# Extract the view_ids from the view array to
# create a "in (<view_ids>)" SQL statement
#
set joined_ids [join [array names view] ","]

set sql "
select
        v.*
from
        im_views v
where
        v.view_id in ($joined_ids)
order by
	sort_order
"

set page_body "<ul>\n"
set ctr 0
db_foreach foreach_report $sql {

    regexp {im_(.*)} $view_name match object

    set cmd "append page_body \[im_import_$object \"$path/$view_name.csv\"]"
    append page_body "<li>$cmd<br>\n"

    eval $cmd

#    if [catch { eval $cmd } errmsg] {
#	append page_body "<pre>$errmsg</pre>\n"
#    }
    incr ctr
}

return

# 10
append page_body [im_import_categories "$path/im_categories.csv"]

# 20
append page_body [im_import_users "$path/im_users.csv"]

# 30
append page_body [im_import_profiles "$path/im_profiles.csv"]

# 40
append page_body [im_import_offices "$path/im_offices.csv"]

# 50
append page_body [im_import_companies "$path/im_companies.csv"]

# 60
append page_body [im_import_projects "$path/im_projects.csv"]

# 70
append page_body [im_import_office_members "$path/im_office_members.csv"]

# 80
append page_body [im_import_company_members "$path/im_company_members.csv"]

# 90
append page_body [im_import_project_members "$path/im_project_members.csv"]

# 100
append page_body [im_import_freelancers "$path/im_freelancers.csv"]

# 110
append page_body [im_import_freelance_skills "$path/im_freelance_skills.csv"]

# 120
append page_body [im_import_employees "$path/im_employees.csv"]

# 130
append page_body [im_import_hours "$path/im_hours.csv"]

# 140
append page_body [im_import_user_absences "$path/im_user_absences.csv"]

# 150
append page_body [im_import_trans_project_details "$path/im_trans_project_details.csv"]

# 160
append page_body [im_import_trans_tasks "$path/im_trans_tasks.csv"]

#170
append page_body [im_import_target_languages "$path/im_target_languages.csv"]

# 200
append page_body [im_import_costs_centers "$path/im_costs_centers.csv"]

# 210
append page_body [im_import_investments "$path/im_investments.csv"]

# 220
append page_body [im_import_costs "$path/im_costs.csv"]

# 230
append page_body [im_import_invoices "$path/im_invoices.csv"]

# 240
append page_body [im_import_invoice_items "$path/im_invoice_items.csv"]

# 250
append page_body [im_import_project_invoice_map "$path/im_project_invoice_map.csv"]

# 260
append page_body [im_import_payments "$path/im_payments.csv"]

# 270
append page_body [im_import_prices "$path/im_trans_prices.csv"]

# 280
append page_body [im_import_prices "$path/im_trans_trados_matrices.csv"]






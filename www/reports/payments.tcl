# /www/intranet/reports/payments.tcl
ad_page_contract {
    This page will display a list of late and upcoming payments
    Diemnsional sliders at the top will control whether the user sees late payments, upcoming payments 
    (upcoming split into week and month) or all payments
    Maybe include links to spam for certain projects.

    @param due_date
    @param order_by

    @author unknown
    @cvs-id payments.tcl,v 1.5.2.6 2000/09/22 01:38:47 kevin Exp
} {
    {due_date "all"}
    order_by:optional
}

ad_maybe_redirect_for_registration

if { ![info exists orderby] } {
   set orderby [list]
 }

set dimensional {
    {due_date "Due Date" all {
	{all "All Payments" {}}
	{late "Late Payments" {where "sysdate > due_date"}}
	{next_week "Upcoming Week" {where "due_date between sysdate and sysdate +  7"}}
	{next_month "Upcoming Month" {where "due_date between sysdate and sysdate + 30"}}
	{no_info "No information" {where "due_date is null"}}
	
}   }
}

set table_def {
    {group_name "Group" {} {<td align=left><a href=[im_url_stub]/projects/view?[export_url_vars group_id]>$group_name</a></td>}}
    {fee "Fee" {} {<td align=left>\$[util_commify_number $fee]</td>}}
    {fee_type "Type of Fee" {} l}
    {due_date "Due Date" {} <td>&nbsp;$due_date</td>}
    {email "Project Lead Email" {} {<td><a href=mailto:$email>$email</a></td>} }
}

set sql_query "select payments.fee as fee, payments.fee_type as fee_type, 
                      payments.due_date as due_date,
                      user_groups.group_name as group_name, user_groups.group_id,
                      users.email as email
                 from im_project_payments payments, im_projects, users, user_groups 
                 where im_projects.project_lead_id = users.user_id
                 and im_projects.group_id = payments.group_id 
                 and user_groups.group_id = payments.group_id
                 [ad_dimensional_sql $dimensional where]
                 and received_date is null
                 [ad_order_by_from_sort_spec $orderby $table_def]"



set page_title "Payment Report"
set context_bar [ad_context_bar [list index "Reports"] $page_title]
set page_body "
[ad_dimensional $dimensional]
[ad_table -Ttable_extra_html "border=1" payment_statement $sql_query $table_def]
"

doc_return  200 text/html [im_return_template]

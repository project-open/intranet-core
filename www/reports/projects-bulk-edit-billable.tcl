# /www/intranet/reports/projects-bulk-edit-projects.tcl

ad_page_contract {

    This page allows bulk editing of billable column for im_projects

    @author umathur@arsdigita.com
    @cvs-id projects-bulk-edit-billable.tcl,v 1.1.2.2 2000/09/22 01:38:47 kevin Exp

} {

}

set table_def {
    {group_name "Project Name" {} {<td><a href=[im_url_stub]/projects/view?group_id=$group_id>$group_name</a></td>}}
    {group_id "Edit This Project" no_sort {<td>
<input type=hidden name=\"old_project.$group_id\" [export_form_value billable_type_id]>
<select name=\"project.$group_id\">[ad_generic_optionlist $items $values $billable_type_id]</select></td>}}
}


set items [list]
set values [list]
db_foreach select_billing_categories {
    select category, category_id 
      from categories
     where category_type = 'Intranet Project Billing Type'
    order by lower(category)} {
	lappend items $category
	lappend values $category_id
    }

set sql_query "select ug.group_name as group_name, proj.group_id, proj.billable_type_id
                from im_projects proj, user_groups ug
                where ug.group_id = proj.group_id
                order by lower(ug.group_name)"

set context_bar [ad_context_bar [list [im_url_stub]/reports/ Reports] "Edit billable projects"]

doc_return  200 text/html "
[im_header "Project Billable Type"]

<form method=post action=projects-bulk-edit-billable-2>
<center>
[ad_table -Ttable_extra_html "border=1 width=90%" -Trows_per_page 50 -Textra_vars {items values} project_select $sql_query $table_def]

<p><input type=submit value=update>

</center>
</form>
[im_footer]
"




# /www/intranet/reports/checkpoint-one.tcl 

ad_page_contract {
    this file is the target of checklist-progress.cl
    it returns the list of users missing the given checkoff.

    @param user_info
    @param checkpoint_id
    @param checkpoint

    @author unknown
    @cvs-id checkpoint-one.tcl,v 1.4.2.9 2000/09/22 01:38:45 kevin Exp
} {
    user_info:optional
    checkpoint_id:integer,notnull 
    checkpoint:notnull    
}

set dimensional { 
    {user_info "Users: " missing {
	{missing "Checked" {where "im_emp_checkpoint_checkoffs.checkee is NULL"}}
	{having  "Not checked" {where "im_emp_checkpoint_checkoffs.checkee is not NULL"}}
    }
}
}

set table_def {
    {employee "Employee Info" no_sort {<td><a href=[im_url_stub]/employees/admin/pipeline-new?user_id=$user_id>$name</a>}}
}
set sql_query "select first_names||' '||last_name as name, im_employees.user_id as user_id 
                from im_emp_checkpoint_checkoffs, im_employees, users
                 where im_employees.user_id = users.user_id
                 and im_emp_checkpoint_checkoffs.checkee(+) = im_employees.user_id
                 and checkpoint_id(+) = :checkpoint_id
                 [ad_dimensional_sql $dimensional]"


set bind_vars [ns_set create]
ns_set put $bind_vars checkpoint_id $checkpoint_id

set context_bar [ad_context_bar [list "[im_url_stub]/reports/" "Reports"] [list "[im_url_stub]/reports/checkpoint-progress" "Checkpoints"] "One CheckPoint"]

set return_html "[im_header "Checkpoint: $checkpoint"]

[ad_dimensional $dimensional]

[ad_table -bind $bind_vars checkpoint_statement $sql_query $table_def]
[im_footer]"

ns_set free $bind_vars

doc_return  200 text/html $return_html


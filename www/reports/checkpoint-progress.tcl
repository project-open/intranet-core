# /www/intranet/reports/checkpoint-progress.tcl

ad_page_contract {
    this file will give administrators a dimensional bar at
    the top where they can choose different stages of checkpoints 
    (hiring_process, in_processing)
    given the stage, it will display in an ad_table the different 
    checkpoints on the left column
    and the number of people who have and have not completed this 
    checkpoint in the right column
    the numbers will be hyperlinks to one_checkpoint_progress.tcl 

    @param dim_stage

    @author unkown
    @cvs-id checkpoint-progress.tcl,v 1.4.2.9 2000/09/22 01:38:46 kevin Exp
} {
    {dim_stage "all"}
}

## this part will create the dimensional sliders at the top

set stages_sql "select distinct stage from im_employee_checkpoints"
set stages_dimensional {dim_stage "Stage" all }
set stages_list [list]

db_foreach dimensional_slider_statement $stages_sql {
    lappend stages_list [list $stage $stage {}]            
}

lappend stages_list [list all "all" {}]
lappend stages_dimensional $stages_list

if {[string compare $dim_stage "all"] == 0} {
    set where_clause ""
} else {
    set where_clause "where stage = :dim_stage"
}

set sql_query "select stage, checkpoint, checkpoint_id, 
               (select count(*) from im_emp_checkpoint_checkoffs, im_employees
               where im_emp_checkpoint_checkoffs.checkee(+) = im_employees.user_id
               and checkpoint_id(+) = i_emc.checkpoint_id
               and im_emp_checkpoint_checkoffs.checkee is NULL) as missing
               from im_employee_checkpoints i_emc $where_clause"

set bind_vars [ns_set create]
ns_set put $bind_vars dim_stage $dim_stage]
set table_def {
    {stage "Stage" no_sort c}
    {checkpoint "Checkpoint" no_sort c} 
    {missing "# Missing" no_sort {<td><a href=[im_url_stub]/reports/checkpoint-one?checkpoint_id=[ns_urlencode $checkpoint_id]&checkpoint=[ns_urlencode $checkpoint]>$missing</a>}}
}

set context_bar [ad_context_bar [list "[im_url_stub]/reports/" "Reports"] "Missing Checkpoints"]

set return_html "[im_header "Missing Checkpoints"]
[ad_dimensional [list $stages_dimensional]]
[ad_table -bind $bind_vars stage_checkpoint_id $sql_query $table_def]
[im_footer]"

doc_return  200 text/html $return_html


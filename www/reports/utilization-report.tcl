# /www/intranet/reports/utilization-report.tcl

ad_page_contract {

    this page creates an employee utilization report. It displays  
    a table of projects for each employee including hours spent on
    that project

    @param group_id Limits the report to the specified group

    @author umathur@arsdigita.com
    @creation-date 6/20/2000
    @cvs-id utilization-report.tcl,v 1.1.2.2 2000/09/22 01:38:47 kevin Exp

} {
    { group_id {[im_employee_group_id]} }
    { start_date "" }
    { end_date "" }
}

if {[empty_string_p $end_date]} {
    set end_date [db_string select_max_start_block \
	    "select max(start_block) from im_start_blocks where start_block < sysdate"]
}

if {[empty_string_p $start_date]} {
    set start_date [db_string select_start_date \
	    "select max(start_block) from im_start_blocks where start_block < to_date('$end_date','YYYY-MM-DD')"]
}

set sql_query "select distinct '$start_date' as start_date, '$end_date' as end_date, first_names||' '||last_name as name, users.user_id, 
total_non_compliant_hours(users.user_id, to_date('$start_date','YYYY-MM-DD'), to_date('$end_date','YYYY-MM-DD')) as non_compliant,
total_normalized_hours(users.user_id, to_date('$start_date','YYYY-MM-DD'), to_date('$end_date','YYYY-MM-DD')) as normalized,
total_hours(users.user_id, to_date('$start_date','YYYY-MM-DD'), to_date('$end_date','YYYY-MM-DD')) as hours from users 
where users.user_id in (select user_id from user_group_map where group_id = $group_id) 
"

set table_def {
    {name "Employee" {} {<td><a href=utilization?[export_url_vars user_id start_date end_date]>$name</a></td>}}
    {hours "Hours" {} l}
    {normalized "Normalized Hours" {} l}
    {non_compliant "Noncompliant Hours" {} l}
}

set table_string [ad_table -Ttable_extra_html {width=100% cellpadding=0 cellspacing=2 border=0} select_user_info $sql_query $table_def]

set context_bar [ad_context_bar [list "[im_url_stub]/reports/" "Reports"] "Utilization Report"]

set return_html "
[im_header "Utilization Report"]
<form method=get action=utilization-report>
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr bgcolor=eeeeee>
<th>Team</th>
<th>From</th>
<th>Until</th>
</tr>
<tr>
<td align=center><select name=group_id>
<option value=[im_employee_group_id]>All
[db_html_select_value_options -select_option $group_id team_select "select ug.group_id, ug.group_name
           from user_groups ug
          where ug.parent_group_id = [im_team_group_id]"]
</select></td>
<td>
<select name=start_date>
[db_html_select_value_options -select_option $start_date start_block_select "select to_char(start_block, 'Month DD, YYYY'), start_block from im_start_blocks"]
</select>
</td>
<td>
<select name=end_date>
[db_html_select_value_options -select_option $end_date start_block_select "select to_char(start_block, 'Month DD, YYYY'), start_block from im_start_blocks"]
</select>
</td>
</tr>
<tr>
<td colspan=3>
<center><input type=submit value=\"GO\"></center>
</td>
</tr>
</table>
</form>
$table_string
[im_footer]
"

doc_return  200 text/html $return_html




# /www/intranet/reports/birthdays.tcl

ad_page_contract {
    Displays employee birthdates (or those missing birthdays)

    @param group_id
    @param orderby
    @param missing_birthday_p

    @author mbryzek@arsdigita.com
    @creation-date Fri Jun 23 19:27:51 2000

    @cvs-id birthdays.tcl,v 1.3.2.7 2000/09/22 01:38:45 kevin Exp
} {
    { group_id:integer "0" }
    { orderby "month_day" }
    { missing_birthday_p "f" }
}

set criteria [list]

if { $missing_birthday_p == "t" } {
    lappend criteria " birthdate is null "
    set bday_control "<a href=birthdays?[export_ns_set_vars url [list missing_birthday_p]]>View employees who have entered their birthdates</a>"

} else {
    lappend criteria " birthdate is not null "
    set bday_control "<a href=birthdays?missing_birthday_p=t&[export_ns_set_vars url [list missing_birthday_p]]>View employees who have NOT entered their birthdates</a>"
}

if { ![empty_string_p $group_id] && $group_id != 0 } {
    lappend criteria "ad_group_member_p(emp.user_id,'$group_id') = 't'"
}

set where_clause [join $criteria "\n        and "]

set office_list [list "0" "All"]
set sql_query "select group_id as id, group_name as name
               from user_groups 
               where parent_group_id = [im_office_group_id]"
db_foreach group_id_name_statement $sql_query {
    lappend office_list $id $name
}

set office_slider [im_slider group_id $office_list]


set table_def { 
    {full_name "Employee" \
	    {full_name $order} \
	    {<td><a href=../employees/payroll-edit?[export_url_vars user_id]>$full_name</a></td>}}
    {month_day "Month/Day" \
	    {month_day $order} \
	    {<td align=center>$month_day_pretty</td>}}
    {year "Year" \
	    {year $order} \
	    {<td align=center>$year_pretty</td>}}
}

set sql_query "select emp.last_name || ', ' || emp.first_names as full_name, emp.user_id, 
                to_char(emp.birthdate,'YYYY') as year,
                nvl(to_char(emp.birthdate,'YYYY'),'&nbsp;') as year_pretty,
                to_char(emp.birthdate,'MM-DD') as month_day,
                nvl(to_char(emp.birthdate,'Month DD'),'&nbsp;') as month_day_pretty
	        from im_employees_active emp 
                where $where_clause
	        [ad_order_by_from_sort_spec $orderby $table_def]"

if { $missing_birthday_p == "t" } {
    set page_info "<ul>"
    db_foreach employees_missing_birthdays $sql_query {
	append page_info "  <li> <a href=[im_url_stub]/users/view?[export_url_vars user_id]>$full_name</a>\n\n"
    } if_no_rows {
	append page_info "  <li> All employees have entered birthday information\n"
    }
    append page_info "</ul>\n"

} else {
    set page_info [ad_table -Torderby $orderby -Ttable_extra_html "border=1 cellspacing=2 cellpadding=3" employee_birthday $sql_query $table_def]
}

set context_bar [ad_context_bar [list [im_url_stub]/reports/ Reports] "Birthdays"]

set page_body "
[im_header "Employee Birthdays"]

<table width=\"100%\">
 <tr>
  <td valign=top align=right>Office:</td>
  <td valign=top align=left>$office_slider</td>
  <td valign=top align=right>$bday_control</td>
 </tr>
</table>

<p>

<blockquote>
$page_info
</blockquote>

[im_footer]
"

doc_return  200 text/html $page_body




















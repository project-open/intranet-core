# /www/intranet/reports/exception-missing-info.tcl

ad_page_contract {

    gives a list of people who are missing entries for a given field
    May 5, 2000 we will add a convenient way to update information. We will create
    a select list from the database query of office names and group names. 
    we will present a separate checklist for every user, and let the users submit
    this form that will update information for all indicated users.
    teadams had to finish this file and the submit page
    on 5/11 because a) she needed to use it b) she checked it out

    @author umathur@arsdigita.com 
    @creation-date May 4, 2000
    @cvs-id exception-missing-info.tcl,v 1.11.2.12 2000/09/22 01:38:46 kevin Exp
} {
    {exception_type "start_date"}
}

proc local_format_other_input { option user_id } {
    switch $option {
	"" { return "none" }
	"text" { return "<input type=text name=other.$user_id size=20>" }
	"date" { return "<input type=text name=other.$user_id size=12 maxlength=10> (YYYY-MM-DD)" }
	"new_category" { return "<font size=-1>or enter a new category</font><br><input type=text name=other.$user_id size=20  maxlength=50>"}
	"user-admin-link" { return "<font size=-1><a href=[im_url_stub]/employees/admin/view?[export_url_vars user_id] target=_new>user admin page</a></font>" }
	"supervisor-link" { return "<font size=-1><a href=[im_url_stub]/employees/admin/update-supervisor?[export_url_vars user_id] target=_new>other supervisor</a></font>" }
    }
    return "&nbsp;"
}

set dimensional {
    {exception_type "Type of Exception" start_date {
	{start_date "Start Date" {} }
	{source_id "Source" {} }
	{qualification_id "Qualification Process" {} }
	{department_id "Department" {} }
	{salary "Salary Information" {} }
	{supervisor_id "Supervisor" {} }
	{experience_id "Experience" {} }
	{original_job_id "Original Position" {} }
	{current_job_id "Current Position" {} }
    }
}   }

set parent_group_id 0


#make the option list for this exception_type
set option_list_html "<option value=no_update>Update this User</option>"

# Specify the type of other option (one of new_category, date, text)
set other_option ""

if {[string compare $exception_type "start_date"] == 0} {

    set other_option date

    append option_list_html [ad_db_optionlist start_date_statement "select 'today - ' || to_char(trunc(sysdate),'Mon FMDDFM') as item, trunc(sysdate) as value from dual 
    UNION
    select 'tomorrow - '||to_char(trunc(sysdate+1),'Mon FMDDFM') as item, trunc(sysdate+1) as value from dual
    UNION
    select 'next week - '||to_char(trunc(sysdate+7),'Mon FMDDFM') as item, trunc(sysdate+7) as value from dual 
    UNION
    select 'yesterday - '||to_char(trunc(sysdate-1),'Mon FMDDFM') as item, trunc(sysdate-1) as value from dual 
    UNION
    select 'last week - '||to_char(trunc(sysdate-7),'Mon FMDDFM') as item, trunc(sysdate-7) as value from dual 
    order by value" ]

} elseif {[string compare $exception_type "source_id"] == 0} {

    set category_type "Intranet Hiring Source"
  
} elseif {[string compare $exception_type "qualification_id"] == 0} {  

    set category_type "Intranet Qualification Process"

} elseif {[string compare $exception_type "department_id"] == 0} {

    set category_type "Intranet Department"

} elseif {[string compare $exception_type "salary"] == 0} {

    set other_option text

    append option_list_html [ad_db_optionlist salary_statement \
        "select distinct '$'||to_char(info.salary,'999G999G999G999G999') as item, info.salary as value 
         from im_employees info
         where info.salary is not null
         order by item"]

} elseif {[string compare $exception_type "supervisor_id"] == 0} {  

    set other_option "supervisor-link"

    append option_list_html [ad_db_optionlist supervisor_id_statement \
        "select distinct u.first_names||' '||u.last_name as item, u.user_id as value 
         from users u, im_employees info
         where info.supervisor_id=u.user_id"]

} elseif {[string compare $exception_type "experience_id"] == 0} {

    set category_type "Intranet Prior Experience"

} elseif {[string compare $exception_type "original_job_id"] == 0} {  

    set category_type "Intranet Job Title"

} elseif {[string compare $exception_type "current_job_id"] == 0}  {

    set category_type "Intranet Job Title"

} else {

    ad_returnredirect exception-missing-info
    return
}

if { [exists_and_not_null category_type] } {
    set other_option new_category
    set bind [ns_set create]
    ns_set put $bind category_type $category_type

    append option_list_html [ad_db_optionlist -bind $bind category_statement \
         "select c.category as item, c.category_id as value 
	  from categories c
	  where c.category_type=:category_type
	  order by lower(item)"]
}



set table_def {
    {name "User Name" no_sort \
	    {<td><a href=[im_url_stub]/employees/admin/view?user_id=$user_id>$name</a></td> }}
    { user_id "Modify This User" no_sort \
	    {<td><select name=user.$user_id>$option_list_html</select></td> }}
    { other_option "Other value" no_sort \
	    {<td>[local_format_other_input $other_option $user_id]</td>} }
}

set sql_query "select last_name || ', ' || first_names as name,
                      im_employees.user_id 
               from im_employees, users 
               where im_employees.user_id = users.user_id
               and im_employees.$exception_type is NULL
               and ad_group_member_p ( im_employees.user_id, [im_employee_group_id] ) = 't'
               order by lower(name)"

set context_bar [ad_context_bar [list [im_url_stub]/reports/ Reports] "Exception Report"]
append html_page "[im_header "Missing $exception_type info"]
[ad_dimensional $dimensional]
<form action=exception-missing-info-2 method=post>
[export_form_vars exception_type other_option category_type]
[ad_table -Textra_vars {option_list_html other_option} option_list_statement $sql_query $table_def]
<p><center><input type=submit value=\"Update Information\"></center>
</form>
[im_footer]"

doc_return  200 text/html $html_page

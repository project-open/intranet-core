# /www/intranet/reports/department-reports.tcl

ad_page_contract {
    list of employees by department
    @param none
    @author teadams@arsdigita.com 
    @creation-date June 11, 2000

    @cvs-id department-report.tcl,v 1.4.2.6 2000/09/22 01:38:46 kevin Exp
} {
}

# User_id already verified by the /intranet filters
set current_user_id [ad_get_user_id]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set text ""

set sql_query "select users.user_id, users.last_name || ', ' || users.first_names as name, 
                      (select  im_job_titles.job_title  as current_job_option 
                       from im_employees, im_job_titles 
                       where im_employees.user_id = users.user_id 
                             and im_job_titles.job_title_id = im_employees.current_job_id) 
                       as job,
                      (select  im_departments.department 
                       from im_employees, im_departments 
                       where im_employees.user_id = users.user_id 
                             and im_departments.department_id = im_employees.department_id) 
                       as department, start_date, percentage_time
               from users, im_employees info, im_employee_percentage_time
               where  users.user_id = im_employee_percentage_time.user_id
                      and users.user_id = info.user_id(+) 
                      and im_employee_percentage_time.start_block = (select min(start_block) 
                                                                     from im_start_blocks 
                                                                     where start_block > sysdate)
                      and percentage_time > 0
               order by department,  upper(name), name"


set department_prev ""
set dept_total_percentage 0
set dept_string ""
set total_percentage 0

db_foreach  department_statement $sql_query {
    if {$department_prev != $department && ![empty_string_p $department_prev]} {
	append text "<h4>$department_prev - [expr $dept_total_percentage/100] FTEs</h4> 
<ul>$dept_string</ul>"
        set total_percentage [expr $total_percentage + $dept_total_percentage]
        set dept_total_percentage 0
	set dept_string ""
    }
    
    if { $user_admin_p } {
	# Offer link to view employee information
	set user_id_link "<a href=\"[im_url_stub]/employees/admin/view?[export_url_vars user_id]\">$user_id</a>"
    } else {
	set user_id_link "$user_id"
    }
    append dept_string " <li> $name ($user_id_link), $percentage_time% $job,  $start_date"
    

    set dept_total_percentage [expr $dept_total_percentage + $percentage_time]
 
    append dept_string "<br>"
    set department_prev $department
}

append text "<h4>$department - [expr $dept_total_percentage/100] FTEs</h4> 
<ul>$dept_string</ul>
"
set total_percentage [expr $total_percentage + $dept_total_percentage]

db_release_unused_handles

set context_bar [ad_context_bar [list "[im_url_stub]/reports/" Reports] "Department report"]

set html_page "
[im_header "Department Report"]

The following lists employees by department along with their percentage
of a full-employee, job title and start date.
If an employee works in multiple departments, the primary department
is listed.
<p>
We have [util_commify_number [expr $total_percentage/100]] FTEs in the following departments:

$text
[im_footer]
"

doc_return  200 text/html $html_page

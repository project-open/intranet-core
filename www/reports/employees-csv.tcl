# /www/intranet/reports/employees-csv.tcl

ad_page_contract {
    list of current and future employees, their
    start date, department, and 
    @param none
    @author teadams@arsdigita.com 
    @creation-date May 15, 2000

    @cvs-id employees-csv.tcl,v 1.2.2.7 2000/09/22 01:38:46 kevin Exp
} {
}
set text ""


set sql_query "select users.user_id, users.last_name || ', ' || users.first_names as name, 
                    (select im_hiring_sources.source  as source 
                     from im_employees, im_hiring_sources 
                     where im_employees.user_id = users.user_id 
                           and im_hiring_sources.source_id = im_employees.source_id) 
                    as source,
                    (select  im_job_titles.job_title  as current_job_option 
                     from im_employees, im_job_titles 
                     where im_employees.user_id = users.user_id 
                           and im_job_titles.job_title_id = im_employees.current_job_id) 
                    as job,
                    (select  im_departments.department 
                     from im_employees, im_departments 
                     where im_employees.user_id = users.user_id 
                           and im_departments.department_id = im_employees.department_id) 
                    as department, start_date
	       from users, im_employees info, user_group_map ugm
	       where users.user_id = ugm.user_id
	             and ugm.group_id = [im_employee_group_id]
		     and users.user_id = info.user_id(+) 
	       order by department, upper(name), name"

db_foreach employee_information $sql_query {
    append text "\"$name\",\"$start_date\",\"$department\",\"$job\"\n\n" 
}



doc_return  200 text "$text"








# /www/intranet/reports/report.tcl

ad_page_contract {

    this page creates an employee count report. It displays a history
    of the number of employees    this history is split by Office,
    Team, Original Job, Current Job, Source and Prior Experience. The
    query here is mildly complicated. Here is a summary:

    we first select the names of the different column headings depending
    on the dimensional slider. Then we use this query to form clauses for the 
    select in the main query. While reading the first query, we also set up
    the columns for ad_table. 

    @author umathur@arsdigita.com 
    @creation-date May 1, 2000
    @cvs-id report.tcl,v 1.18.2.11 2000/09/22 01:38:47 kevin Exp
} {
    { orderby        "start_block*" }
    { view_type      "office" }
    { date_range     "month_1" }
    { date_group_by  "month" }
    { count_type     "all" }
}


# set defaults for variables

if {[regexp {\*} $orderby match order]} {
    set order "order_date desc"
} else {
    set order "order_date asc"
}

if {$count_type == "new"} {
    # this is pretty tricky; we want to limit this to users whose
    # first entry in the allocation table is that start_block

    set count_where_clause "im_employees.user_id in (select 
user_id from im_employee_percentage_time imept1 where 
imept1.start_block = imsb.start_block
and imept1.start_block = (select min(start_block) from
im_employee_percentage_time imept2 where 
imept2.user_id = imept1.user_id))"
}

# create dimensional slider. Not all SQL included since the query is too complex 
# to mash together with the standard tool
# in particular, the subselects must be specified within the loop of another query

set dimensional { 
    {date_group_by "Group Date By" month {
	{week "Week" {} }
	{month "Month" {} }}
    }
    {date_range "Future Date Range" month_1 {
	{now "Now" {}}
	{month_1 "One month" {}}
	{month_3 "Three months" {}}} 
    }
    {view_type "View By" office {
        {office "Office" {} }
	{team "Team" {}}
	{department_id "Department" {} }
	{original_job_id "Original Job" {} }
	{current_job_id "Current Job" {} }
	{source_id "Source" {} }
	{prior_experience "Prior Experience" {}} }    
    }
    {count_type "Count Employees" all {
	{all "Total FTEs" {} }
	{new "New employees" {where $count_where_clause}}}
    }
}

#here we set some variables based on dimensional settings
if {[string compare $date_range "month_1"] == 0} {
    set date_future_length 30
} elseif {[string compare $date_range "month_3"] == 0} {
    set date_future_length 90
} elseif {[string compare $date_range "month_6"] == 0} {
    set date_future_length 182
} elseif {[string compare $date_range "month_12"] == 0} {
    set date_future_length 365
} else {
    set date_future_length 0
}

if {[string compare $date_group_by "month"] == 0} {

    set date_group_by_list {"to_char(trunc(start_block, 'MONTH'), 'fmMonth, YYYY')" "trunc(start_block, 'YYYY'), trunc(start_block, 'MONTH')"}
} else {
    set date_group_by_list {"to_char(start_block, 'fmMonth DD, YYYY')" "start_block"}
}

if {[string compare $count_type "new"] == 0} {
    set grouping_expr "sum"
} else {
    set grouping_expr "avg"
}

# queries to get column headings, and values for final query
set office_info_sql "select im_offices.group_id as group_id, group_name, short_name from im_offices, user_groups
                      where im_offices.group_id = user_groups.group_id
                        and parent_group_id = [im_office_group_id]
                   order by lower(group_name)
"

set team_info_sql "select group_id, group_name, short_name from user_groups
                    where parent_group_id = [im_team_group_id]
                 order by lower(group_name)
"

set current_job_id_info_sql "select distinct current_job_id as group_id, 
                                    im_job_titles.job_title as group_name, 
                                    current_job_id as short_name
                              from im_employees, im_job_titles
                             where im_employees.current_job_id = im_job_titles.job_title_id"

set original_job_id_info_sql "select distinct current_job_id as group_id, 
                                     im_job_titles.job_title as group_name, 
                                     current_job_id as short_name
                               from im_employees, im_job_titles
                              where im_employees.current_job_id = im_job_titles.job_title_id"

set source_info_sql "select distinct im_hiring_sources.source_id as group_id,
                            source as group_name, 
                            im_hiring_sources.source_id as short_name
                      from im_hiring_sources, im_employees
                     where im_employees.source_id = im_hiring_sources.source_id"

set experience_info_sql "select distinct im_prior_experiences.experience_id as group_id, 
                                experience as group_name, 
                                im_prior_experiences.experience_id as short_name
                      from im_prior_experiences, im_employees
                     where im_employees.experience_id = im_prior_experiences.experience_id"

set department_info_sql "select distinct im_departments.department_id as group_id, 
                                department as group_name, 
                                im_departments.department_id as short_name
                      from im_departments, im_employees
                     where im_departments.department_id = im_employees.department_id"

# set default query. 

if {[string compare $view_type "office"] == 0} {
    set this_query $office_info_sql
} elseif {[string compare $view_type "team"] == 0} {
    set this_query $team_info_sql
} elseif {[string compare $view_type "current_job_id"] == 0} {
    set this_query $current_job_id_info_sql
} elseif {[string compare $view_type "original_job_id"] == 0} {
    set this_query $original_job_id_info_sql
} elseif {[string compare $view_type "source_id"] == 0} {
    set this_query $source_info_sql
} elseif {[string compare $view_type "prior_experience"] == 0} {
    set this_query $experience_info_sql
} elseif {[string compare $view_type "department_id"] == 0} {
    set this_query $department_info_sql
} else {
    set this_query $office_info_sql
}

# here is the basic stuff where we set the beginning of the query, and the first column of the table
# as we loop through with getrow, we will add to the query and the table_def
set report_count_sql "select min(start_block) as order_date, 
                             [lindex $date_group_by_list 0] as start_block,
                             $grouping_expr (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
                                                    from im_employee_percentage_time, im_employees
                                                   where start_block = imsb.start_block  [ad_dimensional_sql $dimensional where]
                                                     and im_employees.user_id = im_employee_percentage_time.user_id),0)) as total"

set table_def {
    {start_block "Beginning" {order_date $order} l}
    {total "Total" no_sort c}
}


# here we will loop through each of the rows in the select query.
# This data from the db will be used to generate the query that will
# actually create the report. Because of the many different tables,
# and changing column headers, we must first query to see which columns
# we want and then fill in the sql for each column
# the row is selected as a<name> since sometime the name is a number.

set count 0
db_foreach this_query_statement $this_query {
   incr count
   set temp_list [list]


   #create dynamic valid short name b/c the short_name from the query could contains invalid characters (i.e. $%@....)
   set short_name short_name_$count

    if {[string compare $view_type "office"] == 0} {
	# if people are in more than one office, we don't want to count
	# them twice.  Therefore, we label all office that are not
	# the user's primary group "secondary" and don't put them in
	# this count.

	set select_clause ",
        $grouping_expr 
        (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
              from im_employee_percentage_time, user_group_map, im_employees
              where start_block = imsb.start_block  [ad_dimensional_sql $dimensional where]
                and user_group_map.user_id = im_employee_percentage_time.user_id
                and user_group_map.user_id = im_employees.user_id
                and im_employees.user_id = im_employee_percentage_time.user_id
                and user_group_map.group_id in (select group_id 
                                                  from user_groups 
                                                 where parent_group_id = [im_office_group_id]) 
                and user_group_map.group_id = $group_id
                and (role <> 'secondary' or role is null)),0))
        as [string tolower "a$short_name"] "	

    }   elseif {[string compare $view_type "team"] == 0} {

	# if people are in more than one team, we don't want to count
	# them twice.  Therefore, we label all office that are not
	# the user's primary group "secondary" and don't put them in
	# this count.

	set select_clause ",
        $grouping_expr 
        (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
              from im_employee_percentage_time, user_group_map, im_employees
             where start_block = imsb.start_block  [ad_dimensional_sql $dimensional where]
               and user_group_map.user_id = im_employee_percentage_time.user_id
               and user_group_map.user_id = im_employees.user_id
               and im_employees.user_id = im_employee_percentage_time.user_id
               and user_group_map.group_id in (select group_id 
                                                 from user_groups 
                                                where parent_group_id = [im_team_group_id]) 
               and user_group_map.group_id = $group_id
               and (role <> 'secondary' or role is null)),0))
        as [string tolower "a$short_name"]\n "

    }    elseif {[string compare $view_type "department_id"] == 0} {
	set select_clause ",
        $grouping_expr 
        (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
                from im_employee_percentage_time, im_employees
               where start_block = imsb.start_block
                     [ad_dimensional_sql $dimensional where]
                 and im_employees.user_id = im_employee_percentage_time.user_id
                 and im_employees.department_id = $group_id),0))
        as [string tolower "a$short_name"]\n "

  }  elseif {[string compare $view_type "current_job_id"] == 0} {
	set select_clause ",
        $grouping_expr 
        (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
                from im_employee_percentage_time, im_employees
               where start_block = imsb.start_block
                     [ad_dimensional_sql $dimensional where]
                 and im_employees.user_id = im_employee_percentage_time.user_id
                 and im_employees.current_job_id = $group_id),0))
        as [string tolower "a$short_name"]\n "

    } elseif {[string compare $view_type "original_job_id"] == 0} {
	set select_clause ",
        $grouping_expr 
        (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
                from im_employee_percentage_time, im_employees
               where start_block = imsb.start_block
                     [ad_dimensional_sql $dimensional where]
                 and im_employees.user_id = im_employee_percentage_time.user_id
                 and im_employees.original_job_id = $group_id),0))
        as [string tolower "a$short_name"]\n "

    }  elseif {[string compare $view_type "source_id"] == 0} {
	set select_clause ",
        $grouping_expr 
        (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
              from im_employee_percentage_time, im_employees
              where start_block = imsb.start_block
                    [ad_dimensional_sql $dimensional where]
                and im_employees.user_id = im_employee_percentage_time.user_id
                and im_employees.source_id = $group_id),0))
        as [string tolower "a$short_name"]\n "

    }  elseif {[string compare $view_type "prior_experience"] == 0} {
	set select_clause ",
        $grouping_expr 
        (nvl((select sum(((nvl(im_employee_percentage_time.percentage_time,100))*.01)) 
                from im_employee_percentage_time, im_employees
               where start_block = imsb.start_block   
                     [ad_dimensional_sql $dimensional where]
                 and im_employees.user_id = im_employee_percentage_time.user_id
                 and im_employees.experience_id = $group_id),0))
        as [string tolower "a$short_name"]\n "
    }
    append report_count_sql $select_clause
 
    lappend temp_list [string tolower "a$short_name"]
    lappend temp_list $group_name
    lappend temp_list "no_sort"
    lappend temp_list "c"
    lappend table_def $temp_list
}

append report_count_sql "\n from im_start_blocks imsb \n where start_block < (sysdate + $date_future_length) \n "
append report_count_sql "group by [lindex $date_group_by_list 1]"
append report_count_sql "[ad_order_by_from_sort_spec $orderby $table_def]"

set context_bar [ad_context_bar [list [im_url_stub]/reports/ Reports] "Employee Report"]

set return_html "[im_header "Employee statistics"] 
[ad_dimensional $dimensional]"

# if group_id exists, mean there is rows and report_count_sql is a complete sql statement
# if group_id does not exists, mean there is no  rows and report_count_sql is incomplete statement
if [exists_and_not_null group_id] {
    set bind_vars [ns_set create]
    ns_set put $bind_vars group_id $group_id
    append return_html [ad_table -Ttable_extra_html {border=1 width=100%} -Torderby $orderby \
                        -bind $bind_vars report_count_statement $report_count_sql  $table_def]
} else {
    append return_html [ad_table -Ttable_extra_html {width=100%} -Torderby $orderby \
                        dummy_statement "select sysdate from dual where 1=0"  $table_def]
   
}
append return_html [im_footer]
doc_return  200 text/html $return_html


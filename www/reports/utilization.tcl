# /www/intranet/reports/utilization.tcl

# this page uses ns_write on purpose, as we want
# it to stream to the browser

ad_page_variables {

    {ColValue.start_date.day {}} 
    {ColValue.end_date.day {}} 
    { start_date "" }
    { end_date "" }
    { group_id "" }
    { department_id "" }
    {csv_p "f"}

}

if { 0 } {
    # This is the ad_page_contract_block

    this page creates an employee utilization report. It displays a
    table of projects for each employee including hours spent on that
    project refined this query to find noncompliant.
    
    Unfortunately, since we wanted totals, we could not use
    ad_table. (maybe I just didn't know how) this means there is a lot of
    "reinventing of the wheel" in this file.
    
    note that we round off for pretty display
    we keep the number to 2 decimal places for better accuracy

    @param ColValue.start_date.day Day we start the report on
    @param ColValue.end_date.day Day we end the report on
    @param group_id Integer ID of the group of users to includes in this report
    @param csv_p String - when set to "t", we return a csv file for
    easy spreadsheet import

    @author Uday Mathur (umathur@arsdigita.com)
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date June 20, 2000
    @cvs-id utilization.tcl,v 1.41.2.2 2000/09/22 01:38:47 kevin Exp
}

proc local_format_number { number } {
    upvar csv_p csv_p
    if { $csv_p == "t" } {
	return [expr round($number)]
    } 
    return [util_commify_number [expr round($number)]]
}


# We reuse this procedure in two places...
proc local_utilization_format_one_row {} {
    uplevel {
	set total_last_non_compliant [expr $total_last_non_compliant + $last_non_compliant]
	set total_normalized_and_noncompliant [expr $normalized_hour_count+$last_non_compliant]
	if { $total_normalized_and_noncompliant == 0 } {
	    set total_normalized_and_noncompliant 1
	}
	
	set local_hour_count [expr round ($hour_count)]
	set local_normalized_hour_count [expr round ($normalized_hour_count)]
	set local_billable_hour_count [expr round ($billable_hour_count)]
	set local_unbillable_hour_count [expr round ($unbillable_hour_count)]
	set local_last_non_compliant [expr round ($last_non_compliant)]
	set local_utilization_percent [expr round((100.0 * $billable_hour_count)/$total_normalized_and_noncompliant)]
	set local_noncompliant_percent [expr round((100.0 * $last_non_compliant)/$total_normalized_and_noncompliant)]
	
	ns_write  "
<tr bgcolor=eeeeee>
  <td align=right><b>Total: $last_max_normalized_per_user</b></td> 
  <td>$local_hour_count</td>
  <td>$local_normalized_hour_count</td>
  <td>$local_billable_hour_count</td>
  <td>$local_unbillable_hour_count</td>
  <td>$local_last_non_compliant</td>
  <td>$local_utilization_percent%</td>
  <td>$local_noncompliant_percent%</td>
</tr>

"
        append csv_data ",Total: $last_max_normalized_per_user,$local_hour_count,$local_normalized_hour_count,$local_billable_hour_count,$local_unbillable_hour_count,$local_last_non_compliant,$local_utilization_percent,$local_noncompliant_percent\n"

    }
}

set db [ns_db gethandle]

#we add/subtract one to start and endblock to accomodate Jim Jordan's request that weeks start on a monday
#this has been changed to have weeks go from sunday to saturday like the rest of the intranet/ACS
# we subtract one from the end date so it is sunday -> saturday
 
#we add a bit of sensitivity to this. if they select the next sunday (a start_block) then we do not jump to the next block, we just back up one day. 


if { [empty_string_p $end_date] } {
    if {[catch {set end_date [validate_ad_dateentrywidget end_date end_date [ns_conn form]]} errmsg]} { 
	set end_date [database_to_tcl_string $db "select max(start_block) from im_start_blocks where start_block < sysdate"]
    } else {
	set end_date [database_to_tcl_string $db "select min(start_block) from im_start_blocks where start_block >= to_date('$end_date', 'YYYY-MM-DD')"]
    }    
}

if { [empty_string_p $start_date] } {
    if {[catch {set start_date [validate_ad_dateentrywidget start_date start_date [ns_conn form]]} errmsg]} { 
	set start_date [database_to_tcl_string $db "select max(start_block) from im_start_blocks where start_block < to_date('$end_date','YYYY-MM-DD')"]
    } else {
	set start_date [database_to_tcl_string $db "select max(start_block) from im_start_blocks where start_block <= to_date('$start_date','YYYY-MM-DD')"]
    }
}

# We need to flag intern/short-term employees. These are identified by the
# comma-separated list of job titles in the ShortTermJobTitles parameter.
# We create an array of the job titles for easy lookup in our loop below
foreach title [split [ad_parameter ShortTermJobTitles intranet ""] ","] {
    set short_term_job_titles([string toupper [string trim $title]]) 1
}


# We choose not to build up one string to return at the end because this report
# can take a very long time. It's better to hang on to one handle and not worry 
# about people double-clicking in fear that the report is hung

if {[empty_string_p $group_id] && ![empty_string_p $department_id]} {
    set group_id [im_employee_group_id]
}

set context_bar [ad_context_bar [list "[im_url_stub]/reports/" "Reports"] "Utilization Report"]

ReturnHeaders
ns_write " [im_header "Employee Utilization Detail Report"]
<form method=get action=utilization>
Start Date: 
[ad_dateentrywidget start_date $start_date]
End Date: 
[ad_dateentrywidget end_date $end_date]
<br>
Team: 
<select name=group_id>
<option value=\"\"> -- Please select a team -- 
[ad_db_optionlist $db "select group_name, group_id
           from user_groups 
          where parent_group_id = [im_team_group_id]" $group_id]
<option value=[im_employee_group_id][util_decode $group_id [im_employee_group_id] " selected" ""]>All
</select>

Department:<select name=department_id>
<option value=\"\" [util_decode $department_id "" "selected" ""]>All Departments 
[ad_db_optionlist $db "select department, department_id
           from im_departments" $department_id]
</select>
<input type=submit value=Submit>
<br>
"

if { [empty_string_p $group_id] } {
    # Let's force the user to pick a group and report dates...
    ns_write "
<b>Please select a team (above) for which to generate a report</b>
[im_footer]
"    
    return
}
if { ![empty_string_p $department_id] } {
    #in the case there is a department specified, we add a where clause 
    #to the query below
    set department_where_clause "and info.department_id = $department_id"
} else {
    set department_where_clause ""
}

# Offer link to download this report for import to things like excel
ns_write "<a href=utilization?csv_p=t&[export_url_vars start_date end_date group_id]>Download this report in CSV format</a><p>"


# Don't use ad_group_member_p here - it breaks everything and no rows are returned...
# We need to select out employee information (first name, last name, email, etc.)
# and hour information (such as the total hours worked, billable_p to determine billable or not, etc.)

if { $group_id == [im_employee_group_id] } {
    set group_subselect_sql ""
} else {
    set group_subselect_sql " and exists (select 1 from user_group_map ugm where ugm.group_id = $group_id and ugm.user_id=info.user_id) "
}


# Note that we check only those project on which the user has logged any hours
# (The first exists... clause of the where statement)

set sql "
select u.last_name || ', ' || u.first_names as name, u.email, u.user_id, 
       info.start_date as emp_start_date, info.termination_date as emp_termination_date, 
       im_departments.department as department,
       nvl(im_jobs.job_name,'No Job Title') as job_title,
       ug.group_name as project, ug.group_id as project_id,
       im_actual_hours_on_project(u.user_id, to_date('$start_date'), to_date('$end_date'), 'im_projects', proj.group_id) as hours,
       im_normalize_hours(u.user_id, to_date('$start_date'), to_date('$end_date'), 'im_projects', proj.group_id) as normalized,
       im_max_normalized_per_user(to_date('$start_date'), to_date('$end_date'), info.user_id) as max_normalized_per_user,
       nvl(proj.billable_type_id, 0) as billable_type_id
  from users u, im_employees info, user_groups ug, im_projects proj, im_jobs, im_departments
 where (exists (select 1 
                 from im_hours h 
                where h.on_which_table='im_projects' 
                  and h.on_what_id=proj.group_id 
                  and h.user_id=u.user_id 
                  and h.day between to_date('$start_date') and to_date('$end_date')+.9999)
   or 
   exists (select 1 from user_group_map where user_id = u.user_id and group_id = proj.group_id)
)
   $department_where_clause
   and ug.group_id = proj.group_id
   and u.user_id = info.user_id
   and info.current_job_id = im_jobs.type_id(+)
   and info.department_id = im_departments.department_id(+) $group_subselect_sql
order by lower(name), lower(ug.group_name)
"


set previous_name ""

#per user counters
set counter 0
set hour_count 0
set normalized_hour_count 0
set billable_hour_count 0
set unbillable_hour_count 0
set last_non_compliant 1
set last_max_normalized_per_user 0

#all user counters
set total_hour_count 0
set total_normalized_hour_count 0
set total_billable_hour_count 0
set total_unbillable_hour_count 0
set total_last_non_compliant 0

# Build up strings for cvs if we're displaying it
set csv_headers ""
set csv_data ""
set csv_totals ""

# For debugging:
# ns_write "<pre>$sql</pre>"

set selection [ns_db select $db $sql]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    # set billable with the client_type flag in the db, null goes to f
    if {  $billable_type_id == 0 } {
	set billable 0
	set unbillable $normalized
    } else {
	set unbillable 0
	set billable $normalized
    }

    # This is either the first row, or we've finished iterating all
    # over the projects for one user
    if { [string compare $previous_name $name] } {
	# This is not the first row so we have data.... do some computation
	if { ![empty_string_p $previous_name] } {	    
	    # The following call modifies table_string and csv_data in this environment
	    local_utilization_format_one_row 
	    ns_write "</table>\n\n"
        }

	#reset the per user counters
	set previous_name $name
	set hour_count 0
	set normalized_hour_count 0
	set billable_hour_count 0
	set unbillable_hour_count 0

	# Let's see if we need to flag this employee as a short-term one
	if { [info exists short_term_job_titles([string toupper [string trim $job_title]])] } {
	    set short_term_flag "<em>Short term employee</em>\n"
	} else {
	    set short_term_flag "$job_title - $department"
	}
	# Set up the cvs column headers
	if { $csv_p == "t" && [empty_string_p $csv_headers] } {
	    set csv_headers "Employee,Project,Actual Hours, Normalized Hours, Billable Hours, UnBillable Hours, Non-compliant, Utilization %,Non-compliant%"
	}

	set emp_working_dates "$emp_start_date"
	if { ![empty_string_p $emp_termination_date] } {
	    append emp_working_dates " - $emp_termination_date"
	}

	ns_write "
<table width=100%>\n
<tr bgcolor=cccccc>
  <th><a href=../hours/index?[export_url_vars user_id]&date=[ad_urlencode $start_date]>$name</a> &lt;<a href=mailto:$email>$email</a>&gt; $emp_working_dates $short_term_flag</th>
  <th>Actual</th>
  <th>Normalized</th>
  <th>Billable</th>
  <th>Unbillable</th>
  <th>Non-compliant</th>
  <th>Utilization %</th>
  <th>Non-compliant %</th>
</tr>

"
        append csv_data "\"$name, $emp_working_dates $short_term_flag\"\n"
    }
    
    #do a bunch of addition
    set hour_count [expr $hours + $hour_count]
    set normalized_hour_count [expr $normalized + $normalized_hour_count]
    set billable_hour_count [expr $billable + $billable_hour_count]
    set unbillable_hour_count [expr $unbillable + $unbillable_hour_count]
    set total_hour_count [expr $hours + $total_hour_count]
    set total_normalized_hour_count [expr $normalized + $total_normalized_hour_count]
    set total_billable_hour_count [expr $billable + $total_billable_hour_count]
    set total_unbillable_hour_count [expr $unbillable + $total_unbillable_hour_count]
    set last_non_compliant [expr $max_normalized_per_user - $normalized_hour_count]
    if { $last_non_compliant < 0 } {
	# Might be negative if we logged hours before our official start date
	set last_non_compliant 0
    }
    set last_max_normalized_per_user $max_normalized_per_user

    incr counter

    #print the actual row for this project
    
    if {$hours != 0} {
    ns_write "
<tr>
  <td><a href=../projects/view?group_id=$project_id>$project</a></td>
  <td>[expr round($hours)]</td>
  <td>[expr round($normalized)]</td>
  <td>[expr round($billable)]</td>
  <td>[expr round($unbillable)]</td>
</tr>
"

    regsub -all {\"} $project "" project_no_quotes
    append csv_data ",\"$project_no_quotes\",[expr round($hours)],[expr round($normalized)],[expr round($billable)],[expr round($unbillable)]\n"
    }
}

#writes the bottom of the table if there was any data
if { $counter == 0 } {
    # We have to check for zero here because we may enter the while loop above, only to find
    # that no hours were logged on the projects we look at
    set table_string "<b>No employees have logged their hours on projects during the time period selected</b>"
} else {
    # The following call modifies table_string and csv_data in this environment
    local_utilization_format_one_row 

    ns_write "

<tr bgcolor=cccccc>
  <td align=right><b>Overall Totals</b></td>
  <td>[local_format_number $total_hour_count]</td>
  <td>[local_format_number $total_normalized_hour_count]</td>
  <td>[local_format_number $total_billable_hour_count]</td>
  <td>[local_format_number $total_unbillable_hour_count]</td>
  <td>[local_format_number $total_last_non_compliant]</td>
  <td>[expr round (100.0*$total_billable_hour_count/($total_normalized_hour_count+$total_last_non_compliant))]% </td>
  <td>[expr round(100.0*$total_last_non_compliant/($total_normalized_hour_count+$total_last_non_compliant))]%</td>
</tr>

"
     append csv_totals "Overall Totals,,,[local_format_number $total_hour_count],[local_format_number $total_normalized_hour_count],[local_format_number $total_billable_hour_count],[local_format_number $total_unbillable_hour_count],[local_format_number $total_last_non_compliant],[expr round (100.0*($total_billable_hour_count/($total_normalized_hour_count+$total_last_non_compliant)))],[expr round(100.0*($total_last_non_compliant/($total_normalized_hour_count+$total_last_non_compliant)))]"
}


if { $csv_p == "t" } {
    doc_return 200 text/csv "
$csv_headers
$csv_data$csv_totals
"
    return
}


ns_db releasehandle $db

ns_write "</table>"

set table_def {
    {block "Block" {} l}
    {name "Employee" {} l}
    {project "Project" {} l}
    {hours "Hours" {} l}
}
    

ns_write "
[im_footer]
"


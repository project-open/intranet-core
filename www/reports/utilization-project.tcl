# /www/intranet/reports/utilization.tcl
 
# this page uses ns_write on purpose, as we want
# it to stream to the browser

ad_page_variables {

    {ColValue.start_date.day {}} 
    {ColValue.end_date.day {}} 
    { start_date "" }
    { end_date "" }
    { parent_group_id "" }
    {csv_p "f"}

}

if { 0 } {
    # This is the ad_page_contract_block

    this page creates a project utilization report. It displays a
    table of employees for each project including hours spent on that
    project 
    
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
    @cvs-id utilization-project.tcl,v 1.9.2.2 2000/09/22 01:38:47 kevin Exp
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
	set local_hour_count [expr round ($hour_count)]
	set local_normalized_hour_count [expr round ($normalized_hour_count)]
	ns_write  "
<tr bgcolor=eeeeee>
  <td align=right></td> 
  <td>$local_hour_count</td>
  <td>$local_normalized_hour_count</td>
  <td>$fte_sum</td>
</tr>

"
# THIS NEEDS TO BE FIXED
#        append csv_data ",Total: $last_max_normalized_per_user,$local_hour_count,$local_normalized_hour_count,$local_billable_hour_count,$local_unbillable_hour_count,$local_last_non_compliant,$local_utilization_percent,$local_noncompliant_percent\n"

    }
}

set db [ns_db gethandle]


#this has been changed to have weeks go from sunday to saturday like the rest of the intranet/ACS


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

set context_bar [ad_context_bar [list "[im_url_stub]/reports/" "Reports"] "Project Utilization Report"]

ReturnHeaders
ns_write " [im_header "Project Utilization Detail Report"]
<form method=get action=utilization-project>
Start Date: 
[ad_dateentrywidget start_date $start_date]
End Date: 
[ad_dateentrywidget end_date $end_date]
Project Parent: 
<select name=parent_group_id>
<option value=\"\"> -- Please select a project type -- 
[ad_db_optionlist $db "select group_name, group_id
           from user_groups 
          where group_id in (select distinct parent_id from im_projects)
          order by lower(group_name)" $parent_group_id]
<option value=0 [util_decode $parent_group_id 0 " selected" ""]>All
</select>
<input type=submit value=Submit>
<br>
"

if { [empty_string_p $parent_group_id] } {
    # Let's force the user to pick a group and report dates...
    ns_write "
<b>Please select a team (above) for which to generate a report</b>
[im_footer]
"    
    return
}

# Offer link to download this report for import to things like excel
ns_write "<a href=utilization?csv_p=t&[export_url_vars start_date end_date parent_group_id]>Download this report in CSV format</a><p>"


# Don't use ad_group_member_p here - it breaks everything and no rows are returned...
# We need to select out employee information (first name, last name, email, etc.)
# and hour information (such as the total hours worked, billable_p to determine billable or not, etc.)

if { $parent_group_id == 0 } {
    set group_select_sql ""
} else {
    set group_select_sql " and (proj.parent_id = $parent_group_id or proj.group_id = $parent_group_id)"
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
       trunc(nvl(im_fte_in_period(u.user_id, to_date('$start_date'), to_date('$end_date'), 'im_projects', proj.group_id),0),2) as fte,
       nvl(proj.billable_type_id, 0) as billable_type_id
  from users u, im_employees info, user_groups ug, im_projects proj, im_jobs, im_departments
 where (exists (select 1 
                 from im_hours h 
                where h.on_which_table='im_projects' 
                  and h.on_what_id=proj.group_id 
                  and h.user_id=u.user_id 
                  and h.day between to_date('$start_date') and to_date('$end_date')))
   and ug.group_id = proj.group_id
   and u.user_id = info.user_id
   and info.current_job_id = im_jobs.type_id(+)
   and info.department_id = im_departments.department_id(+) $group_select_sql
order by lower(ug.group_name), ug.group_id, lower(name)
"
# by adding group_id to the orderby we avoid problems like the ones we had
# with multiple projects showing up twice
# 

set previous_project ""

#per user counters
set counter 0
set hour_count 0
set normalized_hour_count 0
set fte_sum 0

#all user counters
set total_hour_count 0
set total_normalized_hour_count 0
set fte_total_sum 0

# Build up strings for cvs if we're displaying it
set csv_headers ""
set csv_data ""
set csv_totals ""

# For debugging:
# ns_write "<pre>$sql</pre>"

set selection [ns_db select $db $sql]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    # This is either the first row, or we've finished iterating all
    # over the projects for one user
    if { [string compare $previous_project $project] } {
	# This is not the first row so we have data.... do some computation
	if { ![empty_string_p $previous_project] } {	    
	    # The following call modifies table_string and csv_data in this environment
	    local_utilization_format_one_row 
	    ns_write "</table>\n\n"
        }

	#reset the per project counters
	set previous_project $project
	set hour_count 0
	set normalized_hour_count 0
	set fte_sum 0

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
  <th width=40%><a href=../projects/view?group_id=$project_id>$project</a></th>
  <th width=15%>Actual</th>
  <th width=15%>Normalized</th>
  <th width=30%>F.T.E.</th>
</tr>

"
        append csv_data "\"$name, $emp_working_dates $short_term_flag\"\n"
    }
    
    #do a bunch of addition
    set hour_count [expr $hours + $hour_count]
    set normalized_hour_count [expr $normalized + $normalized_hour_count]
    set fte_sum [expr $fte_sum + $fte]
    set total_hour_count [expr $hours + $total_hour_count]
    set total_normalized_hour_count [expr $normalized + $total_normalized_hour_count]
    set fte_total_sum [expr $fte_total_sum + $fte]

    incr counter

    #print the actual row for this project
    
    ns_write "
<tr>
  <td><a href=../hours/index?user_id=$user_id>$name</a></td>
  <td>[expr round($hours)]</td>
  <td>[expr round($normalized)]</td>
  <td>$fte</td>
</tr>
"

    regsub -all {\"} $project "" project_no_quotes
#    append csv_data ",\"$project_no_quotes\",[expr round($hours)],[expr round($normalized)],[expr round($billable)],[expr round($unbillable)]\n"
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
  <td>$fte_total_sum</td>
</tr>

"
#     append csv_totals "Overall Totals,,,[local_format_number $total_hour_count],[local_format_number $total_normalized_hour_count],[local_format_number $total_billable_hour_count],[local_format_number $total_unbillable_hour_count],[local_format_number $total_last_non_compliant],[expr round (100.0*($total_billable_hour_count/($total_normalized_hour_count+$total_last_non_compliant)))],[expr round(100.0*($total_last_non_compliant/($total_normalized_hour_count+$total_last_non_compliant)))]"
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
ns_write [im_footer]


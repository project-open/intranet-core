# /www/intranet/employees/admin/view.tcl
ad_page_contract {

    Adminstrative view of one employee

    @param user_id
    @param user_id_from_search
    @return_url

    @author (Michael Bryzek) mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id view.tcl,v 3.33.2.14 2000/09/22 01:38:35 kevin Exp
  

} {
    { user_id:integer "" }
    { user_id_from_search:integer "" }
    { return_url "" } 
}


proc im_local_format_group { user_id triple { return_url "" } } {
    set group_id [lindex $triple 0]
    set what_is_it [lindex $triple 1]
    set new_group_link [lindex $triple 2]
    set view_group_link [lindex $triple 3]

    set caller_user_id $user_id
    
    set thequery  \
	    "select ug.group_name, ug.group_id
               from user_groups ug
    where ad_group_member_p ( :caller_user_id , ug.group_id ) = 't'
                   and ug.parent_group_id = :group_id
              order by lower(ug.group_name)"

    set group_list ""
    
    db_foreach get_employee_info $thequery {

	if { ![empty_string_p $group_list] } {
	    append group_list ", "
	}
	
	if { ![empty_string_p $view_group_link] } {
	    append group_list " <a href=$view_group_link?[export_url_vars group_id]>$group_name</a>\n"
	} else {
	    append group_list " $group_name\n"
	}
    }
    if { [empty_string_p $group_list] } {
	append group_list "This person does not belong to a $what_is_it."
    }
    set option_list [db_html_select_value_options \
	    user_groups_select_options \
	    "select ug.group_id, ug.group_name
               from user_groups ug
              where ug.parent_group_id = :group_id
              order by lower(group_name)"]

    set html "<li>\n"
    if { ![empty_string_p $option_list] } {
	# Start the form here for nicer html display

	append html "
<form action=[im_url_stub]/member-add-3 method=post>
<input type=hidden name=user_id_from_search [export_form_value user_id]>
<input type=hidden name=role value=member>
<input type=hidden name=return_url value=\"$return_url\">
"
    }
    append html "[capitalize $what_is_it](s): $group_list"
    if { ![empty_string_p $new_group_link] } {
	append html " (<a href=\"$new_group_link\">add $what_is_it</a>)"
    }
    if { [empty_string_p $option_list] } {
	append html "<p>\n"
    } else {
	append html "
<br>Add to $what_is_it:
<select name=group_id>
$option_list
</select>
<input type=submit name=Add value=Add>
</form>"
    }
    
    return $html
}

ad_maybe_redirect_for_registration

if { [empty_string_p $user_id] } {
    if { [empty_string_p $user_id_from_search] } {
	ad_return_error "Missing user id" "We weren't able to determine for what user you want information."
	return
    } else {
	set user_id $user_id_from_search
    }
}

if { [empty_string_p $return_url] } {
    set return_url [im_url_with_query]
}

set caller_user_id $user_id 


set has_subordinates_p [db_string get_sub_string_p \
	"select decode(count(1),0,0,1)
	   from im_employees_active u
	  where u.supervisor_id = :caller_user_id"]

db_0or1row get_one_employee "
select 
  u.first_names, 
  u.last_name, 
  u.email, 
  u.bio,
  info.*, 
  referral.user_id as referral_id,
  referral.first_names || ' ' || referral.last_name as referral_name,
  supervisors.user_id as supervisor_user_id, 
  supervisors.first_names || ' ' || supervisors.last_name as supervisor_name,
  featured_employee_blurb,
  featured_employee_approved_p
from users u, im_employees info, users supervisors, users referral
where u.user_id = :caller_user_id
and u.user_id = info.user_id(+)
and info.referred_by = referral.user_id(+)
and ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'
and info.supervisor_id = supervisors.user_id(+)"

if { ![info exists first_names] } {
    ad_return_error "Error" "That user doesn't exist"
    return
}

# We keep offices separate as their is a chance of having 
# more than one right now (because
# we have people associated with more than one office"

set list_of_group_types [list [ad_parameter OfficeGroupShortName intranet] [ad_parameter TeamGroupShortName intranet] [ad_parameter ProjectGroupShortName intranet] [ad_parameter CustomerGroupShortName intranet]]

# Only site-wides can add teams and manage categories right now
if { [ad_permission_p site_wide] } {
    set add_team_href "/groups/group-new-2.tcl?parent_group_id=[im_team_group_id]&group_type=intranet&[export_url_vars return_url]"
    set manage_categories_link "(<a href=/admin/intranet/>manage these categories</a>)"
} else {
    set add_team_href ""
    set manage_categories_link ""
}

# Set up lists of: type, parent_group_id, what it is, link to add a new group, link to view current group
set list_of_group_types [list \
	[list [im_office_group_id] "office" "[im_url_stub]/offices/new?[export_url_vars return_url]" "[im_url_stub]/offices/view"] \
	[list [im_team_group_id] "team" $add_team_href ""] \
	[list [im_project_group_id] "project" "[im_url_stub]/projects/new?[export_url_vars return_url]" "[im_url_stub]/projects/view"] \
	[list [im_customer_group_id] "customer" "[im_url_stub]/customers/new?[export_url_vars return_url]" "[im_url_stub]/customers/view"]]

set group_message ""
foreach triple $list_of_group_types {
    append group_message [im_local_format_group $caller_user_id $triple $return_url]
}

set user_admin_p [im_user_intranet_admin_p $user_id]
append group_message "  <p><li><a href=all_projects.tcl?[export_url_vars user_id]>Add to all projects</a>"
append group_message "  <p><li>Intranet Administrator? [util_decode $user_admin_p 1 "Yes" "No"] (<a href=intranet-admin-toggle?user_id=$caller_user_id>toggle</a>)\n"

proc display_salary {salary} {

    set display_pref [im_salary_period_display]
    set salary_period [im_salary_period_input]

    switch $salary_period {
        month {
	    if {$display_pref == "month"} {
                 return "[format %6.2f $salary] per month"
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f [expr $salary * 12]] per year"
            } else {
                 return "\$[format %6.2f $salary] per $salary_period"
            }
        }
        year {
	    if {$display_pref == "month"} {
                 return "[format %6.2f [expr $salary/12]] per month "
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f $salary] per year "
            } else {
                 return "\$[format %6.2f $salary] per $salary_period "
            }
        }
        default {
            return "\$[format %6.2f $salary] per $salary_period  "
        }
    }
}

set page_title "$first_names $last_name"
set context_bar [ad_context_bar [list ./ "Employees"] "One employee"]

if { [empty_string_p $job_title] } {
    set job_title "<em>(No information)</em>"
}

if [empty_string_p $salary] {
    set salary "<em>(No information)</em>"
} else {
    set salary [display_salary $salary ]
}

if { ![empty_string_p $supervisor_user_id] } {
    set supervisor_link "<a href=view?user_id=$supervisor_user_id>$supervisor_name</a>"
} else {
    set supervisor_link "<em>(No information)</em>"
}

if { $has_subordinates_p } {
    set clear_subordinates_link "<a href=change-subordinates?from_user_id=$caller_user_id>Transfer subordinates to another supervisor</a>"
} else {
    set clear_subordinates_link ""
}

append page_body "

<h3>In Processing</h3>
$manage_categories_link
<ul>
<form action=in-processing-edit-2 method=post>
<input type=hidden name=return_url value=\"$return_url\">
<input type=hidden name=caller_user_id value=\"$caller_user_id\">
<li>Previous company/position
<select name=experience_id>
<option></option>
[db_html_select_value_options  -select_option $experience_id getexperience "select  experience_id, experience from im_prior_experiences order by lower(experience)"]
</select>
<li>Source: 
<select name=source_id>
<option></option>
[db_html_select_value_options -select_option $source_id getsource "select source_id, source from im_hiring_sources order by lower(source)"]
</select>  
<li>Qualification process: 
<select name=qualification_id>
<option></option>
[db_html_select_value_options  -select_option $qualification_id getqualifications "select qualification_id , qualification from im_qualification_processes order by lower(qualification)"]
</select>  
<li>Department 
<select name=department_id>
<option></option>
[db_html_select_value_options  -select_option $department_id getdepartment "select department_id,department from im_departments order by lower(department)"]
</select>  
<li>Original Job:
<select name=original_job_id>
<option></option>
[db_html_select_value_options  -select_option $original_job_id getoriginaljob "select job_title_id, job_title  from im_job_titles order by lower(job_title)"]
</select>  
<li>Start date: [ad_dateentrywidget start_date $start_date]
<br>
<input type=submit name=submit value=\"Edit above\">
</form>
<li>Referred by: "
set target "[im_url_stub]/employees/admin/info-update-referral.tcl"
set passthrough "return_url employee_id"
set employee_id $caller_user_id
if { ![empty_string_p $referred_by] } {    
    append page_body "<a href=[im_url_stub]/users/view?user_id=$referral_id>$referral_name</a>  recorded by [db_string getname "select first_names || ' ' || last_name from users where user_id = [util_decode $referred_by_recording_user "" 0 $referred_by_recording_user]" -default ""]
(<a href=../../user-search?[export_url_vars passthrough target return_url employee_id]>update</a> | 
 <a href=info-update-referral?user_id_from_search=&[export_url_vars employee_id return_url]>clear</a> )\n"
} else {
        append page_body "<a href=../../user-search?[export_url_vars passthrough target return_url employee_id]>add</a>"
}

append page_body "
<p>
In processing checkpoints: <font size=-1><a href=checkpoint-add?stage=in_processing&[export_url_vars return_url]>add an in processing checkpoint</a></font>
<p>"

set thequery "select checkpoint, im_employee_checkpoints.checkpoint_id, 
    check_date, check_note, first_names, last_name,  checkee, 
    im_emp_ccs.checker as checker
    from im_employee_checkpoints, 
    (select checkpoint_id, check_date, check_note, checker, checkee 
       from im_emp_checkpoint_checkoffs 
       where im_emp_checkpoint_checkoffs.checkee = :caller_user_id
    ) im_emp_ccs, users
    where im_employee_checkpoints.checkpoint_id = im_emp_ccs.checkpoint_id (+)
    and stage = 'in_processing'
    and users.user_id (+) = im_emp_ccs.checker
"

set checkstring ""
db_foreach getcheckpoints $thequery {
    append checkstring "<li>$checkpoint:"
    if {[empty_string_p $check_date]} {
	append checkstring " <a href=checkoff?[export_url_vars checkpoint_id return_url]&checkee=$caller_user_id>Checkoff</a>"
     } else {
	append checkstring " $check_note by 
	   <a href=[im_url_stub]/employees/admin/view?user_id=$checker>
           $first_names $last_name</a> on $check_date 
           (<a href=checkpoint-edit?[export_url_vars checkpoint_id user_id]>edit</a>)"
     }
 }

append page_body "
$checkstring
</ul>

<h3>Group membership</H3>
<ul>
$group_message
</ul>

<h3>Employment Information</h3>
<ul>
<li> <form method=get action=update-supervisor-2>
Supervisor:
<input type=hidden name=user_id value=\"$caller_user_id\">
<input type=hidden name=return_url value=\"$return_url\">
<select name=dp.im_employees.supervisor_id>
<option value=\"\"> None
[db_html_select_value_options -select_option $supervisor_user_id getsupervisor  "select u.user_id, u.last_name || ', ' || u.first_names as name 
from im_employees_active u
where u.user_id <> :caller_user_id
order by upper(u.last_name)"]
</select>
<input type=submit value=\"Update\">
</form>
[util_decode $clear_subordinates_link "" "" "<li>$clear_subordinates_link"]
<li>Salary: $salary
 -- <A HREF=../payroll?user_id=$caller_user_id&[export_url_vars return_url]>payroll information</A>

<li>Percentage of a full work week:  [db_string  getpercent "select percentage_time from im_employee_percentage_time where user_id = :caller_user_id and start_block = (select max(start_block) from im_start_blocks where start_block <= sysdate)" -default ""] (<a href=history?user_id=$caller_user_id>edit</a>)
<li><form action=current-job-edit-2>
Job Title:
<input type=hidden name=user_id value=\"$caller_user_id\">
[export_form_vars return_url]
<select name=current_job_id>
<option></option>
[db_html_select_value_options  -select_option $current_job_id getjobinfo "select  job_title_id, job_title from im_job_titles order by lower(job_title)" ]
</select>   <input type=submit name=submit value=Update>
</form>
<p>
<form action=employment-info-update action=post>
[export_form_vars return_url]
<input type=hidden name=user_id value=\"$caller_user_id\">
<li> People they have referred: [join \
[util_decode   \
[catch {db_list getpeoplereferred \
	"select u.first_names || ' ' ||u.last_name as user_name
           from users u, im_employees info
          where u.user_id=info.user_id
            and info.referred_by=:caller_user_id
order by lower(user_name)"} result] 0 $result [list "none"]]  ", "]
<li>Job description: $job_description
<li>Most recent review: [util_AnsiDatetoPrettyDate $most_recent_review]
<li>Reviewed by:
<li>Most recent review in folder? [util_decode t $most_recent_review_in_folder_p "Yes" "No"]
<br>
<input type=submit name=submit value=\"Edit\">
</form>
</ul>
<h3>Personal information</h3>

<ul>

<li>Biography: 
<blockquote>
$bio
</blockquote>
<li> Years experience: $years_experience
<li> Educational history: $educational_history
<li> Last degree completed: $last_degree_completed
<li>Featured Employee Blurb:
<blockquote>
$featured_employee_blurb
</blockquote>
<form action=info-update method=post>
<input type=hidden name=user_id value=\"$caller_user_id\">
<input type=submit name=submit value=\"Edit\">
</form>

</ul>
"

append page_body "<h3>Termination</h3>
<ul>
<li>Date of termination: [util_decode $termination_date "" "n/a" [util_AnsiDatetoPrettyDate $termination_date]]
<li>Termination Reason: $termination_reason
<li>Termination voluntary: [util_PrettyBoolean $voluntary_termination_p ""]
<form action=employee-termination method=post>
<input type=hidden name=user_id value=\"$caller_user_id\">
<input type=submit name=submit value=\"Edit\">
</form>

<p>
Termination checkpoints: <font size=-1><a href=checkpoint-add?stage=termination&[export_url_vars return_url]>add a termination checkpoint</a></font>
<p>"

set thequery "select checkpoint, im_employee_checkpoints.checkpoint_id, check_date, check_note, first_names , last_name ,  checkee
from im_employee_checkpoints, 
(select checkpoint_id, check_date, check_note, checker, checkee from im_emp_checkpoint_checkoffs where im_emp_checkpoint_checkoffs.checkee = :caller_user_id) im_emp_ccs, users
where im_employee_checkpoints.checkpoint_id = im_emp_ccs.checkpoint_id (+)
and stage = 'termination'
and users.user_id (+) = im_emp_ccs.checker
"

set checkstring ""
db_foreach getmorecheckpoints $thequery {
    append checkstring "<li>$checkpoint:"
    if {[empty_string_p $check_date]} {
	append checkstring " <a href=checkoff?[export_url_vars checkpoint_id return_url]&checkee=$caller_user_id>Checkoff</a>"
     } else {
	append checkstring " $check_note  by <a href=[im_url_stub]/employees/admin/view?user_id=$checkee>$first_names $last_name</a> on $check_date"
     }
 }

append page_body "
$checkstring
</ul>
"

doc_return  200 text/html [im_return_template]

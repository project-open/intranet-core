# /tcl/intranet-project-components.tcl
#
# Copyright (C) 2004 Project/Open
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Projects.

    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
    @creation-date  27 June 2003
}



namespace eval project {

    ad_proc new {
        -project_name
        -project_nr
        -project_path
        -customer_id
        { -parent_id "" }
	{ -project_type_id "" }
	{ -project_status_id "" }
	{ -creation_date "" }
	{ -creation_user "" }
	{ -creation_ip "" }
	{ -context_id "" }

    } {
	Creates a new project including the projects  "Main Office".
	@author frank.bergmann@project-open.com

	@return <code>project_id</code> of the newly created project

	@param project_name Pretty name for the project
	@param project_nr Current project Nr, such as: "2004_0001".
	@param project_path Path for project files in the filestorage
	@param customer_id Who is going to pay for this project?
	@param parent_id Which is the parent (for subprojects)
	@param project_type_id Default: "Other": Configurable project
	       type used for reporting only
	@param project_status_id Default: "Active": Allows to follow-
	       up through the project acquistion process
	@param others The default optional parameters for OpenACS
	       objects
    } {
	# -----------------------------------------------------------
	# Check for duplicated unique fields (name & path)
	# We asume the application page knows how to deal with
	# the uniqueness constraint, so we won't generate an error
	# but just return the duplicated item. 
	set dup_sql "
select	project_id 
from	im_projects 
where	upper(trim(project_name)) = upper(trim(:project_name))
	or upper(trim(project_nr)) = upper(trim(:project_nr))
	or upper(trim(project_path)) = upper(trim(:project_path))"
	set pid 0
	db_foreach dup_projects $dup_sql { set pid $project_id }
	if {0 != $pid} { return $pid }

	# -----------------------------------------------------------
	set sql "
begin
    :1 := im_project.new(
	object_type	=> 'im_project',
	project_name	=> '$project_name',
        project_nr      => '$project_nr',
        project_path   => '$project_path'
"
if {"" != $customer_id} { append sql "\t, customer_id => $customer_id\n" }
if {"" != $parent_id} { append sql "\t, parent_id => $parent_id\n" }
if {"" != $project_type_id} { append sql "\t, project_type_id => $project_type_id\n" }
if {"" != $project_status_id} { append sql "\t, project_status_id => $project_status_id\n" }

if {"" != $creation_date} { append sql "\t, creation_date => '$creation_date'\n" }
if {"" != $creation_user} { append sql "\t, creation_user => '$creation_user'\n" }
if {"" != $creation_ip} { append sql "\t, creation_ip => '$creation_ip'\n" }
if {"" != $context_id} { append sql "\t, context_id => $context_id\n" }

	append sql "        );
    end;
"
	db_exec_plsql create_new_project $sql
    }
}



ad_proc -public im_new_project_html { user_id } {
    Return a piece of HTML allowing a user to start a new project
} {
    if {![im_permission $user_id add_projects]} { return "" }
    return "<a href='/intranet/projects/new'>
           [im_gif new "Create a new Project"]
           </a>"
}


ad_proc -public im_next_project_nr { } {
    Returns the next free project number

    Project_nr's look like: 2003_0123 with the first 4 digits being
    the current year and the last 4 digits as the current number
    within the year.
    Returns "" if there was an error calculating the number.

    The SQL query works by building the maximum of all numeric (the 8 
    substr comparisons of the last 4 digits) project numbers
    of the current year (comparing the first 4 digits to the current year),
    adding "+1", and contatenating again with the current year.
} {
    set sql "
select
	to_char(sysdate, 'YYYY')||'_'||
	trim(to_char(1+max(substr(p.project_nr,6,4)),'0000')) as project_nr
from
        im_projects p
where
        p.project_nr like '200_/_____' escape '/' and
        substr(p.project_nr, 1,4)=to_char(sysdate, 'YYYY') and
        ascii(substr(p.project_nr,6,1)) > 47 and
        ascii(substr(p.project_nr,6,1)) < 58 and
        ascii(substr(p.project_nr,7,1)) > 47 and
        ascii(substr(p.project_nr,7,1)) < 58 and
        ascii(substr(p.project_nr,8,1)) > 47 and
        ascii(substr(p.project_nr,8,1)) < 58 and
        ascii(substr(p.project_nr,9,1)) > 47 and
        ascii(substr(p.project_nr,9,1)) < 58
"
    set project_nr [db_string next_project_nr $sql -default ""]
    return $project_nr
}



ad_proc -public im_current_project_nr { } {
    Returns the current project number, not touching the sequence. 
    !!! Attention: currval is only defined within the same session !!!
    !!! of a preceeding nextval. Just querying currval will cause  !!!
    !!! an error .                                                 !!!
} {
    
    set project_nr_prefix [ad_parameter "ProjectNumberPrefix" intranet "2003"]
    set next_project_nr_query "select im_projects_seq.currval from dual"
    if { ![db_0or1row max_project_nr_query $next_project_nr_query] } {
	return ""
    }
    set sls_project_nr "$project_nr_prefix"
    append sls_project_nr "_"
    append sls_project_nr [format "%04u" $currval]
    return $sls_project_nr
}

ad_proc -public im_target_languages { on_what_id on_which_table} {
    Returns a (possibly empty list) of target languages 
    (i.e. "en_ES", ...) used for a specific project or task
    (on_which_table=im_projects or im_tasks).
} {
    set result [list]
    set sql "
select
	im_category_from_id(l.language_id) as target_language
from 
	im_target_languages l
where 
	on_what_id=:on_what_id
	and on_which_table=:on_which_table
"
    db_foreach select_target_languages $sql {
	lappend result $target_language
    }
    return $result
}

ad_proc -public im_target_language_ids { on_what_id on_which_table} {
    Returns a (possibly empty list) of target language IDs used
    for a specific project or task (on_which_table=im_projects or im_tasks).
} {
    set result [list]
    set sql "
select
	language_id
from 
	im_target_languages
where 
	on_what_id=:on_what_id
	and on_which_table=:on_which_table
"
    db_foreach select_target_languages $sql {
	lappend result $language_id
    }
    return $result
}

ad_proc -public im_format_project_duration { words {lines ""} {hours ""} {days ""} {units ""} } {
    Write out the shortest possible string describing the 
    length of a project
} {
    set result $words
    set pending ""
    if {![string equal $words ""]} {
	set pending "W, "
    }

    if {![string equal $lines ""]} {
	append result "${pending}${lines}L"
	set pending ", "
    }
    if {![string equal $hours ""]} {
	append result "${pending}${hours}H"
	set pending ", "
    }
    if {![string equal $days ""]} {
	append result "${pending}${days}D"
	set pending ", "
    }
    if {![string equal $units ""]} {
	append result "${pending}${units}U"
	set pending ""
    }
    return $result
}


ad_proc -public im_project_members_select { select_name project_id { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all members of $project_id. If status is
    specified, we limit the select box to invoices that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id $project_id

    set sql "
select
	u.user_id,
	u.first_names||' '||u.last_name as user_name
from
	user_group_map m,
	users u
where
	m.group_id=:project_id
	and m.user_id=u.user_id
order by 
	lower(first_names)"

    return [im_selection_to_select_box $bind_vars "project_member_select" $sql $select_name $default]
}


ad_proc -public im_project_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the project_types in the system
} {
    return [im_category_select "Intranet Project Type" $select_name $default]
}

ad_proc -public im_project_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the project_types in the system
} {
    return [im_category_select "Intranet Project Status" $select_name $default]
}

ad_proc -public im_project_parent_select { select_name { default "" } {current_group_id ""} { status "" } { exclude_status "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the eligible projects for parents
} {
    set bind_vars [ns_set create]
    if { [empty_string_p $current_group_id] } {
	set limit_group_sql ""
    } else {
	ns_set put $bind_vars current_group_id $current_group_id
	set limit_group_sql " and p.group_id != :current_group_id"
    }
    set status_sql ""
    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	set status_sql "and p.project_status_id=(select project_status_id from im_project_status where project_status=:status)"
    } elseif { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status] 
	set status_sql " and p.project_status_id in (
	    select project_status_id 
            from im_project_status
	    where project_status not in ($exclude_string)) "
    }

    set sql "select g.group_id, g.group_name
               from user_groups g, im_projects p 
              where p.parent_id is null 
                and g.group_id=p.group_id(+) $limit_group_sql $status_sql
              order by lower(g.group_name)"
    return [im_selection_to_select_box $bind_vars parent_project_select $sql $select_name $default]
}



ad_proc -public im_project_select { select_name { default "" } { status "" } {type ""} { exclude_status "" } {member_user_id ""} } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the projects in the system. If status is
    specified, we limit the select box to projects matching that
    status. If type is specified, we limit the select box to project
    matching that type. If exclude_status is provided as a list, we
    limit to states that do not match any states in exclude_status.
    If member_user_id is specified, we limit the select box to projects
    where member_user_id participate in some role.
 } {
     set bind_vars [ns_set create]
     ns_set put $bind_vars project_group_id [im_project_group_id]


     set sql "
	select
		p.project_id,
		p.project_name
	from
		im_projects p
	where
		1=1
	"
	
     if { ![empty_string_p $status] } {
	 ns_set put $bind_vars status $status
	 append sql " and project_status_id=(
	     select project_status_id 
	     from im_project_status 
	     where project_status=:status)"
    }

    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status]
	append sql " and project_status_id in (
	    select project_status_id 
            from im_project_status 
            where project_status not in ($exclude_string)) "
    }

    if { ![empty_string_p $type] } {
	ns_set put $bind_vars type $type
	append sql " and project_type_id=(
	    select project_type_id 
	    from im_project_types 
	    where project_type=:type)"
    }

     if { ![empty_string_p $member_user_id] } {
	 ns_set put $bind_vars member_user_id $member_user_id
	 append sql "	and p.project_id in (
				select project_id
				from im_projects
				where project_id=:member_user_id)
		    "
    }
# and ug.group_id in (
	#     select group_id
	 #    from user_group_map
	  #   where user_id=:member_user_id)




    append sql " order by lower(project_name)"
    return [im_selection_to_select_box $bind_vars project_select $sql $select_name $default]
}


ad_proc -public im_list_late_project_report_groups_for_user { user_id { number_days 7 } } {
    Returns a list of all the groups and group ids for which the
    user is late entering in a report. The ith element is the group name,
    the i+1st element is the group_id. This function simply hides the
    complexity of the late_project_report query
} {

    set project_report_type_as_survey_list [list]
    set survey_report_types_list [list]
    foreach type_survey_pair  [ad_parameter_all_values_as_list ProjectReportTypeSurveyNamePair intranet] {
	set type_survey_list [split $type_survey_pair ","]
	set type [lindex $type_survey_list 0]
	set survey [lindex $type_survey_list 1]
	# we found a project type done with a survey
	
	lappend project_report_type_as_survey_list [string tolower $type]
	lappend survey_report_types_list [string tolower $survey]
    }
    
    # We generate a list of the criteria out here to try to make the query more readable
    
    set criteria [list "p.requires_report_p='t'" "u.user_id='$user_id'"]
    # Only open projects need project reports
    lappend criteria "p.project_status_id = (
      select project_status_id 
      from im_project_status
      where project_status='Open')" 
    
    # We have multiple reports - those for project types listed in the 
    # .ini file and general comments for others.

    # Check reports that need general_comments reports
    if { [llength $project_report_type_as_survey_list] == 0 } {
	set general_comments_reports \
		"not exists  (
	  select 1 
	  from general_comments gc
	  where gc.comment_date > sysdate - $number_days
	  and on_which_table = 'user_groups'
	  and on_what_id = p.group_id)"
	lappend criteria $general_comments_reports
    } else {
	set general_comments_reports \
		"lower(project_type) not in ('[join  $project_report_type_as_survey_list "','"]')
	and not exists (
	  select 1 
	  from general_comments gc
	  where gc.comment_date > sysdate - $number_days
	  and on_which_table = 'user_groups'
	  and on_what_id = p.group_id)"
    
	# With project types that need survey reports, we check two things:
	#   1. that a survey actually exists for the user to fill out
	#   2. It's filled out if it exists.
	#
	set survey_reports "
	lower(project_type) in 
	('[join  $project_report_type_as_survey_list "','"]')
	and exists (select 1
	  from survsimp_surveys
	  where short_name in ('[join  $survey_report_types_list "','"]'))
	  and not exists (
	    select 1
	    from survsimp_responses
	    where survey_id=(
	      select survey_id 
	      from survsimp_surveys
	      where short_name in ('[join  $survey_report_types_list "','"]'
	    )
	  )
	  and submission_date > sysdate - $number_days
	  and group_id=p.group_id
	)"
	lappend criteria "( ($general_comments_reports) or ($survey_reports) )"
    }
    set where_clause [join $criteria "\n         and "]

    # Not binding the variables in this query because of the dynamic where clause
    set sql "select g.group_name, g.group_id
    from user_groups g, im_projects p, im_employees_active u, im_project_types
    where p.project_lead_id = u.user_id
    and p.project_type_id = im_project_types.project_type_id
    and p.group_id=g.group_id
    and $where_clause"

    set group_list [list]
    db_foreach late_reports_for_user $sql {
	lappend group_list $group_name $group_id
    }
    return $group_list
}


ad_proc -public im_force_user_to_enter_project_report { conn args why } {
    If a user is not on vacation and is late with their project
    report, Send them to a screen to enter that project report.
    Sets state in session so user is only asked once per session.
} {
    if { ![im_enabled_p] } {
	# intranet or hours-logging not turned on. Do nothing
	return filter_ok
    } 
    
    set last_prompted_time [ad_get_client_property intranet user_asked_to_fill_out_project_reports_p]

    if { ![empty_string_p $last_prompted_time] && \
	    $last_prompted_time > [expr [ns_time] - 60*60*24] } {
	# We have already asked the user in this session, within the last 24 hours, 
	# to enter their missing project report
	return filter_ok
    }

    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# This can't happen on standard acs installs since intranet is protected
	# But we check any way to prevent bugs on other installations
	return filter_ok
    }

    # Let's make a note that the user has been prompted 
    # to enter project reports. This saves us the database 
    # hit next time. 
    ad_set_client_property -persistent f intranet user_asked_to_fill_out_project_reports_p [ns_time]

    # build up a list of all the project reports we need to fill out
    # We'll use this as a stack to go through all project reports 
    #  until we're out of places to go
    set groups_list [list]
    
    # first check if the user is no vacation
    set user_on_vacation [db_string user_is_on_vacation \
	    "select nvl(u.on_vacation_until,sysdate-1) - sysdate from users u where u.user_id=:user_id"]

    if { $user_on_vacation > 0 } {
	# we're on vacation right now. no need to log hours
	return filter_ok
    }

    set group_name_id_list [im_list_late_project_report_groups_for_user $user_id]

    if { [llength $group_name_id_list] == 0 } {
	# no late project reports
	return filter_ok
    }

    # We have late project reports - let's build up a fancy return_url
    
    # first the current url - the last place we want to go
    set return_url [im_url_with_query]
    foreach { group_name group_id } $group_name_id_list {
	set return_url "[im_url_stub]/projects/report-add?[export_url_vars group_id return_url]"
    }
    
    ad_returnredirect $return_url
    return filter_return
}




ad_proc -public im_late_project_reports {user_id {html_p "t"} { number_days 7 } } "Returns either a text or html block describing late project reports" {
    set return_string ""

    foreach { group_name group_id } [im_list_late_project_report_groups_for_user $user_id $number_days] {
	if {$html_p == "t"} {
	    append return_string "<li><b>Late project report:</b> <a href=[im_url_stub]/projects/report-add?[export_url_vars group_id]>$group_name</a>"
	} else {
	    append return_string "$group_name: 
  [im_url]/projects/report-add?[export_url_vars group_id]

"
	}
	
    }
    return $return_string
}

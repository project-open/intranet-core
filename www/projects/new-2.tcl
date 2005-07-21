# /www/intranet/projects/new-2.tcl
#
# Copyright (C) 1998-2004 various parties
# The software is based on ArsDigita ACS 3.4
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

ad_page_contract {
    Purpose: verifies and stores project information to db.

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    return_url:optional
    project_id:integer
    project_name
    { project_path "" }
    project_nr
    project_type_id:integer
    project_status_id:integer
    company_id:integer
    { project_lead_id:integer ""}
    { supervisor_id:integer  ""}
    { parent_id:integer ""}
    { description "" }
    { requires_report_p "f" }
    { on_track_status_id "" }
    { project_budget:float "" }
    { project_budget_currency "" }
    { project_budget_hours:float "" }
    { percent_completed:float "" }
    start:array,date,notnull
    end:array,date,notnull
    end_time:array
}

# -----------------------------------------------------------------
# Defaults & Security
# -----------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

if {$percent_completed > 100 || $percent_completed < 0} {
    ad_return_complaint 1 "Error with '$percent_completed'% completed:<br>
    Number must be in range (0 .. 100)"
    return
}

# Log who's making changes and when
set todays_date [db_string projects_get_date "select sysdate from dual"]

if {"" == $project_path} { set project_path $project_nr }


# Make sure the user has the privileges, because this
# pages shows the list of companies etc.
if {![im_permission $user_id add_projects]} {

    # Double check for the case that this guy is a freelance
    # project manager of the project or similar...
    im_project_permissions $user_id $project_id view read write admin
    if {!$write} {
        ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to see this page."
    }
}

# -----------------------------------------------------------------
# Check input variables
# -----------------------------------------------------------------

set required_vars [list \
[list "project_id" "[_ intranet-core.lt_You_must_specify_the_]"] \
[list "company_id" "[_ intranet-core.lt_You_must_specify_the__1]"] \
[list "project_type_id" "[_ intranet-core.lt_You_must_specify_the__2]"] \
[list "project_nr" "[_ intranet-core.lt_You_must_specify_the__3]"]\
[list "project_status_id" "[_ intranet-core.lt_You_must_specify_the__4]"]]

set errors [im_verify_form_variables $required_vars]
if { [empty_string_p $errors] == 0 } {
    set err_cnt 1
} else {
    set err_cnt 0
}

ad_proc var_contains_quotes { var } {
    if {[regexp {"} $var]} { return 1 }
    if {[regexp {'} $var]} { return 1 }
    return 0
}

# check that no variable contains double or single quotes
if {[var_contains_quotes $project_name]} { 
    append errors "<li>[_ intranet-core.lt_Quotes_in_Project_Nam]"
}
if {[var_contains_quotes $project_nr]} { 
    append errors "<li>[_ intranet-core.lt_Quotes_in_Project_Nr_]"
}
if {[var_contains_quotes $project_path]} { 
    append errors "<li>[_ intranet-core.lt_Quotes_in_Project_Pat]"
}
if {[regexp {/} $project_path]} { 
    append errors "<li>[_ intranet-core.lt_Slashes__in_Project_P]"
}
if {[regexp {\.} $project_path]} { 
    append errors "<li>[_ intranet-core.lt_Dots__in_Project_Path]"
}


# check for not null start date
if { [info exists start(date) ] } {
   set start_date $start(date)
} else {
   incr err_cnt
   append errors "<li>[_ intranet-core.lt_Please_make_sure_the_]"
}

# check for not null end date 
if [info exists end(date)] {
   set end_date $end(date)
} else {
   incr err_cnt
   append errors "<li>[_ intranet-core.lt_Please_make_sure_the__1]"
}

# check for a valid time
set end_date_time "00:00"

if [info exists end_time(time)] {

    if { ![regexp {[0-9][0-9]\:[0-9][0-9]$} $end_time(time)] } {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_Invalid_time_format_e]"
    }
    set end_date_time $end_time(time)
}

# make sure end date after start date
if { ![empty_string_p $end_date] && ![empty_string_p $start_date] } {
    set difference [db_string projects_get_date_difference \
	    "select to_date(:end_date,'YYYY-MM-DD') - to_date(:start_date,'YYYY-MM-DD') from dual"]
    if { $difference < 0 } {
	incr err_cnt
	append errors "  <li>[_ intranet-core.lt_End_date_must_be_afte]"
    }
}

# Let's make sure the specified project_nr is unique
set project_nr ${project_nr}
set project_nr_exists [db_string project_nr_exists "
select 	count(*)
from	im_projects
where	project_nr = :project_nr
        and project_id <> :project_id"]

if { $project_nr_exists > 0 } {
    incr err_cnt
    append errors "  <li>[_ intranet-core.lt_The_specified_project]"
}


# Make sure the project name has a minimum length
if { [string length $project_name] < 5} {
   incr err_cnt
   append errors "<li>[_ intranet-core.lt_The_project_name_that] <br>
   [_ intranet-core.lt_Please_use_a_project_]"
}

# Let's make sure the specified name is unique
set project_name_exists [db_string project_name_exists "
select 	count(*)
from	im_projects
where	(
	    upper(trim(project_name)) = upper(trim(:project_name))
	    or upper(trim(project_nr)) = upper(trim(:project_nr))
	    or upper(trim(project_path)) = upper(trim(:project_path))
	)
        and project_id <> :project_id"]

if { $project_name_exists > 0 } {
    incr err_cnt
    append errors "  <li>[_ intranet-core.lt_The_specified_name_pr]"
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $err_cnt $errors
    return
}

# -----------------------------------------------------------------
# Create a new Project if it didn't exist yet
# -----------------------------------------------------------------

# Double-Click protection: the project Id was generated at the new.tcl page

set id_count [db_string id_count "select count(*) from im_projects where project_id=:project_id"]


# Create the "administration group" for this project.
# The project is going to get the same ID then.
#
if {0 == $id_count} {

    set project_id [project::new \
        -project_name		$project_name \
        -project_nr		$project_nr \
        -project_path		$project_path \
        -company_id		$company_id \
        -parent_id		$parent_id \
        -project_type_id	$project_type_id \
	-project_status_id	$project_status_id]

    # add users to the project as PMs
    # - current_user (creator/owner)
    # - project_leader
    # - supervisor
    set role_id [im_biz_object_role_project_manager]
    im_biz_object_add_role $user_id $project_id $role_id 
    if {"" != $project_lead_id} {
	im_biz_object_add_role $project_lead_id $project_id $role_id 
    }
    if {"" != $supervisor_id} {
	im_biz_object_add_role $supervisor_id $project_id $role_id 
    }
}


# -----------------------------------------------------------------
# Update the Project
# -----------------------------------------------------------------

    set project_update_sql "
update im_projects set
	project_name =	:project_name,
	project_path =	:project_path,
	project_nr =	:project_nr,
	project_type_id =:project_type_id,
	project_status_id =:project_status_id,
	project_lead_id =:project_lead_id,
	company_id =	:company_id,
	supervisor_id =	:supervisor_id,
	parent_id =	:parent_id,
	description =	:description,
	requires_report_p =:requires_report_p,
	project_budget =:project_budget,
	project_budget_currency =:project_budget_currency,
	project_budget_hours =:project_budget_hours,
	percent_completed = :percent_completed,
	on_track_status_id =:on_track_status_id,
	start_date =	:start_date,
	end_date =	to_timestamp('$end_date $end_date_time', 'YYYY-MM-DD HH24:MI')
where
	project_id = :project_id
"

    db_dml project_update $project_update_sql


if { [exists_and_not_null project_lead_id] } {

    # add the creating current user to the group
    relation_add \
        -member_state "approved" \
        "admin_rel" \
        $project_id \
        $project_lead_id

}


if { ![exists_and_not_null return_url] } {
    set return_url "[im_url_stub]/projects/view?[export_url_vars project_id]"
}

ad_returnredirect $return_url


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
    customer_id:integer
    { project_lead_id:integer ""}
    { supervisor_id:integer  ""}
    { parent_id:integer ""}
    { description "" }
    { requires_report_p "f" }
    { project_budget "" }
    start:array,date,notnull
    end:array,date,notnull
    end_time:array
}

# -----------------------------------------------------------------
# Defaults & Security
# -----------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

# Log who's making changes and when
set todays_date [db_string projects_get_date "select sysdate from dual"]

if {"" == $project_path} { set project_path $project_nr }

# Make sure the user has the privileges, because this
# pages shows the list of customers etc.
if {![im_permission $user_id "add_projects"]} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."
}

# -----------------------------------------------------------------
# Check input variables
# -----------------------------------------------------------------

set required_vars [list \
[list "project_id" "You must specify the project_id"] \
[list "customer_id" "You must specify the client"] \
[list "project_type_id" "You must specify the project type"] \
[list "project_nr" "You must specify the project #"]\
[list "project_status_id" "You must specify the project status"]]

set errors [im_verify_form_variables $required_vars]
if { [empty_string_p $errors] == 0 } {
    set err_cnt 1
} else {
    set err_cnt 0
}

# check for not null start date
if { [info exists start(date) ] } {
   set start_date $start(date)
} else {
   incr err_cnt
   append errors "<li> Please make sure the start date is not empty"
}

# check for not null end date 
if [info exists end(date)] {
   set end_date $end(date)
} else {
   incr err_cnt
   append errors "<li> Please make sure the end date is not empty"
}

# check for a valid time
set end_date_time "00:00"
if [info exists end_time(time)] {
    if { ![regexp {[0-9][0-9]\:[0-9][0-9]$} $end_time(time)] } {
	ad_return_complaint 1 "<li> Invalid time format '$end_time(time)': Please enter the time in format '12:30'"
    }
    set end_date_time $end_time(time)
}

# make sure end date after start date
if { ![empty_string_p $end_date] && ![empty_string_p $start_date] } {
    set difference [db_string projects_get_date_difference \
	    "select to_date(:end_date,'YYYY-MM-DD') - to_date(:start_date,'YYYY-MM-DD') from dual"]
    if { $difference < 0 } {
	incr err_cnt
	append errors "  <li> End date must be after start date\n"
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
    append errors "  <li> The specified project_nr, \"${project_nr},\" already exists - please select another, unique project_nr\n"
}


# Make sure the project name has a minimum length
if { [string length $project_name] < 5} {
   incr err_cnt
   append errors "<li>The project name that you have chosen is too short. <br>
   Please use a project name with atleast 6 characters"
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
    append errors "  <li> The specified name, \"${project_name},\" already exists - please select another, unique name\n"
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
        -customer_id		$customer_id \
        -parent_id		$parent_id \
        -project_type_id	$project_type_id \
	-project_status_id	$project_status_id]

    # add users to the project as PMs (1301):
    # - current_user (creator/owner)
    # - project_leader
    # - supervisor
    set role_id 1301
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
	customer_id =	:customer_id,
	supervisor_id =	:supervisor_id,
	parent_id =	:parent_id,
	description =	:description,
	requires_report_p =:requires_report_p,
	project_budget =:project_budget,
	start_date =	:start_date,
	end_date =	to_date('$end_date $end_date_time', 'YYYY-MM-DD HH24:MI')
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

# doc_return  200 text/html "<body></body>"

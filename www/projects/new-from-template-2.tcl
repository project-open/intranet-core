# /packages/intranet-core/projects/new-from-template-2.tcl
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
    Purpose: Create a copy of an existing project
    
    @param parent_project_id the parent project id
    @param return_url the url to return to
    @param template_postfix Postfix to add to the project name
           if the project_name already exists.

    @author frank.bergmann@project-open.com
} {
    { template_project_id:integer 0 }
    { project_nr "" }
    { project_name "" }
    { company_id 0 }
    { template_postfix "From Template" }
    { return_url "" }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set project_nr_field_size [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldSize "" 20]

set current_url [ns_conn url]

if {![im_permission $user_id add_projects]} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to see this page."
}


if {"" == $template_project_id} {
    ad_return_complaint 1 "<li>You haven't chosen a valid template."
    return
}

# Make sure the user can read the template_project
if {$template_project_id} {
    im_project_permissions $user_id $template_project_id template_view template_read template_write template_admin
    if {!$template_read} {
	ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to read from the template."
    }
}


# ---------------------------------------------------------------------
# Determine what to clone
# ---------------------------------------------------------------------

set clone_members_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectMembersP" -default 1]
set clone_costs_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectCostsP" -default 0]
set clone_trans_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTransTasksP" -default 0]
set clone_timesheet_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTimesheetTasksP" -default 1]
set clone_forum_topics_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectForumTopicsP" -default 1]
set clone_files_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectFsFilesP" -default 1]
set clone_folders_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectFsFoldersP" -default 1]
set clone_subprojects_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectSubprojectsP" -default 1]

set clone_struct {
    {"Clone Project Members" clone_members_p}
    {"Clone Costs" clone_costs_p}
    {"Clone Timesheet Tasks" clone_timesheet_tasks_p}
    {"Clone Forum Topics" clone_forum_topics_p}
    {"Clone Filestorage Files" clone_files_p}
    {"Clone Filestorage Folders" clone_folders_p}
    {"Clone Sub-projects" clone_subprojects_p}
}

set clone_html ""
foreach struct $clone_struct {
    set name [lindex $struct 0]
    set var [lindex $struct 1]
    set value [expr \$$var]

    set checked ""
    if {$value} { set checked "checked" }
    append clone_html "
	<tr>
	<td>$name</td>
	<td><input type=checkbox name=$var $checked></td>
	</tr>   
    "
}

# ---------------------------------------------------------------------
# Get Template information
# ---------------------------------------------------------------------

# Get the information from the parent project
#
db_1row projects_info_query { 
select 
	p.project_name as template_project_name,
        p.company_id as template_company_id
from
	im_projects p
where 
	p.project_id=:template_project_id
}


# Create a new project_nr if it wasn't specified
if {"" == $project_nr || ""} {
    set project_nr [im_next_project_nr -customer_id $template_company_id]
}

# Use the parents project name if none was specified
if {"" == $project_name} {
    set project_name $template_project_name
}

# Append "Postfix" to project name if it already exists:
#
while {[db_string count "select count(*) from im_projects where project_name = :project_name"]} {
    set project_name "$project_name - $template_postfix"
}

set parent_project_id $template_project_id
set page_title [lang::message::lookup "" intranet-core.Template_Project "Template Project"]
set button_text [lang::message::lookup "" intranet-core.Create "Create"]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]


# Default values for checkboxes

set clone_costs_p_selected ""
set clone_files_p_selected ""
set clone_subprojects_p_selected ""
set clone_forum_topics_p_selected ""
set clone_members_p_selected ""
set clone_timesheet_tasks_p_selected ""
set clone_trans_tasks_p_selected ""

if {1 == [ad_parameter -package_id [im_package_core_id] CloneProjectCostsP "" ""]} { set clone_costs_p_selected checked }
if {1 == [ad_parameter -package_id [im_package_core_id] CloneProjectFilesP "" ""]} { set clone_files_p_selected checked }
if {1 == [ad_parameter -package_id [im_package_core_id] CloneProjectSubprojectsP "" ""]} { set clone_subprojects_p_selected checked }
if {1 == [ad_parameter -package_id [im_package_core_id] CloneProjectForumTopicsP "" ""]} { set clone_forum_topics_p_selected checked }
if {1 == [ad_parameter -package_id [im_package_core_id] CloneProjectMembersP "" ""]} { set clone_members_p_selected checked }
if {1 == [ad_parameter -package_id [im_package_core_id] CloneProjectTimesheetTasksP "" ""]} { set clone_timesheet_tasks_p_selected checked }
if {1 == [ad_parameter -package_id [im_package_core_id] CloneProjectTransTasksP "" ""]} { set clone_trans_tasks_p_selected checked }


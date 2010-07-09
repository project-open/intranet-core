# /packages/intranet-core/projects/clone.tcl
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
    @param clone_postfix Postfix to add to the project name
           if the project_name already exists.

    @author avila@digiteix.com
    @author frank.bergmann@project-open.com
} {
    parent_project_id:integer
    { project_nr "" }
    { project_name "" }
    { company_id 0 }
    { clone_postfix "Clone" }
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

# Make sure the user can read the parent_project
im_project_permissions $user_id $parent_project_id parent_view parent_read parent_write parent_admin
if {!$parent_read} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to see this page."
}



# ---------------------------------------------------------------------
# Get Clone information
# ---------------------------------------------------------------------


set clone_members_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectMembersP" -default 1]
set clone_costs_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectCostsP" -default 0]
set clone_trans_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTransTasksP" -default 0]
set clone_timesheet_tasks_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTimesheetTasksP" -default 1]
set clone_target_languages_p [parameter::get -package_id [im_package_core_id] -parameter "CloneProjectTargetLanguagesP" -default 0]
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
    {"Clone Target Languages" clone_target_languages_p}
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

# ad_return_complaint 1 [ns_quotehtml $clone_html]


# ---------------------------------------------------------------------
# Get Clone information
# ---------------------------------------------------------------------

# Get the information from the parent project
#
db_1row projects_info_query { 
select 
	p.project_name as parent_project_name,
	p.company_id as parent_company_id
from
	im_projects p
where 
	p.project_id=:parent_project_id
}


# Create a new project_nr if it wasn't specified
if {"" == $project_nr || ""} {
    set project_nr [im_next_project_nr -customer_id $parent_company_id]
}

# Use the parents project name if none was specified
if {"" == $project_name} {
    set project_name $parent_project_name
}

# Append "Postfix" to project name if it already exists:
#
while {[db_string count "select count(*) from im_projects where project_name = :project_name"]} {
    set project_name "$project_name - $clone_postfix"
}


set page_title [lang::message::lookup "" intranet-core.Clone_Project "Clone Project"]
set button_text "[lang::message::lookup "" intranet-core.Create "Create"] $clone_postfix"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]

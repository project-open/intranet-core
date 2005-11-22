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

# Make sure the user can read the template_project

if {$template_project_id} {
    im_project_permissions $user_id $template_project_id template_view template_read template_write template_admin
    if {!$template_read} {
	ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to read from the template."
    }
}

# ---------------------------------------------------------------------
# Get Template information
# ---------------------------------------------------------------------

# Get the information from the parent project
#
db_1row projects_info_query { 
select 
	p.project_name as template_project_name
from
	im_projects p
where 
	p.project_id=:template_project_id
}


# Create a new project_nr if it wasn't specified
if {"" == $project_nr || ""} {
    set project_nr [im_next_project_nr]
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

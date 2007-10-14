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

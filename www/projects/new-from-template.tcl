# /packages/intranet-core/projects/new-from-template.tcl
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

    @author frank.bergmann@project-open.com
} {
    { template_project_id:integer 0 }
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

# Make sure the user can read the template_project

if {$template_project_id} {
    im_project_permissions $user_id $template_project_id template_view template_read template_write template_admin
    if {!$template_read} {
	ad_return_complaint "Insufficient Privileges" "
        <li>You don't have sufficient privileges to read from the template."
    }
}

# ---------------------------------------------------------------------
# Get The list of template projects
# ---------------------------------------------------------------------

set page_title [lang::message::lookup "" intranet-core.Project_Template "Project Template"]
set button_text [lang::message::lookup "" intranet-core.Create "Create"]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]

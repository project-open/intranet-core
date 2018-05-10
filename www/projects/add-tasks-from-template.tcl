# /packages/intranet-core/projects/add-tasks-from-template.tcl
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
    Add tasks from a template 
    
    @param parent_project_id the parent project id
    @param return_url the url to return to
    @param clone_postfix Postfix to add to the project name
           if the project_name already exists.

    @author avila@digiteix.com
    @author frank.bergmann@project-open.com
} {
    parent_project_id:integer
    { template_project_id:integer "" }
    { return_url "" }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [auth::require_login]
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

set page_title [lang::message::lookup "" intranet-core.Add_tasks_from_template "Add tasks from template"]
set button_text [lang::message::lookup "" intranet-core.Create "Create"]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]

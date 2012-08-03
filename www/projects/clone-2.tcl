# /packages/intranet-core/projects/clone-2.tcl
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
    
    @param parent_id the parent project id
    @param return_url the url to return to

    @author avila@digiteix.com
    @author frank.bergmann@project-open.com
} {
    parent_project_id:integer
    project_nr
    project_name
    { company_id:integer 0 }
    { clone_postfix "Clone" }
    { return_url "" }
    { clone_costs_p 0 }
    { clone_files_p 0 }
    { clone_subprojects_p 0 }
    { clone_forum_topics_p 0 }
    { clone_members_p 0 }
    { clone_timesheet_tasks_p 0 }
    { clone_target_languages_p 0 }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set required_field "<font color=red size=+1><B>*</B></font>"
set project_nr_field_size [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldSize "" 20]
set page_title "Clone Project"

set current_url [ns_conn url]

if {![im_permission $current_user_id add_projects]} { 
    ad_return_complaint "Insufficient Privileges" "
	<li>You don't have sufficient privileges to see this page."
    return
}

# Make sure the user can read the parent_project
im_project_permissions $current_user_id $parent_project_id parent_view parent_read parent_write parent_admin
if {!$parent_read} {
    ad_return_complaint "Insufficient Privileges" "
	<li>You don't have sufficient privileges to see this page."
    return
}

# ----------------------------------------------------
# Write out HTTP headers to prepare for error output

set content_type "text/html"
set http_encoding "utf-8"

append content_type "; charset=$http_encoding"

set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"

util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type
ns_write [im_header $page_title]
ns_write [im_navbar]
ns_write "<p>\n"

set page_body [im_project_clone \
		   -clone_costs_p $clone_costs_p \
		   -clone_files_p $clone_files_p \
		   -clone_subprojects_p $clone_subprojects_p \
		   -clone_forum_topics_p $clone_forum_topics_p \
		   -clone_members_p $clone_members_p \
		   -clone_timesheet_tasks_p $clone_timesheet_tasks_p \
		   -clone_target_languages_p $clone_target_languages_p \
		   -company_id $company_id \
		   $parent_project_id \
		   $project_name \
		   $project_nr \
		   $clone_postfix \
]


set clone_project_id [db_string project_id "select max(project_id) from im_projects where project_nr = :project_nr" -default 0]
set clone_project_type_id [db_string project_id "select project_type_id from im_projects where project_id = :clone_project_id" -default 0]

# -----------------------------------------------------------------
# Create a new Workflow for the project either if:
# - if there is a WF associated with the project_type

# Check if there is a WF associated with the project type
set wf_key [db_string wf "select aux_string1 from im_categories where category_id = :clone_project_type_id" -default ""]
if { "" != $wf_key } {
            # Create a new workflow case (instance)
            set context_key ""
            set case_id [wf_case_new \
                     $wf_key \
                     $context_key \
                     $clone_project_id \
	    ]
            # Determine the first task in the case to be executed and start+finisch the task.
            im_workflow_skip_first_transition -case_id $case_id
}

# Write Audit Trail
im_project_audit -project_id $clone_project_id


if {"" == $return_url && 0 != $clone_project_id} { 
    set return_url "/intranet/projects/view?project_id=$clone_project_id" 
}

if {"" == $return_url } { 
    set return_url "/intranet/projects/"
}

ns_write "
	</table>

	<li><a href=\"$return_url\">Return to project page</a>
	[im_footer]
"

# ad_returnredirect $return_url
# doc_return 200 text/html [im_return_template]

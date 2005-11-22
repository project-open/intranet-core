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
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set required_field "<font color=red size=+1><B>*</B></font>"
set project_nr_field_size [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldSize "" 20]

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

set page_body [im_project_clone \
	-company_id $company_id \
	$parent_project_id \
	$project_name \
	$project_nr \
	$clone_postfix \
]

set clone_project_id [db_string project_id "select project_id from im_projects where project_nr = :project_nr" -default 0]

if {"" == $return_url && 0 != $clone_project_id} { 
    set return_url "/intranet/projects/view?project_id=$clone_project_id" 
}

if {"" == $return_url } { 
    set return_url "/intranet/projects/"
}

ad_returnredirect $return_url

# doc_return 200 text/html [im_return_template]


# /packages/intranet-core/www/index.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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
    List all projects with dimensional sliders.

    @param order_by project display order 
    @param include_subprojects_p whether to include sub projects
    @param mine_p show my projects or all projects
    @param status_id criteria for project status
    @param type_id criteria for project_type_id
    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    { order_by "Project #" }
    { include_subprojects_p "f" }
    { mine_p "t" }
    { status_id "" } 
    { type_id:integer "0" } 
    { letter "scroll" }
    { start_idx:integer "1" }
    { how_many "" }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set view_types [list "t" "Mine" "f" "All"]
set subproject_types [list "t" "Yes" "f" "No"]
set page_title "Projects"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set current_url [ns_conn url]
set return_url "/intranet/"

set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]

# ----------------------------------------------------------------
# Hours
# ----------------------------------------------------------------

set hours_html ""
set on_which_table "im_projects"

if { [catch {
    set num_hours [hours_sum_for_user $current_user_id $on_which_table "" 7]
} err_msg] } {
    set num_hours 0
}

if { $num_hours == 0 } {
    append hours_html "<b>You haven't logged your hours in the last week. <BR>
     Please <a href=hours/index?[export_url_vars on_which_table]>log them now</a></b>\n"
} else {
    append hours_html "You logged $num_hours [util_decode $num_hours 1 hour hours] in the last 7 days."
}

if {[im_permission $current_user_id view_hours_all]} {
    set user_id $current_user_id
    append hours_html "
    <ul>
    <li><a href=hours/projects?[export_url_vars on_which_table user_id]>View your hours on all projects</a>
    <li><a href=hours/total?[export_url_vars on_which_table]>View time spent on all projects by everyone</a>
    <li><a href=hours/projects?[export_url_vars on_which_table]>View the hours logged by someone else</a>\n"
}
append hours_html "<li><a href=hours/index?[export_url_vars on_which_table]>Log hours</a>\n"

# Show the "Work Absences" link only to in-house staff.
# Clients and Freelancers do not necessarily need it.
if {[im_permission $current_user_id employee] || [im_permission $current_user_id wheel] || [im_permission $current_user_id accounting]} {
    append hours_html "<li> <a href=/intranet/absences/>Work absences</a>\n"
}
append hours_html "</ul>"

# ----------------------------------------------------------------
# Administration
# ----------------------------------------------------------------

set admin_html ""
append admin_html "
  <li> <a href=/intranet/users/view?user_id=$current_user_id>About You</A>\n"

set administration_component [im_table_with_title "Administration" $admin_html]

db_release_unused_handles

# /www/intranet/projects/view.tcl
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
    View all the info about a specific project.

    @param project_id the group id
    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date Jan 2000
} {
    project_id:integer
    { orderby "subproject_name" }
    { show_all_comments 0 }
    { forum_order_by "" }
    { forum_view_name "forum_list_project" }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set current_url [ns_conn url]

# get the current users permissions for this project
im_project_permissions $user_id $project_id read write admin

# Compatibility with old components...
set current_user_id $user_id
set user_admin_p $admin

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

if {!$read} {
    ad_return_complaint 1 "You have insufficient permissions to view this page."
    return
}

# ---------------------------------------------------------------------
# Prepare Project SQL Query
# ---------------------------------------------------------------------

# We need to check if the Dev-Tracker is installed.
if {![empty_string_p [ad_parameter "DevTrackerInstalledP" "DevTracker" ""]]} {
    set query "select 
	dt_group_id_project_id(g.group_id) as dev_tracker_project_id, "
} else {
    set query "select "
}

append query   "
	p.*,
	c.customer_name,
	c.customer_path,
	to_char(p.end_date, 'HH24:MI') as end_date_time,
	im_category_from_id(p.project_type_id) as project_type, 
	im_category_from_id(p.project_status_id) as project_status,
	im_name_from_user_id(c.primary_contact_id) as customer_contact,
	im_email_from_user_id(c.primary_contact_id) as customer_contact_email,
	im_name_from_user_id(p.project_lead_id) as project_lead,
	im_name_from_user_id(p.supervisor_id) as supervisor,
	im_name_from_user_id(c.manager_id) as manager,
	pp.project_name as parent_name
from
	im_projects p, 
	im_customers c,
	im_projects pp
where 
	p.project_id=:project_id
	and p.customer_id = c.customer_id(+)
	and p.parent_id=pp.project_id(+)
"

if { ![db_0or1row projects_info_query $query] } {
    # redirect to customers if exists
    set customer_p [db_string exists_customer "select count(*) from im_customers where customer_id=:project_id"]
    if {$customer_p} { ad_returnredirect "/intranet/customers/view?customer_id=$customer_id" }

    ad_return_complaint 1 "Can't find the project with group id of $project_id"
    return
}

# ---------------------------------------------------------------------
# Set display options as a function of the project data
# ---------------------------------------------------------------------

set page_title "Project: $project_name"


# Set the context bar as a function on whether this is a subproject or not:
#
if { [empty_string_p $parent_id] } {
    set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] "One project"]
    set include_subproject_p 1
} else {
    set context_bar [ad_context_bar [list /intranet/projects/ "Projects"] [list "/intranet/projects/view?project_id=$parent_id" "One project"] "One subproject"]
    set include_subproject_p 0
}

# Don't show subproject nor a link to the "projects" page to freelancers
if {![im_permission $user_id view_projects]} {
    set context_bar [ad_context_bar "One project"]
    set include_subproject_p 0
}

# ---------------------------------------------------------------------
# Project Base Data
# ---------------------------------------------------------------------

set project_base_data_html "
                        <table border=0>
                          <tr> 
                            <td colspan=2 class=rowtitle align=center>
                              Project Base Data
                            </td>
                          </tr>
                          <tr> 
                            <td>Project name</td>
                            <td>$project_name</td>
                          </tr>"

if { ![empty_string_p $parent_id] } { 
    append project_base_data_html "
                          <tr> 
                            <td>Parent Project</td>
                            <td>
                              <a href=/intranet/projects/view?project_id=$parent_id>$parent_name</a>
                            </td>
                          </tr>"
}

append project_base_data_html "
                          <tr> 
                            <td>SLS project#</td>
                            <td>$project_path</td>
                          </tr>"
if {[im_permission $user_id view_customers]} {
    append project_base_data_html "  <tr> 
                            <td>Client</td>
                            <td><A HREF='/intranet/customers/view?customer_id=$customer_id'>$customer_name</A>
                            </td>
                          </tr>"
}

append project_base_data_html "
		          <tr> 
                            <td>Project Manager</td>
                            <td>
[im_render_user_id $project_lead_id $project_lead $user_id $project_id]
                            </td>
                          </tr>
		          <tr> 
                            <td>Project Type</td>
                            <td>$project_type</td>
                          </tr>
                          <tr> 
                            <td>Project Status</td>
                            <td>$project_status</td>
                          </tr>\n"

if { ![empty_string_p $start_date] } { append project_base_data_html "
                          <tr>
                            <td>Start Date</td>
                            <td>$start_date</td>
                          </tr>"
}
if { ![empty_string_p $end_date] } { append project_base_data_html "
                          <tr>
                            <td>Delivery Date</td>
                            <td>$end_date $end_date_time</td>
                          </tr>"
}

if {$write} {
	append project_base_data_html "
                          <tr> 
                            <td>&nbsp; </td>
                            <td> 
                              <form action=/intranet/projects/new method=POST>
                                  [export_form_vars project_id return_url]
                                  <input type=submit value=Edit name=submit3>
                              </form>
                            </td>
                          </tr>"
}
append project_base_data_html "    </table>
                        <br>
"


# ---------------------------------------------------------------------
# Admin Box
# ---------------------------------------------------------------------

set admin_html ""
if {$admin} {
    set admin_html_content "
<ul>
  <li><A href=\"/intranet/projects/new\"> Create a new Project</A>
  <li><A href=\"/intranet/projects/new?parent_id=$project_id\"> Create a Subproject</A>
</ul>\n"
    set admin_html [im_table_with_title "Admin Project" $admin_html_content]
}

# ---------------------------------------------------------------------
# Project Hierarchy
# ---------------------------------------------------------------------

set super_project_id $project_id
set loop 1
while {$loop} {
    set loop 0
    set parent_id [db_string parent_id "select parent_id from im_projects where project_id=:super_project_id"]

    if {"" != $parent_id} {
	set super_project_id $parent_id
	set loop 1
    }
}

set hierarchy_sql {
select
	project_id as subproject_id,
	project_nr as subproject_nr,
	project_name as subproject_name,
	level as subproject_level
from
	im_projects 
start with 
	project_id=:super_project_id
connect by 
	parent_id = PRIOR project_id
}

set cur_level 1
set hierarchy_html ""
set counter 0
db_foreach project_hierarchy $hierarchy_sql {
    while {$subproject_level > $cur_level} {
	append hierarchy_html "<ul>\n"
	incr cur_level
    }

    while {$subproject_level < $cur_level} {
	append hierarchy_html "</ul>\n"
	decr cur_level
    }
    
    # Render the project itself in bold
    if {$project_id == $subproject_id} {
	append hierarchy_html "<li><B><A HREF=\"/intranet/projects/view?project_id=$subproject_id\">$subproject_name</A></B>\n"
    } else {
	append hierarchy_html "<li><A HREF=\"/intranet/projects/view?project_id=$subproject_id\">$subproject_name</A>\n"
    }

    incr counter
}

if {$counter > 1} {
    set hierarchy_html [im_table_with_title "Project Hierarchy [im_gif help "This project is part of another project or contains subprojects."]" "<ul>$hierarchy_html</ul>"]
} else {
    set hierarchy_html ""
}

# /www/intranet/projects/view.tcl

ad_page_contract {
    View all the info about a specific project.
    Code based on ACS 3.4 Intranet from mbryzek@arsdigita.com

    @param project_id the group id
    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author Frank Bergmann (fraber@fraber.de)
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
set current_user_id $user_id
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_is_group_member_p [ad_user_group_member $project_id $user_id]
set user_is_group_admin_p [im_can_user_administer_group $project_id $user_id]
set user_is_employee_p [im_user_is_employee_p $user_id]
set user_in_project_group_p [db_string user_belongs_to_project "select decode ( ad_group_member_p ( :current_user_id, $project_id ), 'f', 0, 1 ) from dual" ]

# Admin permissions to global + intranet admins + group administrators
set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p]
set user_admin_p [expr $user_admin_p || $user_is_wheel_p]

set project_id $project_id

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set return_url [im_url_with_query]
set current_url [ns_conn url]

ns_log Notice "user_is_admin_p=$user_is_admin_p"
ns_log Notice "user_is_group_member_p=$user_is_group_member_p"
ns_log Notice "user_is_group_admin_p=$user_is_group_admin_p"
ns_log Notice "user_is_employee_p=$user_is_employee_p"
ns_log Notice "user_admin_p=$user_admin_p"


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
# Second Security Check
# ---------------------------------------------------------------------

# Let the customers see their projects.
set user_is_project_customer_p [ad_user_group_member $customer_id $user_id]

set allowed 0
if {$user_admin_p} { set allowed 1}
if {$user_is_project_customer_p} { set allowed 1}
if {$user_is_group_member_p} { set allowed 1}
if {[im_permission $user_id view_projects_of_others]} { set allowed 1}
if {!$allowed} {
    ad_return_complaint 1 "You have insufficient permissions to view this page."
    return
}

# customers and freelancers are not allowed to see non-open projects.
if {![im_permission $user_id view_projects_history] && $project_status_id != [ad_parameter "ProjectStatusOpen" "intranet" "0"]} {

    # Except their own projects...
    if {!$user_is_project_customer_p} {
	ad_return_complaint 1 "<li>The project is already closed.<BR>You have insufficient permissions to view this page."
    }
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
if {![im_permission $current_user_id view_projects]} {
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
if {[im_permission $current_user_id view_customers]} {
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
[im_render_user_id $project_lead_id $project_lead $current_user_id $project_id]
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

if {$user_admin_p} {
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

set admin_html_content "
<ul>
  <li><A href=\"/intranet/projects/new\"> Create a new Project</A>
  <li><A href=\"/intranet/projects/new?parent_id=$project_id\"> Create a Subproject</A>
</ul>
"

set admin_html [im_table_with_title "Admin Project" $admin_html_content]


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

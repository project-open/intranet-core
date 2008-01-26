# /packages/intranet-core/projects/view.tcl
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
} {
    { project_id:integer 0}
    { object_id:integer 0}
    { orderby "subproject_name"}
    { show_all_comments 0}
    { forum_order_by "" }
    { view_name "standard"}
    { plugin_id:integer 0 }
    subproject_status_id:optional
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set current_url [ns_conn url]
set clone_url "/intranet/projects/clone"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

if {0 == $project_id} {set project_id $object_id}
if {0 == $project_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_specify_a] "
    return
}

set subproject_filtering_enabled_p [ad_parameter -package_id [im_package_core_id] SubprojectStatusFilteringEnabledP "" 0]
if {$subproject_filtering_enabled_p} {
    set subproject_filtering_default_status_id [ad_parameter -package_id [im_package_core_id] SubprojectStatusFilteringDefaultStatus "" ""]
    if {![info exists subproject_status_id]} { 
	set subproject_status_id $subproject_filtering_default_status_id 
    }
}

set clone_project_enabled_p [ad_parameter -package_id [im_package_core_id] EnableCloneProjectLinkP "" 0]
set execution_project_enabled_p [ad_parameter -package_id [im_package_core_id] EnableExecutionProjectLinkP "" 0]
set gantt_project_enabled_p [util_memoize "db_string gp {select count(*) from apm_packages where package_key = 'intranet-ganttproject'}"]


# ---------------------------------------------------------------------
# Get Everything about the project
# ---------------------------------------------------------------------


set extra_selects [list "0 as zero"]
set column_sql "
	select  w.deref_plpgsql_function,
		aa.attribute_name
	from    im_dynfield_widgets w,
		im_dynfield_attributes a,
		acs_attributes aa
	where   a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_project'
"
db_foreach column_list_sql $column_sql {
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"
}
set extra_select [join $extra_selects ",\n\t"]

set query "
select
	p.*,
	c.company_name,
	c.company_path,
	to_char(p.end_date, 'HH24:MI') as end_date_time,
	to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
	to_char(p.end_date, 'YYYY-MM-DD') as end_date_formatted,
	to_char(p.percent_completed, '999990.9%') as percent_completed_formatted,
	c.primary_contact_id as company_contact_id,
	im_name_from_user_id(c.primary_contact_id) as company_contact,
	im_email_from_user_id(c.primary_contact_id) as company_contact_email,
	im_name_from_user_id(p.project_lead_id) as project_lead,
	im_name_from_user_id(p.supervisor_id) as supervisor,
	im_name_from_user_id(c.manager_id) as manager,
	$extra_select
from
	im_projects p, 
	im_companies c

where 
	p.project_id=:project_id
	and p.company_id = c.company_id
"

if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
    return
}

set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]
set parent_name [db_string parent_name "select project_name from im_projects where project_id = :parent_id" -default ""]


# ---------------------------------------------------------------------
# Redirect to timesheet if this is timesheet
# ---------------------------------------------------------------------

# Redirect if this is a timesheet task (subtype of project)
if {$project_type_id == [im_project_type_task]} {
    ad_returnredirect [export_vars -base "/intranet-timesheet2-tasks/new" {{task_id $project_id}}]

}

# ---------------------------------------------------------------------
# Check permissions
# ---------------------------------------------------------------------

# get the current users permissions for this project
im_project_permissions $user_id $project_id view read write admin

# Compatibility with old components...
set current_user_id $user_id
set user_admin_p $write

if {![db_string ex "select count(*) from im_projects where project_id=:project_id"]} {
    ad_return_complaint 1 "<li>Project doesn't exist"
    return
}

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# ---------------------------------------------------------------------
# Set the context bar as a function on whether this is a subproject or not:
# ---------------------------------------------------------------------

set page_title "$project_nr - $project_name"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]

if { [empty_string_p $parent_id] } {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] "[_ intranet-core.One_project]"]
    set include_subproject_p 1
} else {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] [list "/intranet/projects/view?project_id=$parent_id" "[_ intranet-core.One_project]"] "[_ intranet-core.One_subproject]"]
    set include_subproject_p 0
}


# VAW Special: Dont show dates to non-employees
# ToDo: Replace with DynField dynamic field perms
set user_can_see_start_end_date_p [expr [im_user_is_employee_p $current_user_id] || [im_user_is_customer_p $current_user_id]]


# ---------------------------------------------------------------------
# Project Base Data
# ---------------------------------------------------------------------

set project_base_data_html "
			<table border=0>
			  <tr> 
			    <td colspan=2 class=rowtitle align=center>
			      [_ intranet-core.Project_Base_Data]
			    </td>
			  </tr>
			  <tr> 
			    <td>[_ intranet-core.Project_name]</td>
			    <td>$project_name</td>
			  </tr>"

if { ![empty_string_p $parent_id] } { 
    append project_base_data_html "
			  <tr> 
			    <td>[_ intranet-core.Parent_Project]</td>
			    <td>
			      <a href=/intranet/projects/view?project_id=$parent_id>$parent_name</a>
			    </td>
			  </tr>"
}

append project_base_data_html "
			  <tr> 
			    <td>[_ intranet-core.Project]</td>
			    <td>$project_path</td>
			  </tr>
[im_company_link_tr $user_id $company_id $company_name "[_ intranet-core.Client]"]
			  <tr> 
			    <td>[_ intranet-core.Project_Manager]</td>
			    <td>
[im_render_user_id $project_lead_id $project_lead $user_id $project_id]
			    </td>
			  </tr>
			  <tr> 
			    <td>[_ intranet-core.Project_Type]</td>
			    <td>$project_type</td>
			  </tr>
			  <tr> 
			    <td>[_ intranet-core.Project_Status]</td>
			    <td>$project_status</td>
			  </tr>\n"

# VAW Special: Freelancers shouldnt see star and end date
# ToDo: Replace this hard coded condition with DynField
# permissions per field.
if { $user_can_see_start_end_date_p && ![empty_string_p $start_date] } { append project_base_data_html "
			  <tr>
			    <td>[_ intranet-core.Start_Date]</td>
			    <td>[lc_time_fmt $start_date_formatted "%x" locale]</td>
			  </tr>"
}

if { $user_can_see_start_end_date_p && ![empty_string_p $end_date] } { append project_base_data_html "
			  <tr>
			    <td>[_ intranet-core.Delivery_Date]</td>
			    <td>[lc_time_fmt $end_date_formatted "%x" locale] $end_date_time</td>
			  </tr>"
}

append project_base_data_html "
			  <tr>
			    <td>[_ intranet-core.On_Track_Status]</td>
			    <td>[im_project_on_track_bb $on_track_status_id]</td>
			  </tr>"


if { ![empty_string_p $percent_completed] } { append project_base_data_html "
			  <tr>
			    <td>[_ intranet-core.Percent_Completed]</td>
			    <td>$percent_completed_formatted</td>
			  </tr>"
}

if { ![empty_string_p $project_budget_hours] } { append project_base_data_html "
			  <tr>
			    <td>[_ intranet-core.Project_Budget_Hours]</td>
			    <td>$project_budget_hours</td>
			  </tr>"
}

if {[im_permission $current_user_id view_budget]} {
    if { ![empty_string_p $project_budget] } { append project_base_data_html "
			  <tr>
			    <td>[_ intranet-core.Project_Budget]</td>
			    <td>$project_budget $project_budget_currency</td>
			  </tr>"
    }
}



if { ![empty_string_p $company_project_nr] } { 
    append project_base_data_html "
			  <tr>
			    <td>[lang::message::lookup "" intranet-core.Company_Project_Nr "Customer Project Nr"]</td>
			    <td>$company_project_nr</td>
			  </tr>"
}


if { ![empty_string_p $description] } { append project_base_data_html "
			  <tr>
			    <td>[_ intranet-core.Description]</td>
			    <td width=250>$description</td>
			  </tr>"
}


# ---------------------------------------------------------------------
# Add DynField Columns to the display

set column_sql "
	select
		aa.pretty_name,
		aa.attribute_name
	from
		im_dynfield_widgets w,
		acs_attributes aa,
		im_dynfield_attributes a
		LEFT OUTER JOIN (
			select *
			from im_dynfield_layout
			where page_url = ''
		) la ON (a.attribute_id = la.attribute_id)
	where
		a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_project'
	order by
		coalesce(la.pos_y,0), coalesce(la.pos_x,0)
"
db_foreach column_list_sql $column_sql {
    set var ${attribute_name}_deref
    set value [expr $$var]
    if {"" != [string trim $value]} {
		append project_base_data_html "
		  <tr>
		    <td>[lang::message::lookup "" intranet-cust-baselkb.$attribute_name $pretty_name]</td>
		    <td>$value</td>
		  </tr>
		"
    }
}


if {$write && [im_permission $current_user_id edit_project_basedata]} {
	append project_base_data_html "
			  <tr> 
			    <td>&nbsp; </td>
			    <td> 
			      <form action=/intranet/projects/new method=POST>
				  [export_form_vars project_id return_url]
				  <input type=submit value=\"[_ intranet-core.Edit]\" name=submit3>
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

set admin_html_content ""

if {$gantt_project_enabled_p} {
    set help [lang::message::lookup "" intranet-ganttproject.ProjectComponentHelp \
    "GanttProject is a free Gantt chart viewer (http://sourceforge.net/project/ganttproject/)"]
    append admin_html_content "
        <li><A href=\"[export_vars -base "/intranet-ganttproject/gantt-project.gan" {project_id}]\"
        >[lang::message::lookup "" intranet-ganttproject.Download_Gantt_File "Download GanttProject .gan File"]</A>
        [im_gif help $help]
        <li><A href=\"[export_vars -base "/intranet-ganttproject/gantt-upload" {project_id return_url}]\"
        >[lang::message::lookup "" intranet-ganttproject.Upload_Gantt_File "Upload GanttProject .gan File"]</A>
        [im_gif help $help]
    "
}


if {$admin} {
    append admin_html_content "<li><A href=\"/intranet/projects/new?parent_id=$project_id\">[_ intranet-core.Create_a_Subproject]</A>\n"
}

set exec_pr_help [lang::message::lookup "" intranet-core.Execution_Project_Help "An 'Execution Project' is a copy of the current project, but without any references to the project's customers. This options allows you to delegate the management of an 'Execution Project' to freelance project managers etc."]

set clone_pr_help [lang::message::lookup "" intranet-core.Clone_Project_Help "A 'Clone' is an exact copy of your project. You can use this function to standardize repeating projects."]

if {$clone_project_enabled_p && [im_permission $current_user_id add_projects]} {
    append admin_html_content "
    <li><A href=\"[export_vars -base $clone_url { { parent_project_id $project_id } }]\">[lang::message::lookup "" intranet-core.Clone_Project "Clone this project"]</A>[im_gif -translate_p 0 help $clone_pr_help]\n"
}

if {$execution_project_enabled_p && [im_permission $current_user_id add_projects]} {
    append admin_html_content "
    <li><A href=\"[export_vars -base $clone_url { {parent_project_id $project_id} {company_id [im_company_internal]} { clone_postfix "Execution Project"} }]\">[lang::message::lookup "" intranet-core.Execution_Project "Create an 'Execution Project'"]
</A>[im_gif -translate_p 0 help $exec_pr_help]\n"
}

set admin_html ""
if {"" != $admin_html_content} {
    append admin_html_content "\n<p>\n"
    set admin_html [im_table_with_title "[_ intranet-core.Admin_Project]" $admin_html_content]
}


# ---------------------------------------------------------------------
# Project Hierarchy
# ---------------------------------------------------------------------

set super_project_id [im_project_super_project_id $project_id]

# Check permissions for showing subprojects
set perm_sql "
	(select	p.*
	from	im_projects p,
		acs_rels r
	where	r.object_id_one = p.project_id
		and r.object_id_two = :user_id
	)
"
if {[im_permission $user_id "view_projects_all"]} { set perm_sql "im_projects" }


set project_url "/intranet/projects/view"
set space "&nbsp; &nbsp; &nbsp; "


set subproject_status_sql ""
if {$subproject_filtering_enabled_p && "" != $subproject_status_id && 0 != $subproject_status_id} {
    set subproject_status_sql "
	and (
		children.project_status_id in ([join [im_sub_categories $subproject_status_id] ","])
	    OR
		children.project_id = :project_id
	)
    "
}

db_multirow -extend {
    subproject_indent 
    subproject_url 
    subproject_bold_p 
} subprojects project_hierarchy {} {
    
    set subproject_url [export_vars -base $project_url {{project_id $subproject_id}}]
    set subproject_indent ""
    for {set i 0} {$i < $subproject_level} {incr i} { append subproject_indent $space }
    set subproject_bold_p [expr $project_id == $subproject_id]

}


# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id

set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]

ns_log Notice "/project/view: end of view.tcl"

set menu_label "project_summary"
switch $view_name {
    "files" { set menu_label "project_files" }
    "finance" { set menu_label "project_finance" }
    default { set menu_label "project_summary" }
}
set sub_navbar [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" $menu_label] 



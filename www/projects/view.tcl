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
    { subproject_status_id 0 }
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

# Redirect if this is a task, ticket or opportunity
if {([info exists project_id] && $project_id ne "")} {
    # Determine the project_type_id for the project and redirect
    # to specific pages displaying those project types
    set project_type_id [db_string ptype "select project_type_id from im_projects where project_id = :project_id" -default ""]

    if {[im_category_is_a $project_type_id [im_project_type_task]]} {
	ad_returnredirect [export_vars -base "/intranet-timesheet2-tasks/new" {{form_mode display} {task_id $project_id}}]
    }
    if {[im_category_is_a $project_type_id [im_project_type_ticket]]} {
        ad_returnredirect [export_vars -base "/intranet-helpdesk/new" {{form_mode display} {ticket_id $project_id}}]
    }
    if {[im_category_is_a $project_type_id [im_project_type_opportunity]]} {
	ad_returnredirect [export_vars -base "/intranet-crm-opportunities/view" {{opportunity_id $project_id}}]
    }
}

set show_context_help_p 0

set user_id [auth::require_login]
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

set subproject_filtering_enabled_p [im_parameter -package_id [im_package_core_id] SubprojectStatusFilteringEnabledP "" 0]
if {$subproject_filtering_enabled_p} {
    set subproject_filtering_default_status_id [im_parameter -package_id [im_package_core_id] SubprojectStatusFilteringDefaultStatus "" ""]
    if {0 == $subproject_status_id} {
	set subproject_status_id $subproject_filtering_default_status_id 
    }
}

set clone_project_enabled_p [im_parameter -package_id [im_package_core_id] EnableCloneProjectLinkP "" 0]
set new_from_template_enabled_p [im_parameter -package_id [im_package_core_id] EnableNewFromTemplateLinkP "" 0]
set execution_project_enabled_p [im_parameter -package_id [im_package_core_id] EnableExecutionProjectLinkP "" 0]
set gantt_project_enabled_p [util_memoize [list db_string gp "select count(*) from apm_packages where package_key = 'intranet-ganttproject'"]]
set enable_project_path_p [parameter::get -parameter EnableProjectPathP -package_id [im_package_core_id] -default 0] 


# Check if the invoices was changed outside of ]po[...
im_audit -object_id $project_id -action view

# ---------------------------------------------------------------------
# Check permissions
# ---------------------------------------------------------------------

# Global admin?
# Only global admins are allowed to "nuke" projects
set site_wide_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

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

db_1row select_project  "select * from im_projects where project_id = :project_id"

set page_title "$project_nr - $project_name"
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]

if { $parent_id eq "" } {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] "[_ intranet-core.One_project]"]
    set include_subproject_p 1
} else {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] [list "/intranet/projects/view?project_id=$parent_id" "[_ intranet-core.One_project]"] "[_ intranet-core.One_subproject]"]
    set include_subproject_p 0
}


# ---------------------------------------------------------------------
# Admin Box
# ---------------------------------------------------------------------

set admin_html_content ""

# You should not assume that the subproject has the same project_type_id as the old project. If at all we should make this a switch.
if {$admin} {
    append admin_html_content "<li><A href=\"[export_vars -base "/intranet/projects/new" {{parent_id $project_id}}]\">[_ intranet-core.Create_a_Subproject]</A><br></li>\n"


    if {"" eq $parent_id} {
	set scrum_sprint_type_id [im_project_type_scrum]
	set scrum_project_name "$project_name SCRUM Sprint"
	if {[db_string scrum_p "select count(*) from im_categories where category_id = :scrum_sprint_type_id and enabled_p = 't'"]} {
	    append admin_html_content "<li><A href=\"[export_vars -base "/intranet/projects/new" {{parent_id $project_id} {project_type_id $scrum_sprint_type_id} {project_name $scrum_project_name}}]\" target=_>[lang::message::lookup "" intranet-core.Create_a_SCRUM_Sprint "Create a new SCRUM Sprint"]</A><br></li>\n"
	}

	set ticket_container_type_id [im_project_type_ticket_container]
	set ticket_project_name "$project_name Ticket Container"
	if {[db_string ticket_p "select count(*) from im_categories where category_id = :ticket_container_type_id and enabled_p = 't'"]} {
	    append admin_html_content "<li><A href=\"[export_vars -base "/intranet/projects/new" {{parent_id $project_id} {project_type_id $ticket_container_type_id} {project_name $ticket_project_name}}]\" target=_>[lang::message::lookup "" intranet-core.Create_a_Ticket_Container "Create a new Ticket Container"]</A><br></li>\n"
	}
    }
}

# Fraber 130121: NEVER enable nuke.
# Nuking is only OK for demo-data
# if {$site_wide_admin_p} {
#    append admin_html_content "<li><A href=\"[export_vars -base "/intranet/projects/nuke" {project_id}]\">[_ intranet-core.Nuke_this_project]</A><br></li>\n"
# }


if {$clone_project_enabled_p && [im_permission $current_user_id add_projects]} {
    set clone_pr_help [lang::message::lookup "" intranet-core.Clone_Project_Help "A 'Clone' is an exact copy of your project. You can use this function to standardize repeating projects."]

    append admin_html_content "
    <li><A href=\"[export_vars -base $clone_url { { parent_project_id $project_id } }]\">[lang::message::lookup "" intranet-core.Clone_Project "Clone this project"]</A>[im_gif -translate_p 0 help $clone_pr_help]</li>\n"
}

if {$new_from_template_enabled_p && $write} {
    set add_tasks_from_template_help [lang::message::lookup "" intranet-core.Add_tasks_to_project_help "Import all tasks from a template to this project. Existing tasks with the same name will be overwritten."]
    append admin_html_content "
    <li><A href=\"[export_vars -base "/intranet/projects/add-tasks-from-template" { { parent_project_id $project_id } }]\">[lang::message::lookup "" intranet-core.Add_tasks_from_template "Add tasks from template"]</A>[im_gif -translate_p 0 help $add_tasks_from_template_help]</li>\n"
}


if {$execution_project_enabled_p && [im_permission $current_user_id add_projects]} {
    set exec_pr_help [lang::message::lookup "" intranet-core.Execution_Project_Help "An 'Execution Project' is a copy of the current project, but without any references to the project's customers. This options allows you to delegate the management of an 'Execution Project' to freelance project managers etc."]

    append admin_html_content "
    <li><A href=\"[export_vars -base $clone_url { {parent_project_id $project_id} {company_id [im_company_internal]} { clone_postfix "Execution Project"} }]\">[lang::message::lookup "" intranet-core.Execution_Project "Create an 'Execution Project'"]
</A>[im_gif -translate_p 0 help $exec_pr_help]</li>\n"
}

if { [apm_package_enabled_p "intranet-customer-portal"] && ( [im_profile::member_p -profile_id [im_pm_group_id] -user_id $user_id] || [im_profile::member_p -profile_id [im_admin_group_id] -user_id $user_id]) } {
    append admin_html_content "
    <li><A href=\"/intranet-customer-portal/create-dir-structure?project_id=$project_id\">[lang::message::lookup "" intranet-customer-portal.CreateFolderStructure "Create folder structure"]</A></li>\n"
}


# ---------------------------------------------------------------------
# Import/Export Box
# ---------------------------------------------------------------------

set export_html_content ""

if {$gantt_project_enabled_p} {
    set help [lang::message::lookup "" intranet-ganttproject.ProjectComponentHelp \
    "GanttProject is a free Gantt chart viewer (http://sourceforge.net/project/ganttproject/)"]
    
    if {$read && [im_permission $current_user_id "view_gantt_proj_detail"]} {
	append export_html_content "
        <li><A href=\"[export_vars -base "/intranet-ganttproject/microsoft-project.xml" {project_id}]\"
        >[lang::message::lookup "" intranet-ganttproject.Export_to_MS_Projectj "Export to Microsoft Project"]</A>
<!--	<a href=\"http://www.sourceforge.net/projects/projectlibre\"><img src=/intranet/images/external.png></a> -->
	</li>
        <li><A href=\"[export_vars -base "/intranet-ganttproject/microsoft-project.xml" {project_id}]\"
        >[lang::message::lookup "" intranet-ganttproject.Export_to_ProjectLibre "Export to ProjectLibre"]</A>
<!--	<a href=\"http://www.sourceforge.net/projects/projectlibre\"><img src=/intranet/images/external.png></a> -->
	</li>
        <li><A href=\"[export_vars -base "/intranet-ganttproject/gantt-project.gan" {project_id}]\"
        >[lang::message::lookup "" intranet-ganttproject.Export_to_GanttProject "Export to GanttProject"]</A>
<!--	<a href=\"http://www.sourceforge.net/projects/ganttproject\"><img src=/intranet/images/external.png></a> -->
	</li>
	<br>\n"
    }

    if {$write && [im_permission $current_user_id "view_gantt_proj_detail"]} {
        append export_html_content "
        <li><A href=\"[export_vars -base "/intranet-ganttproject/gantt-upload" {project_id return_url {import_type gantt_project}}]\"
        >[lang::message::lookup "" intranet-ganttproject.Import_from_Microsoft_Project "Import from Microsoft Project"]</A>
	</li>\n"

        append export_html_content "
        <li><A href=\"[export_vars -base "/intranet-ganttproject/gantt-upload" {project_id return_url {import_type gantt_project}}]\"
        >[lang::message::lookup "" intranet-ganttproject.Import_from_Project_Libre "Import from Project Libre"]</A>
	</li>\n"

        append export_html_content "
        <li><A href=\"[export_vars -base "/intranet-ganttproject/gantt-upload" {project_id return_url {import_type gantt_project}}]\"
        >[lang::message::lookup "" intranet-ganttproject.Import_from_Gantt_Project "Import from Gantt Project"]</A>
	</li>\n"

	if {0} {
        append export_html_content "
	</ul><br><ul>
        <li><A href=\"[export_vars -base "/intranet-ganttproject/taskjuggler" {project_id}]\"
        >[lang::message::lookup "" intranet-ganttproject.Schedule_project_using_TaskJuggler "Schedule project using TaskJuggler (alpha)"]</A></li>
	"
	}
    }
}

# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [im_menu_id_from_label "project"]
set menu_label "project_summary"
switch $view_name {
    "files" { set menu_label "project_files" }
    "finance" { set menu_label "project_finance" }
    default { 
	set menu_label "project_summary" 
	set show_context_help_p 1
    }
}

set sub_navbar [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" $menu_label] 



set left_navbar_html ""
if {"" != $admin_html_content} {
    append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>
		[lang::message::lookup "" intranet-core.Admin_Project "Admin Project"]
        </div>
	<ul>$admin_html_content</ul>
      	</div>
	<hr/>
    "
}


if {"" != $export_html_content} {
    append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>
		[lang::message::lookup "" intranet-core.Import_and_Export "Import & Export"]
        </div>
	<ul>$export_html_content</ul>
      	</div>
    "
}

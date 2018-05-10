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
    parent_project_id:integer,notnull
    template_project_id:integer,notnull
    { clone_postfix "clone" }
    { return_url "" }
    { debug_p 0 }
}


# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set current_user_id [auth::require_login]
set required_field "<font color=red size=+1><B>*</B></font>"
set page_title [lang::message::lookup "" intranet-core.Add_tasks_from_template "Add tasks from template"]

# Make sure the user can read the parent_project
im_project_permissions $current_user_id $parent_project_id parent_view parent_read parent_write parent_admin
if {!$parent_read} {
    ad_return_complaint "Insufficient Privileges" "
	<li>You don't have sufficient privileges to see this page."
    return
}


# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

# Use a list of tasks and then "foreach" in order to avoid nested SQLs
set task_list [db_list tasks "
		select	project_id
		from	im_projects
		where 	parent_id = :template_project_id
"]


foreach task_id $task_list {
    db_1row project_info "
		select	p.project_nr || '_' || :parent_project_id as sub_task_nr,
			p.project_name || '_' || :parent_project_id as sub_task_name,
			p.project_nr as sub_task_nr_org,
			p.project_name as sub_task_name_org,
			p.company_id
		from	im_projects p
		where	project_id = :task_id
    "

    # go for the next project
    set tuple [im_project_clone \
		   -debug_p $debug_p \
		   -clone_costs_p 0 -clone_files_p 0 -clone_subprojects_p 1 -clone_forum_topics_p 0\
		   -clone_members_p 0 -clone_timesheet_tasks_p 1 -clone_target_languages_p 0 \
		   -clone_level 0 \
		   -company_id $company_id \
		   $task_id \
		   $sub_task_name \
		   $sub_task_nr \
		   $clone_postfix \
    ]
    set cloned_task_id [lindex $tuple 0]
    set cloned_mapping_hash_list [lindex $tuple 1]
    append errors [lindex $tuple 2]

    # ad_return_complaint 1 "clone=$cloned_task_id, parent=$parent_project_id, template=$template_project_id, tasks=$task_list"

    # We can _now_ reset the subtasks's name to the original one
    db_dml set_parent "
		update	im_projects
		set	parent_id = :parent_project_id,
			project_nr = :sub_task_nr_org,
			project_name = :sub_task_name_org,
			template_p = 'f'
		where
			project_id = :cloned_task_id
    "

    if {[db_0or1row task_info "
			select	material_id, uom_id,
	                        planned_units, billable_units,
	                        cost_center_id, invoice_id, priority, sort_order
			from	im_timesheet_tasks
			where	task_id = :task_id
    "]
    } {
	# Insert a task
	db_dml insert_task "
		insert into im_timesheet_tasks (
			task_id, material_id, uom_id,
			planned_units, billable_units,
			cost_center_id, invoice_id, priority, sort_order
		) values (
			:cloned_task_id, :material_id, :uom_id,
			:planned_units, :billable_units,
			:cost_center_id, :invoice_id, :priority, :sort_order
		)
	        "
    }

    # update acs_object
    db_dml update_acs_objects "
		update acs_objects set object_type = 'im_timesheet_task' where object_id = :cloned_task_id 
    "
}

if {"" == $return_url} { 
    set return_url [export_vars -base "/intranet/projects/view" {{project_id $parent_project_id}}]
}

ad_returnredirect $return_url




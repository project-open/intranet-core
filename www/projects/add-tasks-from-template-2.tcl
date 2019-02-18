# /packages/intranet-core/projects/add-tasks-from-template-2.tcl
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
set parent_project_name [db_string pname "select acs_object__name(:parent_project_id)"]
set page_title "$parent_project_name: [lang::message::lookup "" intranet-core.Add_tasks_from_template "Add tasks from template"]"

# Make sure the user can read the parent_project
im_project_permissions $current_user_id $parent_project_id parent_view parent_read parent_write parent_admin
if {!$parent_read} {
    ad_return_complaint "Insufficient Privileges" "
	<li>You don't have sufficient privileges to see this page."
    return
}



# ---------------------------------------------------------------------
# Check for locking / double click protection
# ---------------------------------------------------------------------

set exists_p [db_0or1row recently_changed "
	select	extract(epoch from now() - lock_date) as lock_seconds,
		lock_user,
		im_name_from_user_id(lock_user) as lock_user_name,
		lock_ip
	from	im_biz_objects
	where	object_id = :parent_project_id
"]

if {$exists_p && $current_user_id eq $lock_user && $lock_seconds < 2.0} {
    exec sleep 3
    ad_returnredirect [export_vars -base "/intranet/projects/view" {{project_id $parent_project_id}}]
} else {
    # Set the lock on the ticket
    db_dml set_lock "
		update im_biz_objects set
			lock_ip = '[ns_conn peeraddr]',
			lock_date = now(),
			lock_user = :current_user_id
		where object_id = :parent_project_id
    "
}


# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

# Use a list of tasks and then "foreach" in order to avoid nested SQLs
set task_list [db_list tasks "
		select	project_id
		from	im_projects
		where 	parent_id = :template_project_id
		order by project_id
"]


set errors [list]
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

    # Check if a 1st level task with that name or nr already exists in the parent project
    set exists_p [db_string tasks_exists_p "
	select	count(*)
	from	im_projects p
	where	p.parent_id = :parent_project_id and
		(p.project_name = :sub_task_name_org OR p.project_nr = :sub_task_nr_org)
    "]

    if {$exists_p} {
	set project_name $sub_task_name_org
	lappend errors [lang::message::lookup "" intranet-core.Task_task_already_exists "Task '%project_name%' already exists in project '%parent_project_name%' - skipping."]
	continue
    }

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
    set error [lindex $tuple 2]
    if {"" eq $cloned_task_id || 0 eq $cloned_task_id} { lappend errors $error }

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

if {[llength $errors] > 0} {
    ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-core.There_were_errors_during_import "There were errors during the import"]</b><br>
    <ul><li>[join $errors "</li>\n<li>"]</ul>"
}

ad_returnredirect $return_url




# /packages/intranet-core/tcl/intranet-audit-procs.tcl
#
# Copyright (C) 2007 ]project-open[
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


ad_library {
    Auditing of important objects

    @author frank.bergmann@project-open.com
}


# -------------------------------------------------------------------
# Audit Sweeper - Make a copy of all "active" projects
# -------------------------------------------------------------------

ad_proc -public im_core_audit_sweeper  {
} {
    Make a copy of all "active" projects
} {
    set audit_exists_p [util_memoize "db_table_exists im_projects_audit"]
    if {!$audit_exists_p} { return }

    # Make sure that only one thread is sweeping at a time
    if {[nsv_incr intranet_core audit_sweep_semaphore] > 1} {
        nsv_incr intranet_core audit_sweep_semaphore -1
        ns_log Notice "im_core_audit_sweeper: Aborting. There is another process running"
        return "busy"
    }

    set debug ""
    set err_msg ""
    set counter 0
    catch {
	set interval_hours [parameter::get_from_package_key \
		-package_key intranet-core \
		-parameter AuditProjectProgressIntervalHours \
		-default 0 \
        ]

	set interval_hours 1

	# Select all "active" (=not deleted or canceled) main projects
	# without an update in the last X hours
	set project_sql "
	select	project_id
	from	im_projects
	where	parent_id is null and
		project_status_id not in (
			[im_project_status_deleted], 
			[im_project_status_canceled]
		) and
		project_id not in (
			select	distinct project_id
			from	im_projects_audit
			where	last_modified > (now() - '$interval_hours hours'::interval)
		)
	LIMIT 10
        "
	db_foreach audit $project_sql {
	    append debug [im_project_audit $project_id]
	    lappend debug $project_id
	    incr counter
	}
    } err_msg

    # Free the semaphore for next use
    nsv_incr intranet_core audit_sweep_semaphore -1

    return [string trim "$counter $debug $err_msg"]
}


# -------------------------------------------------------------------
# 
# -------------------------------------------------------------------

ad_proc -public im_project_audit  {
    { -action update }
    project_id
} {
    Creates an audit entry of the specified project
} {
    # No audit for non-existing projects
    if {"" == $project_id} { return "project_id is empty" }
    if {0 == $project_id} { return "project_id = 0" }

    # Make sure the table exists (compatibility)
    set audit_exists_p [util_memoize "db_table_exists im_projects_audit"]
    if {!$audit_exists_p} { return "Audit table doesn't exist" }

    # No audit for tasks
    set project_type_id [util_memoize "db_string ptype \"select project_type_id from im_projects where project_id=$project_id\" -default 0"]
    if {$project_type_id == [im_project_type_task]} { return "Project is a task" }

    # Parameter to enable/disable project audit
    set audit_projects_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "AuditProjectsP" -default 1]
    if {!$audit_projects_p} { return "Audit not enabled" }


    # Who is modifying? Use empty values when called from schedules proc sweeper
    if {[ad_conn -connected_p]} {
	set modifying_user [ad_get_user_id]
	set modifying_ip [ad_conn peeraddr]
    } else {
	set modifying_user ""
	set modifying_ip ""
    }

    catch {

	db_dml audit "
	    insert into im_projects_audit (
		modifying_action,
		last_modified,		last_modifying_user,		last_modifying_ip,
		project_id,		project_name,			project_nr,
		project_path,		parent_id,			company_id,
		project_type_id,	project_status_id,		description,
		billing_type_id,	note,				project_lead_id,
		supervisor_id,		project_budget,			corporate_sponsor,
		percent_completed,	on_track_status_id,		project_budget_currency,
		project_budget_hours,	end_date,			start_date,
		company_contact_id,	company_project_nr,		final_company,
		cost_invoices_cache,	cost_quotes_cache,		cost_delivery_notes_cache,
		cost_bills_cache,	cost_purchase_orders_cache,	reported_hours_cache,
		cost_timesheet_planned_cache,	cost_timesheet_logged_cache,
		cost_expense_planned_cache,	cost_expense_logged_cache
	    ) 
	    select
		:action,		
		now(),			:modifying_user,		:modifying_ip,
		project_id,		project_name,			project_nr,
		project_path,		parent_id,			company_id,
		project_type_id,	project_status_id,		description,
		billing_type_id,	note,				project_lead_id,
		supervisor_id,		project_budget,			corporate_sponsor,
		percent_completed,	on_track_status_id,		project_budget_currency,
		project_budget_hours,	end_date,			start_date,
		company_contact_id,	company_project_nr,		final_company,
		cost_invoices_cache,	cost_quotes_cache,		cost_delivery_notes_cache,
		cost_bills_cache,	cost_purchase_orders_cache,	reported_hours_cache,
		cost_timesheet_planned_cache,	cost_timesheet_logged_cache,
		cost_expense_planned_cache,	cost_expense_logged_cache
	    from	im_projects
	    where	project_id = :project_id
        "
    } err_msg

    return $err_msg
}




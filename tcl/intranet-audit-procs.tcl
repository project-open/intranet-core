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
# 
# -------------------------------------------------------------------

ad_proc -public im_project_audit  {
    project_id
} {
    Creates an audit entry of the specified project
} {
    set audit_exists_p [util_memoize "db_table_exists im_projects_audit"]
    if {!$audit_exists_p} { return }

    set modifying_user [ad_get_user_id]
    set modifying_ip [ad_conn peeraddr]

    db_dml audit "
	insert into im_projects_audit (
		last_modified,		last_modifying_user,		last_modifying_ip,
		project_id,		project_name,			project_nr,
		project_path,		parent_id,			company_id,
		project_type_id,	project_status_id,		description,
		billing_type_id,	note,				project_lead_id,
		supervisor_id,		project_budget,			corporate_sponsor,
		percent_completed,	on_track_status_id,		project_budget_currency,
		project_budget_hours,	end_date,			start_date,
		company_contact_id,	company_project_nr,		final_company
	) 
	select
		now(),			:modifying_user,		:modifying_ip,
		project_id,		project_name,			project_nr,
		project_path,		parent_id,			company_id,
		project_type_id,	project_status_id,		description,
		billing_type_id,	note,				project_lead_id,
		supervisor_id,		project_budget,			corporate_sponsor,
		percent_completed,	on_track_status_id,		project_budget_currency,
		project_budget_hours,	end_date,			start_date,
		company_contact_id,	company_project_nr,		final_company
	from	im_projects
	where	project_id = :project_id
    "
}


# /package/intranet-core/projects/upload-projects-sample.csv.tcl
#
# Copyright (C) 2011 ]project-open[
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
    Create a sample projects.csv file from current projects
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date July 2011
} {
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "projects.csv Sample"


set csv [im_ad_hoc_query \
	-format csv \
	-translate_p 0 \
"
	select	
		-- Base attributes (not null)
		c.company_name as customer_name,
		im_project_nr_parent_list(p.parent_id) as parent_nrs,
		p.project_nr,
		p.project_name,
		im_category_from_id(p.project_status_id) as project_status,
		im_category_from_id(p.project_type_id) as project_type,
		to_date(p.start_date, 'YYYY-MM-DD') as start_date,
		to_date(p.end_date, 'YYYY-MM-DD') as end_date,
		
		im_name_from_user_id(p.company_contact_id) as customer_contact,
		im_category_from_id(p.on_track_status_id) as on_track_status,
		p.percent_completed,
		im_name_from_user_id(p.project_lead_id) as project_manager,
		im_category_from_id(p.project_priority_id) as project_priority,
		-- im_name_from_user_id(p.supervisor_id) as supervisor,
		im_project_name_from_id(p.program_id) as program,
		p.milestone_p,
		p.description,
		p.note,

		-- Timesheet Tasks
		im_material_name_from_id(tt.material_id) as material,
		im_category_from_id(tt.uom_id) as uom,
		tt.planned_units,
		tt.billable_units,
		im_cost_center_code_from_id(tt.cost_center_id) as cost_center_code,
		tt.priority as timesheet_task_priority,
		tt.sort_order,

		-- Budget
		p.project_budget,
		p.project_budget_currency,
		p.project_budget_hours,

		-- Presales
		p.presales_probability,
		p.presales_value,

		-- Auxillary
		p.project_path,
		p.confirm_date,

		-- Translation
		im_category_from_id(p.source_language_id) as source_language,
		im_category_from_id(p.subject_area_id) as subject_area,
		p.final_company,
		im_category_from_id(p.expected_quality_id) as expected_quality,
		p.company_project_nr as customer_project_nr

	from	im_projects p
		LEFT OUTER JOIN im_timesheet_tasks tt ON (p.project_id = tt.task_id)
		LEFT OUTER JOIN im_companies c ON (p.company_id = c.company_id)
		LEFT OUTER JOIN acs_objects o ON (p.project_id = o.object_id)
"]

# Convert into Latin-1 for Excel support
set csv [encoding convertto "iso8859-1" $csv]


# doc_return 200 "application/csv" $csv
doc_return 200 "test/plain" $csv


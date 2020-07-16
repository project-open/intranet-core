-- 5.0.3.0.3-5.0.3.0.4.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.3.0.3-5.0.3.0.4.sql','');

-- drop view before changing the size of the im_projects fields
drop view if exists im_timesheet_tasks_view;


alter table im_projects alter column project_name type text;
alter table im_projects alter column project_nr type text;
alter table im_projects alter column project_path type text;
alter table im_projects alter column project_risk type text;

alter table im_projects alter column description type text;
alter table im_projects alter column note type text;


-- re-create the view
create or replace view im_timesheet_tasks_view as
select	t.*,
	p.parent_id as project_id,
	p.project_name as task_name,
	p.project_nr as task_nr,
	p.percent_completed,
	p.project_type_id as task_type_id,
	p.project_status_id as task_status_id,
	p.start_date,
	p.end_date,
	p.reported_hours_cache,
	p.reported_days_cache,
	p.reported_hours_cache as reported_units_cache
from
	im_projects p,
	im_timesheet_tasks t
where
	t.task_id = p.project_id
;

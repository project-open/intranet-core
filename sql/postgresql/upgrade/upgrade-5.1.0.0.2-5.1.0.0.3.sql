SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.1.0.0.2-5.1.0.0.3.sql','');


update acs_object_types
set supertype = 'im_timesheet_task'
where object_type = 'im_gantt_project';


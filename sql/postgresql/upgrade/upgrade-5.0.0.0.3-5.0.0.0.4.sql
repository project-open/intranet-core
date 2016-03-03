-- upgrade-5.0.0.0.3-5.0.0.0.4.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.0.0.3-5.0.0.0.4.sql','');

-- Add a new constraint to avoid projects that end before they start.
update im_projects set end_date = start_date where end_date < start_date;
alter table im_projects add constraint im_projects_start_end_chk check(end_date >= start_date);


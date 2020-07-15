-- 5.0.3.0.3-5.0.3.0.4.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.3.0.3-5.0.3.0.4.sql','');


alter table im_projects alter column project_name type text;
alter table im_projects alter column project_nr type text;
alter table im_projects alter column project_path type text;
alter table im_projects alter column project_risk type text;

alter table im_projects alter column description type text;
alter table im_projects alter column note type text;


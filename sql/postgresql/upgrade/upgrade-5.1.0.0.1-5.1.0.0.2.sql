SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.1.0.0.1-5.1.0.0.2.sql','');

alter table im_audits drop constraint im_audits_action_ck;
alter table im_audits add constraint im_audits_action_ck 
      check (audit_action in ('after_create','before_update','after_update','before_nuke', 'view', 'view_fixed', 'baseline'));


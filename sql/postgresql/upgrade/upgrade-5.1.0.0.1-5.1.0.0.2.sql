SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.1.0.0.1-5.1.0.0.2.sql','');

alter table im_audits drop constraint im_audits_action_ck;
alter table im_audits add constraint im_audits_action_ck 
      check (audit_action in ('after_create','before_update','after_update','before_nuke', 'view', 'view_fixed', 'baseline'));


/*

set invoice_ids [db_list invoice_ids "select invoice_id from im_invoices"]
foreach id $invoice_ids {
  append debug "\n$id"
  im_audit -object_id $id -action "view"
}
set debug

*/


update im_audits set audit_action = 'view_fixed' where audit_action = 'view';

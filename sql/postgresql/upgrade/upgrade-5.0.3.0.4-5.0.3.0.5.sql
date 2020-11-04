SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.3.0.4-5.0.3.0.5.sql','');



delete from im_view_columns where column_id = 2500;

insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl, visible_for) 
values (25,2500,0,'<input id=list_check_all type=checkbox name=_dummy>','$select_checkbox', 'expr $bulk_actions_p');

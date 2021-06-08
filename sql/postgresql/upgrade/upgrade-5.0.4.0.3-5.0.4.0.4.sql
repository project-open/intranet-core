SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.4.0.3-5.0.4.0.4.sql','');



update im_view_columns set column_render_tcl = '$project_budget' where column_render_tcl = '"$project_budget $project_budget_currency"';
update im_view_columns set column_render_tcl = 'EUR' where column_render_tcl = '$project_budget_currency';


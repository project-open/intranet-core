SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.4.0.3-5.0.4.0.4.sql','');


update im_menus
set parent_menu_id = (select menu_id from im_menus where label = 'portfolio')
where label in (
	'project_portfolio_list',
	'risk_vs_roi',
	'strategic_vs_roi',
	'projects_resources_assignation_percentage',
	'portfolio_planner',
	'capacity-planning',
	'portfolio_dashboard',
	'resource_management_home',
	'projects_admin_gantt_resources',
	'resource_management',
	'portfolio_planner2'
);



update im_menus set url = '/intranet/projects/dashboard' where label = 'portfolio';

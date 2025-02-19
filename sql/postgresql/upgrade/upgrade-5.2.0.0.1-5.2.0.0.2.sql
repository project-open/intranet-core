SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.2.0.0.1-5.2.0.0.2.sql','');



-- Allow both customers and freelancers to access the REST reports
-- They are all built to take in the user_id of the user for perms.
select	menu_id,
	label,
	name,
	acs_permission__grant_permission(menu_id, g.group_id, 'read')
from
	im_menus m,
	im_reports r,
	groups g
where
	m.parent_menu_id in (select menu_id from im_menus where label = 'reporting-rest') and
	r.report_menu_id = m.menu_id and
	g.group_name in ('Freelancers', 'Employees', 'Customers');


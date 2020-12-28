SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-5.0.4.0.0-5.0.4.0.1.sql','');


create or replace function inline_0 ()
returns integer as $body$
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu from im_menus where label = 'projects';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null, 'im_menu', now(), null, null, null,
		'intranet-core',	-- package_name
		'project_admin',	-- label
		'Project Admin',	-- name
		'/intranet-core/',	-- url
		95,			-- sort_order
		v_main_menu,		-- parent_menu_id
		'0'			-- p_visible_tcl
	);

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

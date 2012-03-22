-- /packages/intranet/sql/oracle/intranet-menu-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

---------------------------------------------------------
-- Menus
--
-- Dynamic Menus are necessary to allow modules
-- to extend the core at some point in the future without
-- that core would need know about these extensions in
-- advance.
--
-- Menus entries are basically mappings from a Name into a URL.
--
-- In addition, menu entries contain a parent_menu_id,
-- allowing for a tree view of all menus (to build a left-
-- hand-side navigation bar).
--
-- The same parent_menu_id field allows a particular page 
-- to find out about its submenus items to display by checking 
-- the super-menu that points to the page and by selecting
-- all of its sub-menu-items. However, the develpers needs to
-- avoid multiple menu pointers to the same page because
-- this leads to an ambiguity about the supermenu.
-- These ambiguities are resolved by taking the menu from
-- the highest possible hierarchy level and then using the
-- lowest sort_key.


SELECT acs_object_type__create_type (
	'im_menu',		-- object_type
	'Menu',			-- pretty_name
	'Menus',		-- pretty_plural
	'acs_object',		-- supertype
	'im_menus',		-- table_name
	'menu_id',		-- id_column
	'im_menu',		-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_menu.name'		-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_menu', 'im_menus', 'menu_id');

update acs_object_types set 
	status_type_table = NULL, 
	status_column = NULL, 
	type_column = NULL 
where object_type = 'im_menu';



-- The idea is to use OpenACS permissions in the future to
-- control who should see what menu.

CREATE TABLE im_menus (
	menu_id 		integer
				constraint im_menu_id_pk
				primary key
				constraint im_menu_id_fk
				references acs_objects,
				-- used to remove all menus from one package
				-- when uninstalling a package
	package_name		varchar(200) not null,
				-- symbolic name of the menu that cannot be
				-- changed using the menu editor.
				-- It cat be used as a constant by TCL pages to
				-- locate their menus.
	label			varchar(200) not null,
				-- the name that should appear on the tab
	name			varchar(200) not null,
				-- On which pages should the menu appear?
	url			varchar(200) not null,
				-- sort order WITHIN the same level
	sort_order		integer,
				-- parent_id allows for tree view for navbars
	parent_menu_id		integer
				constraint im_parent_menu_id_fk
				references im_menus,	
				-- hierarchical codification of menu levels
	tree_sortkey		varchar(100),
				-- TCL expression that needs to be either null
				-- or evaluate (expr *) to 1 in order to display 
				-- the menu.
	visible_tcl		text default null,
				-- Managmenent of different configurations
	enabled_p		char(1) default('t')
				constraint im_menus_enabled_ck
				check (enabled_p in ('t','f')),
				-- small gif for menu - typically 16x16 GIF
	menu_gif_small		text,
				-- medium gif for menu - typically 32x32 GIF
	menu_gif_medium		text,
				-- large gif for menu - typically 64x64 GIF
	menu_gif_large		text,
				-- Make sure there are no two identical
				-- menus on the same _level_.
	constraint im_menus_label_un
	unique(label)
);

create or replace function im_menu__new (integer, varchar, timestamptz, integer, varchar, integer,
varchar, varchar, varchar, varchar, integer, integer, varchar) returns integer as '
declare
	p_menu_id		alias for $1;	-- default null
	p_object_type		alias for $2;	-- default acs_object
	p_creation_date		alias for $3;	-- default now()
	p_creation_user		alias for $4;	-- default null
	p_creation_ip		alias for $5;	-- default null
	p_context_id		alias for $6;	-- default null

	p_package_name		alias for $7;
	p_label			alias for $8;
	p_name			alias for $9;
	p_url			alias for $10;
	p_sort_order		alias for $11;
	p_parent_menu_id	alias for $12;
	p_visible_tcl		alias for $13;  -- default null

	v_menu_id		im_menus.menu_id%TYPE;
begin
	select	menu_id into v_menu_id
	from	im_menus m where m.label = p_label;
	IF v_menu_id is not null THEN return v_menu_id; END IF;

	v_menu_id := acs_object__new (
		p_menu_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,  	-- creation_ip
		p_context_id		-- context_id
	);

	insert into im_menus (
		menu_id, package_name, label, name, 
		url, sort_order, parent_menu_id, visible_tcl
	) values (
		v_menu_id, p_package_name, p_label, p_name, p_url, 
		p_sort_order, p_parent_menu_id, p_visible_tcl
	);
	return v_menu_id;
end;' language 'plpgsql';



-- Delete a single menu (if we know its ID...)
-- Delete a single component
create or replace function im_menu__delete (integer) returns integer as '
DECLARE
	p_menu_id	alias for $1;
BEGIN
	-- Erase the im_menus item associated with the id
	delete from 	im_menus
	where		menu_id = p_menu_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = p_menu_id;
	
	PERFORM acs_object__delete(p_menu_id);
	return 0;
end;' language 'plpgsql';


-- Delete all menus of a module.
-- Used in <module-name>-drop.sql
create or replace function im_menu__del_module (varchar) returns integer as '
DECLARE
	p_module_name	alias for $1;
	row		RECORD;
BEGIN
	-- First we have to delete the references to parent menus...
	for row in 
		select menu_id
		from im_menus
		where package_name = p_module_name
	loop

		update im_menus 
		set parent_menu_id = null
		where menu_id = row.menu_id;

	end loop;

	-- ... then we can delete the menus themseves
	for row in 
		select menu_id
		from im_menus
		where package_name = p_module_name
	loop

		PERFORM im_menu__delete(row.menu_id);

	end loop;

	return 0;
end;' language 'plpgsql';


-- Returns the name of the menu
create or replace function im_menu__name (integer) returns varchar as '
DECLARE
	p_menu_id	alias for $1;
	v_name		im_menus.name%TYPE;
BEGIN
	select	name into v_name from im_menus
	where	menu_id = p_menu_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_new_menu (varchar, varchar, varchar, varchar, integer, varchar, varchar) 
returns integer as '
declare
	p_package_name		alias for $1;
	p_label			alias for $2;
	p_name			alias for $3;
	p_url			alias for $4;
	p_sort_order		alias for $5;
	p_parent_menu_label	alias for $6;
	p_visible_tcl		alias for $7;

	v_menu_id		integer;
	v_parent_menu_id	integer;
begin
	-- Check for duplicates
	select	menu_id into v_menu_id
	from	im_menus m where m.label = p_label;
	IF v_menu_id is not null THEN return v_menu_id; END IF;

	-- Get parent menu
	select	menu_id into v_parent_menu_id
	from	im_menus m where m.label = p_parent_menu_label;

	v_menu_id := im_menu__new (
		null,					-- p_menu_id
		''im_menu'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		p_package_name,
		p_label,
		p_name,
		p_url,
		p_sort_order,
		v_parent_menu_id,
		p_visible_tcl
	);

	return v_menu_id;
end;' language 'plpgsql';



create or replace function im_new_menu_perms (varchar, varchar) 
returns integer as '
declare
	p_label			alias for $1;
	p_group			alias for $2;
	v_menu_id		integer;
	v_group_id		integer;
begin
	select	menu_id into v_menu_id
	from	im_menus where label = p_label;

	select	group_id into v_group_id
	from	groups where lower(group_name) = lower(p_group);

	PERFORM acs_permission__grant_permission(v_menu_id, v_group_id, ''read'');
	return v_menu_id;
end;' language 'plpgsql';




-- -----------------------------------------------------
-- Main Menu
-- -----------------------------------------------------


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_top_menu		integer;
	v_main_menu		integer;
	v_home_menu		integer;
	v_user_menu		integer;
	v_project_menu		integer;
	v_company_menu		integer;
	v_office_menu		integer;
	v_help_menu		integer;
	v_user_orgchart_menu	integer;
	v_user_all_menu		integer;
	v_user_freelancers_menu	integer;
	v_user_companies_menu	integer;
	v_user_employees_menu	integer;
	v_project_status_menu	integer;
	v_project_standard_menu	integer;
	v_admin_menu		integer;
	v_admin_categories_menu	integer;
	v_admin_matrix_menu	integer;
	v_admin_parameters_menu	integer;
	v_admin_profiles_menu	integer;
	v_admin_menus_menu	integer;
	v_admin_home_menu	integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';


	-- The top menu - the father of all menus.
	-- It is not displayed itself and only serves
	-- as a parent_menu_id from main and project.
	v_top_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''top'',		-- label
		''Top Menu'',		-- name
		''/'',			-- url
		10,			-- sort_order
		null,			-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_top_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_top_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_top_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_top_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_top_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_top_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_top_menu, v_freelancers, ''read'');


	-- The Main menu: It''s not displayed itself neither
	-- but serves as the starting point for the main menu
	-- hierarchy.
	v_main_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''main'',		-- label
		''Main Menu'',		-- name
		''/'',			-- url
		10,			-- sort_order
		v_top_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	v_home_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''home'',		-- label
		''Home'',		-- name
		''/intranet/'',		-- url
		10,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_home_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_home_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_home_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_home_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_home_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_home_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_home_menu, v_freelancers, ''read'');

	v_project_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''projects'',			-- label
		''Projects'',			-- name
		''/intranet/projects/'',	-- url
		40,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_project_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_project_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_project_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_project_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_project_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_project_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_project_menu, v_freelancers, ''read'');

	v_company_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''companies'',			-- label
		''Companies'',			-- name
		''/intranet/companies/'',	-- url
		50,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_company_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_company_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_company_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_company_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_company_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_company_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_company_menu, v_freelancers, ''read'');

	v_user_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''user'',		-- label
		''Users'',		-- name
		''/intranet/users/'',	-- url
		30,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_user_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_user_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_user_menu, v_employees, ''read'');


	v_office_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''offices'',		-- label
		''Offices'',		-- name
		''/intranet/offices/'', -- url
		40,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_office_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_office_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_office_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_office_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_office_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_office_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_office_menu, v_freelancers, ''read'');

	v_admin_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''admin'',		-- label
		''Admin'',		-- name
		''/intranet/admin/'',	-- url
		999,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_admin_menu, v_admins, ''read'');

	v_help_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''help'',		-- label
		''Help'',		-- name
		''/intranet/help/'',	-- url
		990,			-- sort_order
		v_main_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_help_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_help_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_help_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_help_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_help_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_help_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_help_menu, v_freelancers, ''read'');


	-- -----------------------------------------------------
	-- Users Submenu
	-- -----------------------------------------------------

	v_user_employees_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''users_employees'',	-- label
		''Employees'',		-- name
		''/intranet/users/index?user_group_name=Employees'',	-- url
		1,			-- sort_order
		v_user_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_user_employees_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_user_employees_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_employees_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_employees_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_user_employees_menu, v_employees, ''read'');


	v_user_companies_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''users_customers'',	-- label
		''Customers'',		-- name
		''/intranet/users/index?user_group_name=Customers'',	-- url
		2,			-- sort_order
		v_user_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_user_companies_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_user_companies_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_companies_menu, v_accounting, ''read'');


	v_user_freelancers_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''users_freelancers'',	-- label
		''Freelancers'',	-- name
		''/intranet/users/index?user_group_name=Freelancers'',   -- url
		3,			-- sort_order
		v_user_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);


	PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_employees, ''read'');

	v_user_all_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''users_unassigned'',   -- label
		''Unassigned'',		-- name
		''/intranet/users/index?user_group_name=Unregistered&view_name=user_community&order_by=Creation'',   -- url
		4,			-- sort_order
		v_user_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_user_all_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_user_all_menu, v_senman, ''read'');

	v_user_all_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''users_all'',		-- label
		''All Users'',		-- name
		''/intranet/users/index?user_group_name=All'',   -- url
		5,			-- sort_order
		v_user_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_user_all_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_user_all_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_all_menu, v_accounting, ''read'');

	-- -----------------------------------------------------
	-- Administration Submenu
	-- -----------------------------------------------------

	v_admin_home_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''admin_home'',		-- label
		''Admin Home'',		-- name
		''/intranet/admin/'',   -- url
		10,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_admin_home_menu, v_admins, ''read'');


	v_admin_profiles_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''admin_profiles'',	-- label
		''Profiles'',		-- name
		''/intranet/admin/profiles/'',   -- url
		15,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_admin_profiles_menu, v_admins, ''read'');


	v_admin_menus_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''admin_menus'',	-- label
		''Menus'',		-- name
		''/intranet/admin/menus/'',   -- url
		20,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_admin_profiles_menu, v_admins, ''read'');


	v_admin_matrix_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''admin_usermatrix'',   -- label
		''User Matrix'',	-- name
		''/intranet/admin/user_matrix/'',   -- url
		30,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_admin_matrix_menu, v_admins, ''read'');

	v_admin_parameters_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''admin_parameters'',   -- label
		''Parameters'',		-- name
		''/intranet/admin/parameters/'',   -- url
		39,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_admin_parameters_menu, v_admins, ''read'');

	v_admin_categories_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''admin_categories'',   -- label
		''Categories'',		-- name
		''/intranet/admin/categories/'',   -- url
		50,			-- sort_order
		v_admin_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_admin_categories_menu, v_admins, ''read'');
  
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- -----------------------------------------------------
-- Project Menu
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_project_menu		integer;
	v_main_menu		integer;
	v_top_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';

	select menu_id
	into v_main_menu
	from im_menus
	where label=''main'';

	select menu_id
	into v_top_menu
	from im_menus
	where label=''top'';

	-- The Project menu: It''s not displayed itself
	-- but serves as the starting point for submenus
		v_project_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''project'',		-- label
		''Project'',		-- name
		''/intranet/projects/view'',  -- url
		10,			-- sort_order
		v_top_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''project_standard'',   -- label
		''Summary'',		-- name
		''/intranet/projects/view?view_name=standard'',  -- url
		10,			-- sort_order
		v_project_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''project_files'',	-- label
		''Files'',		-- name
		''/intranet/projects/view?view_name=files'',  -- url
		20,			-- sort_order
		v_project_menu,		-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

	return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1();




-- -----------------------------------------------------
-- Companies Menu
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_companies_menu	integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';

	select menu_id into v_companies_menu from im_menus where label=''companies'';

	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''customers_potential'', -- label
		''Potential Customers'', -- name
		''/intranet/companies/index?status_id=41&type_id=57'',  -- url
		10,			-- sort_order
		v_companies_menu,	-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

-- Freelancers and Customers shouldnt see non-activ companies,
-- neither suppliers nor customers, even if its their own
-- companies.
--
--	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
--	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');


	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''customers_active'',   -- label
		''Active Customers'',	-- name
		''/intranet/companies/index?status_id=46&type_id=57'',  -- url
		20,			-- sort_order
		v_companies_menu,	-- parent_menu_id
		null			-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

-- Customers & Freelancers see only active companies
--	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
--	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');



	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''customers_inactive'',	-- label
		''Inactive Customers'',	-- name
		''/intranet/companies/index?status_id=48&type_id=57'',  -- url
		30,			-- sort_order
		v_companies_menu,	-- parent_menu_id
		null			-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

-- Customers & Freelancers see only active companies
--  PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
--  PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();




-- -------------------------------------------------------
-- Setup an invisible Companies Admin menu 
-- This can be extended later by other modules
-- with more Admin Links
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id
	into v_main_menu
	from im_menus
	where label = ''companies'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Companies
	v_admin_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''companies_admin'',	-- label
		''Companies Admin'',	-- name
		''/intranet-core/'',	-- url
		90,			-- sort_order
		v_main_menu,		-- parent_menu_id
		''0''			-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();




-- -------------------------------------------------------
-- Setup an invisible Projects Admin menu 
-- This can be extended later by other modules
-- with more Admin Links
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id
	into v_main_menu
	from im_menus
	where label = ''projects'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''projects_admin'',	-- label
		''Projects Admin'',	-- name
		''/intranet-core/'',	-- url
		90,			-- sort_order
		v_main_menu,		-- parent_menu_id
		''0''			-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-core',				-- package_name
	'project_admin_filter_advanced',		-- label
	'Advanced Filtering',				-- name
	'/intranet/projects/index?filter_advanced_p=1',	-- url
	70,						-- sort_order
	(select menu_id from im_menus where label = 'projects_admin'),
	null						-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'project_admin_filter_advanced'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);







-- -------------------------------------------------------
-- Setup an invisible Admin menu for TimesheetNewPage
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''timesheet2_timesheet'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''timesheet_hours_new_admin'',	-- label
		''Timesheet Hours New Admin'',	-- name
		''/intranet-timesheet2/hours/'',	-- url
		90,			-- sort_order
		v_main_menu,		-- parent_menu_id
		''0''			-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


-- -----------------------------------------------------
-- Projects Menu (project index page)
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_projects_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';

	select menu_id
	into v_projects_menu
	from im_menus
	where label=''projects'';

	-- needs to be the first Project menu in order to get selected
	-- The URL should be /intranet/projects/index?view_name=project_list,
	-- but project_list is default in projects/index.tcl, so we can
	-- skip this here.
	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''projects_potential'',	-- label
		''Potential'',		-- name
		''/intranet/projects/index?project_status_id=71'', -- url
		10,			-- sort_order
		v_projects_menu,	-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');


	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''projects_open'',	-- label
		''Open'',		-- name
		''/intranet/projects/index?project_status_id=76'', -- url
		20,			-- sort_order
		v_projects_menu,	-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');


	v_menu := im_menu__new (
		null,			-- p_menu_id
		''im_menu'',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		''intranet-core'',	-- package_name
		''projects_closed'',	-- label
		''Closed'',		-- name
		''/intranet/projects/index?project_status_id=81'', -- url
		30,			-- sort_order
		v_projects_menu,	-- parent_menu_id
		null			-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



-- -----------------------------------------------------
-- User Exits Menu (Admin Page)
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
begin
	select group_id into v_admins from groups where group_name = ''P/O Admins'';

	select menu_id into v_admin_menu
	from im_menus
	where label=''admin'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_user_exits'',		-- label
		''User Exits'',			-- name
		''/intranet/admin/user_exits'', -- url
		110,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



-- -----------------------------------------------------
-- 
-- -----------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_components'',		-- label
		''Portlet Components'',		-- name
		''/intranet/admin/components/'', -- url
		90,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- -------------------------------------------------------
-- Setup "DynView" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_dynview'',		-- label
		''DynView'',			-- name
		''/intranet/admin/views/'',	-- url
		751,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "backup" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_backup'',		-- label
		''Backup'',			-- name
		''/intranet/admin/backup/'',	-- url
		11,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "templates" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_templates'',		-- label
		''Templates'',			-- name
		''/intranet/admin/templates/'',	-- url
		2601,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	update im_menus set menu_gif_small = ''arrow_right''
	where menu_id = v_admin_menu;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "Packages" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_packages'',		-- label
		''Package Manager'',		-- name
		''/acs-admin/apm/'',		-- url
		190,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- Setup "Workflow" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-workflow'',		-- package_name
		''admin_workflow'',		-- label
		''Workflow'',			-- name
		''/acs-workflow/admin/'',	-- url
		1090,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Fix the location of the admin_workflow label
-- for those ]po[ installations where the acs-workflow
-- is already mounted at /acs-workflow/ (instead of
-- (/workflow/ for older installations)
--
update im_menus set
        url = '/'
              || (
                select name
                from site_nodes
                where object_id in (select package_id from apm_packages where package_key = 'acs-workflow'))
              || '/admin/'
where
        label = 'admin_workflow';




-- -------------------------------------------------------
-- Setup "Flush Permission Cash" menu 
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_flush'',		-- label
		''Cache Flush'',		-- name
		''/intranet/admin/flush_cache'',	-- url
		11,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''0''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- -------------------------------------------------------
-- API-Doc

create or replace function inline_0 ()
returns integer as '
declare
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_api_doc'',		-- label
		''API Doc'',			-- name
		''/api-doc/'',			-- url
		10,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- -------------------------------------------------------
-- API-Doc

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_developer'',		-- label
		''Developer Home'',		-- name
		''/acs-admin/developer'',	-- url
		20,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_l10n'',		-- label
		''Localization Home'',		-- name
		''/acs-lang/admin/'',		-- url
		20,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_package_manager'',	-- label
		''Package Manager'',		-- name
		''/acs-admin/apm/'',		-- url
		30,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_sitemap'',		-- label
		''Sitemap'',			-- name
		''/admin/site-map/'',			-- url
		40,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_ds'',			-- label
		''SQL Profiling'',		-- name
		''/ds/'',			-- url
		50,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_shell'',		-- label
		''Interactive Shell'',		-- name
		''/ds/shell'',			-- url
		55,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_cache'',		-- label
		''Cache Status'',		-- name
		''/acs-admin/cache/'',		-- url
		60,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu		integer;
	v_main_menu		integer;
BEGIN
	select menu_id into v_main_menu
	from im_menus where label = ''admin'';

	-- Main admin menu - just an invisible top-menu
	-- for all admin entries links under Projects
	v_admin_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_auth'',			-- label
		''LDAP'',			-- name
		''/acs-admin/auth/'',		-- url
		80,				-- sort_order
		v_main_menu,			-- parent_menu_id
		''''				-- p_visible_tcl
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



select im_menu__new (
	null,				-- p_menu_id
	'im_menu',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'intranet-core',		-- package_name
	'admin_restart_server',		-- label
	'Restart Server',		-- name
	'/acs-admin/server-restart',	-- url
	190,				-- sort_order
	(select menu_id from im_menus where label = 'admin'),
	null				-- p_visible_tcl
);





-- -----------------------------------------------------
-- Auth Authorities
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
begin
	select group_id into v_admins from groups where group_name = ''P/O Admins'';

	select menu_id into v_admin_menu
	from im_menus
	where label=''admin'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_auth_authorities'',	-- label
		''Auth Authorities'',		-- name
		''/acs-admin/auth/index'',	-- url
		120,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();


-- -----------------------------------------------------
-- Consistency Checks
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
begin
	select group_id into v_admins from groups where group_name = ''P/O Admins'';

	select menu_id into v_admin_menu
	from im_menus where label=''admin'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-core'',		-- package_name
		''admin_consistency_check'',	-- label
		''Consistency Checks'',		-- name
		''/acs-admin/auth/index'',	-- url
		650,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



-- Set sort_orders
--

update im_menus set sort_order =  100, menu_gif_small = 'arrow_right' where label = 'admin_home';
update im_menus set sort_order =  200, menu_gif_small = 'arrow_right' where label = 'openacs_api_doc';
update im_menus set sort_order =  300, menu_gif_small = 'arrow_right' where label = 'admin_auth_authorities';
update im_menus set sort_order =  400, menu_gif_small = 'arrow_right' where label = 'admin_backup';
update im_menus set sort_order =  450, menu_gif_small = 'arrow_right' where label = 'admin_flush';
update im_menus set sort_order =  500, menu_gif_small = 'arrow_right' where label = 'openacs_cache';
update im_menus set sort_order =  600, menu_gif_small = 'arrow_right' where label = 'admin_categories';
update im_menus set sort_order =  650, menu_gif_small = 'arrow_right' where label = 'admin_consistency_check';
update im_menus set sort_order =  700, menu_gif_small = 'arrow_right' where label = 'admin_cost_centers';
update im_menus set sort_order =  800, menu_gif_small = 'arrow_right' where label = 'admin_cost_center_permissions';
update im_menus set sort_order =  900, menu_gif_small = 'arrow_right' where label = 'openacs_developer';
update im_menus set sort_order = 1000, menu_gif_small = 'arrow_right' where label = 'dynfield_admin';
update im_menus set sort_order = 1100, menu_gif_small = 'arrow_right' where label = 'admin_dynview';
update im_menus set sort_order = 1200, menu_gif_small = 'arrow_right' where label = 'admin_exchange_rates';
update im_menus set sort_order = 1400, menu_gif_small = 'arrow_right' where label = 'openacs_shell';
update im_menus set sort_order = 1500, menu_gif_small = 'arrow_right' where label = 'openacs_auth';
update im_menus set sort_order = 1600, menu_gif_small = 'arrow_right' where label = 'openacs_l10n';
update im_menus set sort_order = 1650, menu_gif_small = 'arrow_right' where label = 'mail_import';
update im_menus set sort_order = 1700, menu_gif_small = 'arrow_right' where label = 'material';
update im_menus set sort_order = 1800, menu_gif_small = 'arrow_right' where label = 'admin_menus';
update im_menus set sort_order = 1900, menu_gif_small = 'arrow_right' where label = 'admin_packages';
update im_menus set sort_order = 2000, menu_gif_small = 'arrow_right' where label = 'admin_parameters';
update im_menus set sort_order = 2100, menu_gif_small = 'arrow_right' where label = 'admin_components';
update im_menus set sort_order = 2300, menu_gif_small = 'arrow_right' where label = 'openacs_restart_server';
update im_menus set sort_order = 2400, menu_gif_small = 'arrow_right' where label = 'openacs_ds';
update im_menus set sort_order = 2500, menu_gif_small = 'arrow_right' where label = 'admin_survsimp';
update im_menus set sort_order = 2600, menu_gif_small = 'arrow_right' where label = 'openacs_sitemap';
update im_menus set sort_order = 2700, menu_gif_small = 'arrow_right' where label = 'software_updates';
update im_menus set sort_order = 2800, menu_gif_small = 'arrow_right' where label = 'admin_sysconfig';
update im_menus set sort_order = 2850, menu_gif_small = 'arrow_right' where label = 'update_server';
update im_menus set sort_order = 2900, menu_gif_small = 'arrow_right' where label = 'admin_user_exits';
update im_menus set sort_order = 3000, menu_gif_small = 'arrow_right' where label = 'admin_usermatrix';
update im_menus set sort_order = 3050, menu_gif_small = 'arrow_right' where label = 'admin_profiles';
update im_menus set sort_order = 3100, menu_gif_small = 'arrow_right' where label = 'admin_workflow';


update im_menus set name = 'User Profiles' where label = 'admin_profiles';
update im_menus set name = 'Parameters' where label = 'admin_parameters';
update im_menus set name = 'Package Manager' where label = 'admin_packages';
update im_menus set name = 'Cache Flush' where label = 'admin_flush';


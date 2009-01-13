-- /packages/intranet/sql/oracle/intranet-menu-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

---------------------------------------------------------
-- Menus
--
-- Dynamic Menus are necessary to allow Project/Open modules
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
-- avoid multiple "menu pointers" to the same page because
-- this leads to an ambiguity about the supermenu.
-- These ambiguities are resolved by taking the menu from
-- the highest possible hierarchy level and then using the
-- lowest sort_key.


begin
    acs_object_type.create_type (
	supertype =>		'acs_object',
	object_type =>		'im_menu',
	pretty_name =>		'Menu',
	pretty_plural =>	'Menus',
	table_name =>		'im_menus',
	id_column =>		'menu_id',
	package_name =>		'im_menu',
	type_extension_table =>	null,
	name_method =>		'im_menu.name'
    );
end;
/
show errors


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
				-- locate "their" menus.
	label			varchar(200) not null,
				-- the name that should appear on the tab
	name			varchar(200) not null,
				-- On which pages should the menu appear?
	url			varchar(200) not null,
	sort_order		integer,
				-- parent_id allows for tree view for navbars
	parent_menu_id		integer
				constraint im_parent_menu_id_fk
				references im_menus,
				-- TCL expression that needs to be either null
				-- or evaluate (expr *) to 1 in order to display 
				-- the menu.
        tree_sortkey            varchar(100),
	visible_tcl		varchar(1000) default null,
				-- Make sure there are no two identical
				-- menus on the same _level_.
	constraint im_menus_label_un
	unique(label)
);


create or replace package im_menu
is
    function new (
	menu_id		in integer default null,
	object_type	in varchar default 'im_menu',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	package_name	in varchar,
	label		in varchar,
	name		in varchar,
	url		in varchar,
	sort_order	in integer,
	parent_menu_id	in integer,
	visible_tcl	in varchar default null
    ) return im_menus.menu_id%TYPE;

    procedure del (menu_id in integer);
    procedure del_module (module_name in varchar);
    function name (menu_id in integer) return varchar;
end im_menu;
/
show errors


create or replace package body im_menu
is

    function new (
	menu_id		in integer default null,
	object_type	in varchar default 'im_menu',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	package_name	in varchar,
	label		in varchar,
	name		in varchar,
	url		in varchar,
	sort_order	in integer,
	parent_menu_id	in integer,
	visible_tcl	in varchar default null
    ) return im_menus.menu_id%TYPE
    is
	v_menu_id	im_menus.menu_id%TYPE;
    begin
	v_menu_id := acs_object.new (
		object_id =>		menu_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);
	insert into im_menus (
		menu_id, package_name, label, name, 
		url, sort_order, parent_menu_id, visible_tcl
	) values (
		v_menu_id, package_name, label, name, url, 
		sort_order, parent_menu_id, visible_tcl
	);
	return v_menu_id;
    end new;


    -- Delete a single menu (if we know its ID...)
    procedure del (menu_id in integer)
    is
	v_menu_id	integer;
    begin
	-- copy the variable to desambiguate the var name
	v_menu_id := menu_id;

	-- Erase the im_menus item associated with the id
	delete from 	im_menus
	where		menu_id = v_menu_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_menu_id;
	acs_object.del(v_menu_id);
    end del;


    -- Delete all menus of a module.
    -- Used in <module-name>-drop.sql
    procedure del_module (module_name in varchar)
    is
    begin

     -- First we have to delete the references to parent menus...
     for row in (
        select menu_id
        from im_menus
        where package_name = del_module.module_name
     ) loop

	update im_menus 
	set parent_menu_id = null
	where menu_id = row.menu_id;

     end loop;

     -- ... then we can delete the menus themseves
     for row in (
        select menu_id
        from im_menus
        where package_name = del_module.module_name
     ) loop

	im_menu.del(row.menu_id);

     end loop;

    end del_module;


    function name (menu_id in integer) return varchar
    is
	v_name	im_menus.name%TYPE;
    begin
	select	name
	into	v_name
	from	im_menus
	where	menu_id = menu_id;

	return v_name;
    end name;
end im_menu;
/
show errors


set escape \

-- -----------------------------------------------------
-- Main Menu
-- -----------------------------------------------------

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
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

    select group_id
    into v_admins
    from groups
    where group_name = 'P/O Admins';

    select group_id
    into v_senman
    from groups
    where group_name = 'Senior Managers';

    select group_id
    into v_proman
    from groups
    where group_name = 'Project Managers';

    select group_id
    into v_accounting
    from groups
    where group_name = 'Accounting';

    select group_id
    into v_employees
    from groups
    where group_name = 'Employees';

    select group_id
    into v_companies
    from groups
    where group_name = 'Customers';

    select group_id
    into v_freelancers
    from groups
    where group_name = 'Freelancers';

    -- The "top" menu - the father of all menus.
    -- It is not displayed itself and only serves
    -- as a parent_menu_id from 'main' and 'project'.
    v_top_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'top',
	name =>		'Top Menu',
	url =>		'/',
	sort_order =>	10,
	parent_menu_id => null
    );

    -- The "Main" menu: It's not displayed itself neither
    -- but serves as the starting point for the main menu
    -- hierarchy.
    v_main_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'main',
	name =>		'Main Menu',
	url =>		'/',
	sort_order =>	10,
	parent_menu_id => v_top_menu
    );

    v_home_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'home',
	name =>		'Home',
	url =>		'/intranet/',
	sort_order =>	10,
	parent_menu_id => v_main_menu
    );
    acs_permission.grant_permission(v_home_menu, v_admins, 'read');
    acs_permission.grant_permission(v_home_menu, v_senman, 'read');
    acs_permission.grant_permission(v_home_menu, v_proman, 'read');
    acs_permission.grant_permission(v_home_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_home_menu, v_employees, 'read');
    acs_permission.grant_permission(v_home_menu, v_companies, 'read');
    acs_permission.grant_permission(v_home_menu, v_freelancers, 'read');

    v_user_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'users',
	name =>		'Users',
	url =>		'/intranet/users/',
	sort_order =>	30,
	parent_menu_id => v_main_menu
    );
    acs_permission.grant_permission(v_user_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_menu, v_proman, 'read');
    acs_permission.grant_permission(v_user_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_user_menu, v_employees, 'read');


    v_project_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'projects',
	name =>		'Projects',
	url =>		'/intranet/projects/',
	sort_order =>	40,
	parent_menu_id => v_main_menu
    );
    acs_permission.grant_permission(v_project_menu, v_admins, 'read');
    acs_permission.grant_permission(v_project_menu, v_senman, 'read');
    acs_permission.grant_permission(v_project_menu, v_proman, 'read');
    acs_permission.grant_permission(v_project_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_project_menu, v_employees, 'read');
    acs_permission.grant_permission(v_project_menu, v_companies, 'read');
    acs_permission.grant_permission(v_project_menu, v_freelancers, 'read');


    v_company_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'companies',
	name =>		'Companies',
	url =>		'/intranet/companies/',
	sort_order =>	50,
	parent_menu_id => v_main_menu
    );
    acs_permission.grant_permission(v_company_menu, v_admins, 'read');
    acs_permission.grant_permission(v_company_menu, v_senman, 'read');
    acs_permission.grant_permission(v_company_menu, v_proman, 'read');
    acs_permission.grant_permission(v_company_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_company_menu, v_employees, 'read');
    acs_permission.grant_permission(v_company_menu, v_companies, 'read');
    acs_permission.grant_permission(v_company_menu, v_freelancers, 'read');


--    v_office_menu := im_menu.new (
--	package_name =>	'intranet-core',
--	label =>	'offices',
--	name =>		'Offices',
--	url =>		'/intranet/offices/',
--	sort_order =>	60,
--	parent_menu_id => v_main_menu
--    );
--    acs_permission.grant_permission(v_office_menu, v_admins, 'read');
--    acs_permission.grant_permission(v_office_menu, v_senman, 'read');
--    acs_permission.grant_permission(v_office_menu, v_proman, 'read');
--    acs_permission.grant_permission(v_office_menu, v_accounting, 'read');
--    acs_permission.grant_permission(v_office_menu, v_employees, 'read');
--    acs_permission.grant_permission(v_office_menu, v_companies, 'read');
--    acs_permission.grant_permission(v_office_menu, v_freelancers, 'read');


    v_admin_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'admin',
	name =>		'Admin',
	url =>		'/intranet/admin/',
	sort_order =>	999,
	parent_menu_id => v_main_menu
    );
    acs_permission.grant_permission(v_admin_menu, v_admins, 'read');


    -- -----------------------------------------------------
    -- Projects Submenu
    -- -----------------------------------------------------

    -- needs to be the first Project menu in order to get selected
    -- The URL should be /intranet/projects/index?view_name=project_list,
    -- but project_list is default in projects/index.tcl, so we can
    -- skip this here.
    v_project_standard_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'projects_standard',
	name =>		'Summary',
	url =>		'/intranet/projects/index',
	sort_order =>	10,
	parent_menu_id => v_project_menu
    );
    acs_permission.grant_permission(v_project_standard_menu, v_admins, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_senman, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_proman, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_employees, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_companies, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_freelancers, 'read');


    v_project_status_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'projects_status',
	name =>		'Status',
	url =>		'/intranet/projects/index?view_name=project_status',
	sort_order =>	20,
	parent_menu_id => v_project_menu
    );
    acs_permission.grant_permission(v_project_status_menu, v_admins, 'read');
    acs_permission.grant_permission(v_project_status_menu, v_senman, 'read');
    acs_permission.grant_permission(v_project_status_menu, v_proman, 'read');
    acs_permission.grant_permission(v_project_status_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_project_status_menu, v_employees, 'read');
    acs_permission.grant_permission(v_project_status_menu, v_companies, 'read');

    -- -----------------------------------------------------
    -- Users Submenu
    -- -----------------------------------------------------

    v_user_employees_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'users_employees',
	name =>		'Employees',
	url =>		'/intranet/users/index?user_group_name=Employees',
	sort_order =>	1,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_employees_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_employees_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_employees_menu, v_proman, 'read');
    acs_permission.grant_permission(v_user_employees_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_user_employees_menu, v_employees, 'read');


    v_user_companies_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'users_customers',
	name =>		'Customers',
	url =>		'/intranet/users/index?user_group_name=Customers',
	sort_order =>	2,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_companies_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_companies_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_companies_menu, v_accounting, 'read');


    v_user_freelancers_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'users_freelancers',
	name =>		'Freelancers',
	url =>		'/intranet/users/index?user_group_name=Freelancers',
	sort_order =>	3,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_freelancers_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_freelancers_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_freelancers_menu, v_proman, 'read');
    acs_permission.grant_permission(v_user_freelancers_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_user_freelancers_menu, v_employees, 'read');


    v_user_all_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'users_unassigned',
	name =>		'Unassigned',
	url =>		'/intranet/users/index?user_group_name=Unregistered\&view_name=user_community\&order_by=Creation',
	sort_order =>	4,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_all_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_all_menu, v_senman, 'read');


    v_user_all_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'users_all',
	name =>		'All Users',
	url =>		'/intranet/users/index?user_group_name=All',
	sort_order =>	5,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_all_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_all_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_all_menu, v_accounting, 'read');

    -- -----------------------------------------------------
    -- Administration Submenu
    -- -----------------------------------------------------

    v_admin_home_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'admin_home',
	name =>		'Admin Home',
	url =>		'/intranet/admin/',
	sort_order =>	10,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_home_menu, v_admins, 'read');

    v_admin_profiles_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'admin_profiles',
	name =>		'Profiles',
	url =>		'/intranet/admin/profiles/',
	sort_order =>	15,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_profiles_menu, v_admins, 'read');

    v_admin_menus_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'admin_menus',
	name =>		'Menus',
	url =>		'/intranet/admin/menus/',
	sort_order =>	20,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_profiles_menu, v_admins, 'read');

    v_admin_matrix_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'admin_usermatrix',
	name =>		'User Matrix',
	url =>		'/intranet/admin/user_matrix/',
	sort_order =>	30,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_matrix_menu, v_admins, 'read');

    v_admin_parameters_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'admin_parameters',
	name =>		'Parameters',
	url =>		'/intranet/admin/parameters/',
	sort_order =>	39,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_parameters_menu, v_admins, 'read');

    v_admin_categories_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'admin_categories',
	name =>		'Categories',
	url =>		'/intranet/admin/categories/',
	sort_order =>	50,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_categories_menu, v_admins, 'read');
end;
/
show errors



-- -----------------------------------------------------
-- Project Menu
-- -----------------------------------------------------

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
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_proman from groups where group_name = 'Project Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_employees from groups where group_name = 'Employees';
    select group_id into v_companies from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_main_menu
    from im_menus
    where label='main';

    select menu_id
    into v_top_menu
    from im_menus
    where label='top';

    -- The "Project" menu: It's not displayed itself
    -- but serves as the starting point for submenus
    v_project_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'project',
	name =>		'Project',
	url =>		'/intranet/projects/view',
	sort_order =>	10,
	parent_menu_id => v_top_menu
    );

    v_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'project_standard',
	name =>		'Summary',
	url =>		'/intranet/projects/view?view_name=standard',
	sort_order =>	10,
	parent_menu_id => v_project_menu
    );
    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_proman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_employees, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    acs_permission.grant_permission(v_menu, v_freelancers, 'read');

    v_menu := im_menu.new (
	package_name =>	'intranet-core',
	label =>	'project_files',
	name =>		'Files',
	url =>		'/intranet/projects/view?view_name=files',
	sort_order =>	10,
	parent_menu_id => v_project_menu
    );
    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_proman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_employees, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    acs_permission.grant_permission(v_menu, v_freelancers, 'read');


end;
/
commit;

-- /packages/intranet/sql/oracle/intranet-menu-create.sql
--
-- Project/Open Core, fraber@fraber.de, 040129
--

---------------------------------------------------------
-- Menus
--
-- Dynamic Menus are necessary to allow Project/Open modules
-- to extend the core at some point in the future without
-- that core would need know about these extensions in
-- advance.
--
-- Menus entries are basicly mappings from a Name into a URL.
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
				-- the name that should appear on the tab
	package_name		varchar(200) not null,
	name			varchar(200) not null,
	url			varchar(200) not null,
	sort_order		integer,
				-- parent_id allows for tree view for navbars
	parent_menu_id		integer
				constraint im_parent_menu_id_fk
				references im_menus,
				-- Make sure there are no two identical
				-- menus on the same _level_.
				constraint im_menus_name_un
				unique(name, parent_menu_id)
);

create or replace package im_menu
is
    function new (
	menu_id		in integer,
	object_type	in varchar,
	creation_date	in date,
	creation_user	in integer,
	creation_ip	in varchar,
	context_id	in integer,
	package_name	in varchar,
	name		in varchar,
	url		in varchar,
	sort_order	in integer,
	parent_menu_id	in integer
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
	menu_id		in integer,
	object_type	in varchar,
	creation_date	in date,
	creation_user	in integer,
	creation_ip	in varchar,
	context_id	in integer,
	package_name	in varchar,
	name		in varchar,
	url		in varchar,
	sort_order	in integer,
	parent_menu_id	in integer
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
		menu_id, package_name, name, url, sort_order, parent_menu_id
	) values (
		v_menu_id, package_name, name, url, sort_order, parent_menu_id
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
	v_menu_id   integer;
	CURSOR v_menu_cursor IS
        	select menu_id
        	from im_menus
        	where package_name = module_name
        	FOR UPDATE;
    begin
	OPEN v_menu_cursor;
	LOOP
		FETCH v_menu_cursor INTO v_menu_id;
		EXIT WHEN v_menu_cursor%NOTFOUND;
		im_menu.del(v_menu_id);
		END LOOP;
	CLOSE v_menu_cursor;
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



declare
	-- Menu IDs
	v_menu			integer;
	v_home_menu		integer;
	v_user_menu		integer;
	v_project_menu		integer;
	v_customer_menu		integer;
	v_office_menu		integer;
	v_user_orgchart_menu	integer;
	v_user_all_menu		integer;
	v_user_freelancers_menu	integer;
	v_user_customers_menu	integer;
	v_user_employees_menu	integer;
	v_project_status_menu	integer;
	v_project_standard_menu	integer;
	v_admin_menu		integer;
	v_admin_categories_menu	integer;
	v_admin_matrix_menu	integer;
	v_admin_profiles_menu	integer;
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

    -- -----------------------------------------------------
    -- Main Menu
    -- -----------------------------------------------------

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
    into v_customers
    from groups
    where group_name = 'Customers';

    select group_id
    into v_freelancers
    from groups
    where group_name = 'Freelancers';


    v_home_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Home',
	url =>		'/intranet/index',
	sort_order =>	10,
	parent_menu_id => null
    );
    acs_permission.grant_permission(v_home_menu, v_admins, 'read');
    acs_permission.grant_permission(v_home_menu, v_senman, 'read');
    acs_permission.grant_permission(v_home_menu, v_proman, 'read');
    acs_permission.grant_permission(v_home_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_home_menu, v_employees, 'read');
    acs_permission.grant_permission(v_home_menu, v_customers, 'read');
    acs_permission.grant_permission(v_home_menu, v_freelancers, 'read');

    v_user_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Users',
	url =>		'/intranet/users/',
	sort_order =>	30,
	parent_menu_id => null
    );
    acs_permission.grant_permission(v_user_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_menu, v_proman, 'read');
    acs_permission.grant_permission(v_user_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_user_menu, v_employees, 'read');


    v_project_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Projects',
	url =>		'/intranet/projects/',
	sort_order =>	40,
	parent_menu_id => null
    );
    acs_permission.grant_permission(v_project_menu, v_admins, 'read');
    acs_permission.grant_permission(v_project_menu, v_senman, 'read');
    acs_permission.grant_permission(v_project_menu, v_proman, 'read');
    acs_permission.grant_permission(v_project_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_project_menu, v_employees, 'read');
    acs_permission.grant_permission(v_project_menu, v_customers, 'read');
    acs_permission.grant_permission(v_project_menu, v_freelancers, 'read');


    v_customer_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Clients',
	url =>		'/intranet/customers/',
	sort_order =>	50,
	parent_menu_id => null
    );
    acs_permission.grant_permission(v_customer_menu, v_admins, 'read');
    acs_permission.grant_permission(v_customer_menu, v_senman, 'read');
    acs_permission.grant_permission(v_customer_menu, v_proman, 'read');
    acs_permission.grant_permission(v_customer_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_customer_menu, v_employees, 'read');
    acs_permission.grant_permission(v_customer_menu, v_customers, 'read');
    acs_permission.grant_permission(v_customer_menu, v_freelancers, 'read');


    v_office_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Offices',
	url =>		'/intranet/offices/',
	sort_order =>	60,
	parent_menu_id => null
    );
    acs_permission.grant_permission(v_office_menu, v_admins, 'read');
    acs_permission.grant_permission(v_office_menu, v_senman, 'read');
    acs_permission.grant_permission(v_office_menu, v_proman, 'read');
    acs_permission.grant_permission(v_office_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_office_menu, v_employees, 'read');
    acs_permission.grant_permission(v_office_menu, v_customers, 'read');
    acs_permission.grant_permission(v_office_menu, v_freelancers, 'read');


    v_admin_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Admin',
	url =>		'/intranet/admin/',
	sort_order =>	70,
	parent_menu_id => null
    );
    acs_permission.grant_permission(v_admin_menu, v_admins, 'read');


    -- -----------------------------------------------------
    -- Projects Submenu
    -- -----------------------------------------------------

    v_project_standard_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Standard',
	url =>		'/intranet/projects/index?view_name=project_list',
	sort_order =>	10,
	parent_menu_id => v_project_menu
    );
    acs_permission.grant_permission(v_project_standard_menu, v_admins, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_senman, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_proman, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_employees, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_customers, 'read');
    acs_permission.grant_permission(v_project_standard_menu, v_freelancers, 'read');


    v_project_status_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
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
    acs_permission.grant_permission(v_project_status_menu, v_customers, 'read');

    -- -----------------------------------------------------
    -- Users Submenu
    -- -----------------------------------------------------

    v_user_employees_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
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


    v_user_customers_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Clients',
	url =>		'/intranet/users/index?user_group_name=Customers',
	sort_order =>	2,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_customers_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_customers_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_customers_menu, v_accounting, 'read');


    v_user_freelancers_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
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
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'All Users',
	url =>		'/intranet/users/index?user_group_name=All',
	sort_order =>	4,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_all_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_all_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_all_menu, v_accounting, 'read');

    v_user_orgchart_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Org Chart',
	url =>		'/intranet/users/org-chart',
	sort_order =>	5,
	parent_menu_id => v_user_menu
    );
    acs_permission.grant_permission(v_user_orgchart_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_proman, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_employees, 'read');


    -- -----------------------------------------------------
    -- Administration Submenu
    -- -----------------------------------------------------

    v_admin_home_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Admin Home',
	url =>		'/intranet/admin/',
	sort_order =>	10,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_home_menu, v_admins, 'read');
    acs_permission.grant_permission(v_admin_home_menu, v_senman, 'read');

    v_admin_profiles_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Profiles',
	url =>		'/intranet/admin/profiles/',
	sort_order =>	20,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_profiles_menu, v_admins, 'read');
    acs_permission.grant_permission(v_admin_profiles_menu, v_senman, 'read');

    v_admin_matrix_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'User Matrix',
	url =>		'/intranet/admin/user_matrix/',
	sort_order =>	30,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_matrix_menu, v_admins, 'read');
    acs_permission.grant_permission(v_admin_matrix_menu, v_senman, 'read');


    v_admin_categories_menu := im_menu.new (
	menu_id =>	null,
	object_type =>	'im_menu',
	creation_date => sysdate,
	creation_user => 0,
	creation_ip =>	null,
	context_id =>	null,
	package_name =>	'intranet',
	name =>		'Categories',
	url =>		'/intranet/admin/categories/',
	sort_order =>	40,
	parent_menu_id => v_admin_menu
    );
    acs_permission.grant_permission(v_admin_categories_menu, v_admins, 'read');
    acs_permission.grant_permission(v_admin_categories_menu, v_senman, 'read');
end;
/
show errors


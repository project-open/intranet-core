-- /packages/intranet/sql/oracle/intranet-menu-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

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
-- avoid multiple menu pointers to the same page because
-- this leads to an ambiguity about the supermenu.
-- These ambiguities are resolved by taking the menu from
-- the highest possible hierarchy level and then using the
-- lowest sort_key.


SELECT acs_object_type__create_type (
        'im_menu',		    -- object_type
        'Menu',			    -- pretty_name
        'Menus',		    -- pretty_plural
        'acs_object',               -- supertype
        'im_menus',		    -- table_name
        'menu_id',		    -- id_column
        'im_menu',		    -- package_name
        'f',                        -- abstract_p
        null,                       -- type_extension_table
        'im_menu.name'  -- name_method
    );


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
	visible_tcl		varchar(1000) default null,
				-- Make sure there are no two identical
				-- menus on the same _level_.
	constraint im_menus_label_un
	unique(label)
);

create or replace function im_menu__new (integer, varchar, timestamptz, integer, varchar, integer,
varchar, varchar, varchar, varchar, integer, integer, varchar) returns integer as '
declare
	p_menu_id	  alias for $1;   -- default null
        p_object_type	  alias for $2;   -- default ''acs_object''
        p_creation_date	  alias for $3;   -- default now()
        p_creation_user	  alias for $4;   -- default null
        p_creation_ip	  alias for $5;   -- default null
        p_context_id	  alias for $6;   -- default null
	p_package_name	  alias for $7;
	p_label		  alias for $8;
	p_name		  alias for $9;
	p_url		  alias for $10;
	p_sort_order	  alias for $11;
	p_parent_menu_id  alias for $12;
	p_visible_tcl	  alias for $13;  -- default null

	v_menu_id	  im_menus.menu_id%TYPE;
begin
	v_menu_id := acs_object__new (
                p_menu_id,    -- object_id
                p_object_type,  -- object_type
                p_creation_date,        -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip,  -- creation_ip
                p_context_id    -- context_id
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
	p_module_name   alias for $1;
        row             RECORD;
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
        p_menu_id   alias for $1;
	v_name	    im_menus.name%TYPE;
BEGIN

    function name (menu_id in integer) return varchar
    is
    begin
	select	name
	into	v_name
	from	im_menus
	where	menu_id = p_menu_id;

	return v_name;
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
	v_reg_users		integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';


    -- The top menu - the father of all menus.
    -- It is not displayed itself and only serves
    -- as a parent_menu_id from ''main'' and ''project''.
    v_top_menu := im_menu__new (
	null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
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
    PERFORM acs_permission__grant_permission(v_top_menu, v_reg_users, ''read'');


    -- The Main menu: It''s not displayed itself neither
    -- but serves as the starting point for the main menu
    -- hierarchy.
    v_main_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''main'',               -- label
        ''Main Menu'',          -- name
        ''/'',                  -- url
        10,                     -- sort_order
        v_top_menu,             -- parent_menu_id
        null                    -- p_visible_tcl
    );

    v_home_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''home'',               -- label
        ''Home'',               -- name
        ''/intranet/'',         -- url
        10,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_home_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_home_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_home_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_home_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_home_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_home_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_home_menu, v_freelancers, ''read'');
    PERFORM acs_permission__grant_permission(v_home_menu, v_reg_users, ''read'');



    v_project_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects'',               -- label
        ''Projects'',              -- name
        ''/intranet/projects/'',   -- url
        40,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_project_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_project_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_project_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_project_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_project_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_project_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_project_menu, v_freelancers, ''read'');
    PERFORM acs_permission__grant_permission(v_project_menu, v_reg_users, ''read'');




    v_company_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''companies'',               -- label
        ''Companies'',              -- name
        ''/intranet/companies/'',   -- url
        50,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_company_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_company_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_company_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_company_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_company_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_company_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_company_menu, v_freelancers, ''read'');
    PERFORM acs_permission__grant_permission(v_company_menu, v_reg_users, ''read'');



    v_user_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''user'',               -- label
        ''Users'',              -- name
        ''/intranet/users/'',   -- url
        30,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_user_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_user_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_user_menu, v_employees, ''read'');


    v_office_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''offices'',            -- label
        ''Offices'',            -- name
        ''/intranet/offices/'', -- url
        40,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_office_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_office_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_office_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_office_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_office_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_office_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_office_menu, v_freelancers, ''read'');
    PERFORM acs_permission__grant_permission(v_office_menu, v_reg_users, ''read'');

    v_admin_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin'',              -- label
        ''Admin'',              -- name
        ''/intranet/admin/'',   -- url
        999,                    -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_admin_menu, v_admins, ''read'');

    v_help_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''help'',               -- label
        ''Help'',               -- name
        ''/intranet/help/'',	-- url
        990,                    -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_help_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_help_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_help_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_help_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_help_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_help_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_help_menu, v_freelancers, ''read'');
    PERFORM acs_permission__grant_permission(v_help_menu, v_reg_users, ''read'');


    -- -----------------------------------------------------
    -- Users Submenu
    -- -----------------------------------------------------

    v_user_employees_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_employees'',    -- label
        ''Employees'',          -- name
        ''/intranet/users/index?user_group_name=Employees'',   -- url
        1,                      -- sort_order
        v_user_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_user_employees_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_user_employees_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_employees_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_employees_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_user_employees_menu, v_employees, ''read'');


    v_user_companies_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_customers'',    -- label
        ''Customers'',          -- name
        ''/intranet/users/index?user_group_name=Customers'',   -- url
        2,                      -- sort_order
        v_user_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_user_companies_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_user_companies_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_companies_menu, v_accounting, ''read'');


    v_user_freelancers_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_freelancers'',  -- label
        ''Freelancers'',        -- name
        ''/intranet/users/index?user_group_name=Freelancers'',   -- url
        3,                      -- sort_order
        v_user_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );


    PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_user_freelancers_menu, v_employees, ''read'');

    v_user_all_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_unassigned'',   -- label
        ''Unassigned'',         -- name
        ''/intranet/users/index?user_group_name=Unregistered\&view_name=user_community\&order_by=Creation'',   -- url
        4,                      -- sort_order
        v_user_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_user_all_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_user_all_menu, v_senman, ''read'');

    v_user_all_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_all'',          -- label
        ''All Users'',          -- name
        ''/intranet/users/index?user_group_name=All'',   -- url
        5,                      -- sort_order
        v_user_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_user_all_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_user_all_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_user_all_menu, v_accounting, ''read'');

    -- -----------------------------------------------------
    -- Administration Submenu
    -- -----------------------------------------------------

    v_admin_home_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_home'',         -- label
        ''Admin Home'',         -- name
        ''/intranet/admin/'',   -- url
        10,                     -- sort_order
        v_admin_menu,           -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_admin_home_menu, v_admins, ''read'');


    v_admin_profiles_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_profiles'',     -- label
        ''Profiles'',           -- name
        ''/intranet/admin/profiles/'',   -- url
        15,                     -- sort_order
        v_admin_menu,           -- parent_menu_id
        null                    -- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_admin_profiles_menu, v_admins, ''read'');


    v_admin_menus_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_menus'',        -- label
        ''Menus'',              -- name
        ''/intranet/admin/menus/'',   -- url
        20,                     -- sort_order
        v_admin_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_admin_profiles_menu, v_admins, ''read'');


    v_admin_matrix_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_usermatrix'',   -- label
        ''User Matrix'',        -- name
        ''/intranet/admin/user_matrix/'',   -- url
        30,                     -- sort_order
        v_admin_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_admin_matrix_menu, v_admins, ''read'');


    v_admin_parameters_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_parameters'',   -- label
        ''Parameters'',         -- name
        ''/intranet/admin/parameters/'',   -- url
        39,                     -- sort_order
        v_admin_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_admin_parameters_menu, v_admins, ''read'');


    v_admin_categories_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''admin_categories'',   -- label
        ''Categories'',         -- name
        ''/intranet/admin/categories/'',   -- url
        50,                     -- sort_order
        v_admin_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
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
      v_menu                  integer;
      v_project_menu          integer;
      v_main_menu             integer;
      v_top_menu              integer;

      -- Groups
      v_employees             integer;
      v_accounting            integer;
      v_senman                integer;
      v_customers             integer;
      v_freelancers           integer;
      v_proman                integer;
      v_admins                integer;
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
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''project'',            -- label
        ''Project'',            -- name
        ''/intranet/projects/view'',  -- url
        10,                     -- sort_order
        v_top_menu,             -- parent_menu_id
        null                    -- p_visible_tcl
    );

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''project_standard'',   -- label
        ''Summary'',            -- name
        ''/intranet/projects/view?view_name=standard'',  -- url
        10,                     -- sort_order
        v_project_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''project_files'',      -- label
        ''Files'',              -- name
        ''/intranet/projects/view?view_name=files'',  -- url
        20,                     -- sort_order
        v_project_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
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
      v_menu                  integer;
      v_companies_menu          integer;

      -- Groups
      v_employees             integer;
      v_accounting            integer;
      v_senman                integer;
      v_customers             integer;
      v_freelancers           integer;
      v_proman                integer;
      v_admins                integer;
      v_reg_users	      integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';


    select menu_id
    into v_companies_menu
    from im_menus
    where label=''companies'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''customers_potential'', -- label
        ''Potential Customers'', -- name
        ''/intranet/companies/index?status_id=41&type_id=57'',  -- url
        10,                     -- sort_order
        v_companies_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
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
--    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''customers_active'',   -- label
        ''Active Customers'',      -- name
        ''/intranet/companies/index?status_id=46&type_id=57'',  -- url
        20,                     -- sort_order
        v_companies_menu,       -- parent_menu_id
        null                    -- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

-- Customers & Freelancers see only active companies
--    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
--    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');



    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''customers_inactive'',   -- label
        ''Inactive Customers'',      -- name
        ''/intranet/companies/index?status_id=48&type_id=57'',  -- url
        30,                     -- sort_order
        v_companies_menu,       -- parent_menu_id
        null                    -- p_visible_tcl
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
        v_menu                  integer;
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
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''companies_admin'',    -- label
        ''Companies Admin'',    -- name
        ''/intranet-core/'',    -- url
        90,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        ''0''                   -- p_visible_tcl
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
        v_menu                  integer;
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
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_admin'',    -- label
        ''Projects Admin'',    -- name
        ''/intranet-core/'',    -- url
        90,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        ''0''                   -- p_visible_tcl
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
      v_menu                  integer;
      v_projects_menu          integer;

      -- Groups
      v_employees             integer;
      v_accounting            integer;
      v_senman                integer;
      v_customers             integer;
      v_freelancers           integer;
      v_proman                integer;
      v_admins                integer;
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
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_potential'',   -- label
        ''Potential'',            -- name
        ''/intranet/projects/index?project_status_id=71'', -- url
        10,                     -- sort_order
        v_projects_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_open'',    -- label
        ''Open'',             -- name
        ''/intranet/projects/index?project_status_id=76'', -- url
        20,                     -- sort_order
        v_projects_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_closed'',    -- label
        ''Closed'',             -- name
        ''/intranet/projects/index?project_status_id=81'', -- url
        30,                     -- sort_order
        v_projects_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
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



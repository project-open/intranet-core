-- /package/intranet-core/sql/intranet-components.sql
--
-- Copyright (C) 2004 Project/Open
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author      frank.bergmann@project-open.com
-- @author	juanjoruizx@yahoo.es


-- Implements the data structures for component bays
-- that allow to plug-in components into Project/Open
-- pages at runtime.

---------------------------------------------------------
-- Component Plugins
--

SELECT acs_object_type__create_type (
        'im_component_plugin',	    -- object_type
        'Component Plugin',	    -- pretty_name
        'Component Plugins',	    -- pretty_plural
        'acs_object',		    -- supertype
        'im_component_plugins',	    -- table_name
        'plugin_id',		    -- id_column
        'im_component_plugin',	    -- package_name
	'f',			    -- abstract_p
        null,			    -- type_extension_table
        'im_component_plugin.name'  -- name_method
    );


-- The idea is to use OpenACS permissions in the future to
-- control who should see what plugin.


create table im_component_plugins (
	plugin_id		integer 
				constraint im_component_plugin_id_pk
				primary key
				constraint im_component_plugin_id_fk
				references acs_objects,
				-- A unique (future!) name that identifies
				-- the plugin in case an error occurs and
				-- to avoid duplicate installation of plugins.
	plugin_name		varchar(200) not null,
				-- The name of the package that creates the plugin
				-- ... used to cleanup when uninstalling a package.
	package_name		varchar(200) not null,
				-- An integer inicating the order of the
				-- component in a component bay. Values should
				-- go like 10, 20, 30 etc. (like old Basic) to
				-- allow future modules to insert its components.
	sort_order		integer not null,
				-- if not null determines the view_name when
				-- to show the component. For example the filestorage
				-- components should only be shown on the "files"
				-- view of the ProjectViewPage.
	view_name		varchar(100) default null,
				-- page url starting with /intranet/, 
				-- but without the '.tcl' extension.
				-- page_url currently depends on where the
				-- module is mounted. Bad but not better
				-- idea around yet...
	page_url		varchar(200) not null,
				-- One of "left", "right" or "bottom".
	location		varchar(100) not null,
				-- constraint im_comp_plugin_location_check
				-- check(location in ('left','right','bottom','none')),
	title_tcl		varchar(4000),
	component_tcl		varchar(4000),
	enabled_p		char(1) default('t')
                                constraint im_comp_plugin_enabled_ck
                                check (enabled_p in ('t','f')),
				-- Make sure there are no two identical
		constraint im_component_plugins_un
		unique (plugin_name, package_name)
);

comment on table im_component_plugins is '
 Components Plugins are handeled in the database in order to allow
 customizations to survive system updates.
';


create table im_component_plugin_user_map (
	plugin_id		integer
				constraint im_comp_plugin_user_map_plugin_fk
				references im_component_plugins,
	user_id			integer 
				constraint im_comp_plugin_user_map_user_fk
				references users,
	sort_order		integer not null,
	minimized_p		char(1)
				constraint im_comp_plugin_user_map_min_p_ck
				check(minimized_p in ('t','f'))
				default 'f',
	location		varchar(100) not null,
		constraint im_comp_plugin_user_map_plugin_pk
		primary key (plugin_id, user_id)
);

comment on table im_component_plugin_user_map is '
 This table maps Component Plugins to particular users,
 effectively allowing users to customize their GUI
 layout.
';




create or replace function im_component_plugin__new (
	integer, varchar, timestamptz, integer, varchar, integer, 
	varchar, varchar, varchar, varchar, varchar, integer, 
	varchar, varchar
) returns integer as '
declare
	p_plugin_id	alias for $1;	-- default null
	p_object_type	alias for $2;	-- default ''acs_object''
	p_creation_date	alias for $3;	-- default now()
	p_creation_user	alias for $4;	-- default null
	p_creation_ip	alias for $5;	-- default null
	p_context_id	alias for $6;	-- default null

	p_plugin_name	alias for $7;
	p_package_name	alias for $8;
	p_location	alias for $9;
	p_page_url	alias for $10;
	p_view_name	alias for $11;	-- default null
	p_sort_order	alias for $12;
	p_component_tcl	alias for $13;
	p_title_tcl	alias for $14;

	v_plugin_id	im_component_plugins.plugin_id%TYPE;
begin
	v_plugin_id := acs_object__new (
		p_plugin_id,	-- object_id
		p_object_type,	-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,	-- creation_ip
		p_context_id	-- context_id
	);

	insert into im_component_plugins (
		plugin_id, plugin_name, package_name, sort_order, 
		view_name, page_url, location, 
		component_tcl, title_tcl
	) values (
		v_plugin_id, p_plugin_name, p_package_name, p_sort_order, 
		p_view_name, p_page_url, p_location, 
		p_component_tcl, p_title_tcl
	);

	return v_plugin_id;
end;' language 'plpgsql';

-- Delete a single component
create or replace function im_component_plugin__delete (integer) returns integer as '
DECLARE
	p_plugin_id	alias for $1;
BEGIN

	-- Erase the im_component_plugins item associated with the id
	delete from 	im_component_plugins
	where		plugin_id = p_plugin_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = p_plugin_id;

	PERFORM acs_object__delete(p_plugin_id);

	return 0;
end;' language 'plpgsql';


-- Delete all menus of a module.
-- Used in <module-name>-drop.sql
create or replace function im_component_plugin__del_module (varchar) returns integer as '
DECLARE
	p_module_name	alias for $1;
	row		RECORD;
BEGIN
	for row in 
            select plugin_id
            from im_component_plugins
            where package_name = p_module_name
	loop
	    delete from im_component_plugin_user_map
	    where plugin_id = row.plugin_id;

	    PERFORM im_component_plugin__delete(row.plugin_id);
	end loop;

	return 0;
end;' language 'plpgsql';


-- Return the module name
create or replace function im_component_plugin__name (integer) returns varchar as '
DECLARE
	p_plugin_id	alias for $1;
	v_name		varchar(200);
BEGIN
	select	page_url || ''.'' || location
	into	v_name
	from	im_component_plugins
	where	plugin_id = p_plugin_id;

	return v_name;
end;' language 'plpgsql';



-- -----------------------------------------------------
-- Setup a few predefined components
-- -----------------------------------------------------

-- Setup the list of project members for the projects/view
-- page. Sort_order is set to 20, because the forum component 
-- should go to the first place.
--
SELECT  im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
	'Project Members',		-- plugin_name
	'intranet',			-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name	
	20,				-- sort_order
	'im_table_with_title "[_ intranet-core.Project_Members]" [im_group_member_component $project_id 	$current_user_id $user_admin_p $return_url "" "" 1 ]'			-- component_tcl
    );







SELECT  im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
	'Task Members',			-- plugin_name
	'intranet',			-- package_name
	'right',			-- location
	'/intranet-timesheet2-tasks/new',	-- page_url
	null,				-- view_name	
	20,				-- sort_order
	'im_table_with_title "[_ intranet-core.Task_Members]" [im_group_member_component $task_id $current_user_id $user_admin_p $return_url "" "" 1 ]'			-- component_tcl
    );






SELECT  im_component_plugin__new (
	null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Office Members',		-- plugin_name
        'intranet',                     -- package_name
        'right',                        -- location
        '/intranet/offices/view',	-- page_url
        null,                           -- view_name
        20,                             -- sort_order
	'im_table_with_title "[_ intranet-core.Office_Members]" [im_group_member_component $office_id $user_id $admin $return_url "" "" 1 ]'			-- component_tcl
    );

SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Company Offices',		-- plugin_name
        'intranet',                     -- package_name
        'right',                        -- location
        '/intranet/companies/view',     -- page_url
        null,                           -- view_name
        30,                             -- sort_order
	'im_table_with_title "[_ intranet-core.Offices]" [im_office_company_component $user_id $company_id]' -- component_tcl
    );

-- Office component for UserViewPage
SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'User Offices',			-- plugin_name
        'intranet',                     -- package_name
        'right',                        -- location
        '/intranet/users/view',		-- page_url
        null,                           -- view_name
        80,                             -- sort_order
	'im_table_with_title "[_ intranet-core.Offices]" [im_office_user_component $current_user_id $user_id]' -- component_tcl
    );


SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Recent Registrations',         -- plugin_name
        'intranet',                     -- package_name
        'right',                        -- location
        '/intranet/admin/index',        -- page_url
        null,                           -- view_name
        30,                             -- sort_order
	'im_user_registration_component $user_id' -- component_tcl
    );


SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Home Random Portrait',         -- plugin_name
        'intranet',                     -- package_name
        'right',                        -- location
        '/intranet/index',              -- page_url
        null,                           -- view_name
        5,                              -- sort_order
	'im_random_employee_component'  -- component_tcl
    );

SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Home Help Blurb',              -- plugin_name
        'intranet',                     -- package_name
        'left',                         -- location
        '/intranet/index',              -- page_url
        null,                           -- view_name
        10,                             -- sort_order
	'im_help_home_page_blurb_component'       -- component_tcl
    );


SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Home Project Component',       -- plugin_name
        'intranet',                     -- package_name
        'left',                         -- location
        '/intranet/index',              -- page_url
        null,                           -- view_name
        15,                             -- sort_order
	'im_project_personal_active_projects_component'   -- component_tcl
    );





-- Notifications Component for each user
SELECT  im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'User Notifications',       -- plugin_name
        'intranet',                     -- package_name
        'right',                         -- location
        '/intranet/users/view',              -- page_url
        null,                           -- view_name
        85,                             -- sort_order
	'im_notification_user_component -user_id $user_id'   -- component_tcl
);


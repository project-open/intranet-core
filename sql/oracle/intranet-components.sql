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

-- Implements the data structures for component bays
-- that allow to plug-in components into Project/Open
-- pages at runtime.

---------------------------------------------------------
-- Component Plugins
--

begin
    acs_object_type.create_type (
	supertype =>		'acs_object',
	object_type =>		'im_component_plugin',
	pretty_name =>		'Component Plugin',
	pretty_plural =>	'Component Plugins',
	table_name =>		'im_component_plugins',
	id_column =>		'plugin_id',
	package_name =>		'im_component_plugin',
	type_extension_table =>	null,
	name_method =>		'im_component_plugin.name'
    );
end;
/
show errors


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
	component_tcl		varchar(4000),
		constraint im_component_plugins_un
		unique (plugin_name, package_name)
);

create or replace package im_component_plugin
is
    function new (
	plugin_id	in integer default null,
	object_type	in varchar default 'im_component_plugin',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	plugin_name	in varchar,
	package_name	in varchar,
	location	in varchar,
	page_url	in varchar,
	view_name	in varchar default null,
	sort_order	in integer,
	component_tcl	in varchar
    ) return im_component_plugins.plugin_id%TYPE;

    procedure del (plugin_id in integer);
    procedure del_module (module_name in varchar);
    function name (plugin_id in integer) return varchar;

end im_component_plugin;
/
show errors


create or replace package body im_component_plugin
is
    function new (
	plugin_id	in integer default null,
	object_type	in varchar default 'im_component_plugin',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	plugin_name	in varchar,
	package_name	in varchar,
	location	in varchar,
	page_url	in varchar,
	view_name	in varchar default null,
	sort_order	in integer,
	component_tcl	in varchar
    ) return im_component_plugins.plugin_id%TYPE
    is
	v_plugin_id	im_component_plugins.plugin_id%TYPE;
    begin
	v_plugin_id := acs_object.new (
		object_id =>		plugin_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);
	insert into im_component_plugins (
		plugin_id, plugin_name, package_name, sort_order, 
		view_name, page_url, location, component_tcl
	) values (
		v_plugin_id, plugin_name, package_name, sort_order, 
		view_name, page_url, location, component_tcl
	);
	return v_plugin_id;
    end new;


    procedure del (plugin_id in integer)
    is
    begin

	-- Erase the im_component_plugins item associated with the id
	delete from 	im_component_plugins
	where		plugin_id = del.plugin_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = del.plugin_id;

	acs_object.del(del.plugin_id);
    end del;


    -- Delete all menus of a module.
    -- Used in <module-name>-drop.sql
    procedure del_module (module_name in varchar)
    is
    begin
	for row in (
            select plugin_id
            from im_component_plugins
            where package_name = del_module.module_name
	) loop
	    im_component_plugin.del(plugin_id => row.plugin_id);
	end loop;
    end del_module;

    function name (plugin_id in integer) 
    return varchar
    is
	v_name	varchar(200);
    begin
	select	page_url || '.' || location
	into	v_name
	from	im_component_plugins
	where	plugin_id = plugin_id;

	return v_name;
    end name;
end im_component_plugin;
/
show errors



declare
    v_plugin		integer;
begin
    -- -----------------------------------------------------
    -- Setup a few predefined components
    -- -----------------------------------------------------

    -- Setup the list of project members for the projects/view
    -- page. Sort_order is set to 20, because the forum component 
    -- should go to the first place.
    --
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Project Members',
	package_name =>	'intranet',
	page_url =>	'/intranet/projects/view',
	location =>	'right',
	sort_order =>	20,
	component_tcl =>
	'im_table_with_title \
		"[_ intranet-core.Project_Members]" \
		[im_group_member_component \
			$project_id \
			$current_user_id \
			$user_admin_p \
			$return_url \
			"" \
			"" \
			1 \
		]'
    );
end;
/
show errors;




declare
    v_plugin		integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Office Members',
	package_name =>	'intranet',
	page_url =>	'/intranet/offices/view',
	location =>	'right',
	sort_order =>	20,
	component_tcl =>
	'im_table_with_title \
		"[_ intranet-core.Office_Members]" \
		[im_group_member_component \
			$office_id \
			$user_id \
			$admin \
			$return_url \
			"" \
			"" \
			1 \
		]'
    );
end;
/
show errors;
commit;




declare
    v_plugin		integer;
begin
    -- Office component for CompanyViewPage
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Company Offices',
	package_name =>	'intranet',
	page_url =>	'/intranet/companies/view',
	location =>	'right',
	sort_order =>	30,
	component_tcl =>
	'im_table_with_title \
		"[_ intranet-core.Offices]" \
		[im_office_company_component \
			$user_id \
			$company_id
		]'
    );

end;
/
show errors


declare
    v_plugin		integer;
begin
    -- Office component for UserViewPage
    v_plugin := im_component_plugin.new (
	plugin_name =>	'User Offices',
	package_name =>	'intranet',
	page_url =>	'/intranet/users/view',
	location =>	'right',
	sort_order =>	80,
	component_tcl =>
	'im_table_with_title \
		"[_ intranet-core.Offices]" \
		[im_office_user_component $current_user_id $user_id]'
    );

end;
/
show errors
commit;


declare
    v_plugin		integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Recent Registrations',
	package_name =>	'intranet',
	page_url =>	'/intranet/admin/index',
	location =>	'right',
	sort_order =>	30,
	component_tcl =>
	'im_user_registration_component $user_id'
    );
end;
/
show errors
commit;


declare
    v_plugin		integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Home Page Help Blurb',
	package_name =>	'intranet',
	page_url =>	'/intranet/index',
	location =>	'left',
	sort_order =>	10,
	component_tcl =>
	'im_help_home_page_blurb_component'
    );
end;
/
show errors
commit;

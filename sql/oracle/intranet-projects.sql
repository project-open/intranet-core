-- /packages/intranet-core/sql/oracle/intranet-projects.sql
--
-- Copyright (C) 1999-2004 various parties
-- The code is based on ArsDigita ACS 3.4
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
-- @author	  unknown@arsdigita.com
-- @author	  frank.bergmann@project-open.com
-- @author        juanjoruizx@yahoo.es

-- Projects
--
-- Each project can have any number of sub-projects


begin
	acs_object_type.create_type (
		supertype =>		'im_biz_object',
		object_type =>		'im_project',
		pretty_name =>		'Project',
		pretty_plural =>	'Projects',
		table_name =>		'im_projects',
		id_column =>		'project_id',
		package_name =>		'im_project',
		type_extension_table=>	null,
		name_method =>		'im_project.name'
	);
end;
/
show errors;


create table im_projects (
	project_id		integer
				constraint im_projects_pk 
				primary key 
				constraint im_project_prj_fk 
				references acs_objects,
	project_name		varchar(1000) not null,
	project_nr		varchar(100) not null
				constraint im_projects_nr_un unique,
	project_path		varchar(100) not null
				constraint im_projects_path_un unique,
	parent_id		integer 
				constraint im_projects_parent_fk 
				references im_projects,
        tree_sortkey		raw(240),
        max_child_sortkey	raw(100),
	company_id		integer not null
				constraint im_projects_company_fk 
				references im_companies,
	-- type of actions pursued during the project 
	-- implementation, for example "ERP Installation" or
	-- "ERP Upgrade", ...
	project_type_id		not null 
				constraint im_projects_prj_type_fk 
				references im_categories,
	-- status in the project cycle, from "potential", "quoting", ... to
	-- "open", "invoicing", "paid", "closed"
	project_status_id	not null 
				constraint im_projects_prj_status_fk 
				references im_categories,
	description		varchar(4000),
	billing_type_id		integer
				constraint im_project_billing_fk
				references im_categories,
	start_date		date,
	end_date		date,
				-- make sure the end date is after the start date
				constraint im_projects_date_const 
				check( end_date - start_date >= 0 ),	
	note			varchar(4000),
	-- project leader is responsible for the operational execution
	project_lead_id		integer 
				constraint im_projects_prj_lead_fk 
				references users,
	-- supervisor is the manager responsible for the financial success
	supervisor_id		integer 
				constraint im_projects_supervisor_fk 
				references users,
	requires_report_p	char(1) default('t')
				constraint im_project_requires_report_p 
				check (requires_report_p in ('t','f')),
	project_budget		number(12,2)
);

create index im_project_parent_id_idx on im_projects(parent_id);
-- create index im_project_status_id_idx on im_projects(project_status_id);
-- create index im_project_project_nr_idx on im_projects(project_nr);

-- Dont allow the same name for the same company+level
alter table im_projects add
	constraint im_projects_name_un 
	unique(project_name, company_id, parent_id);

-- This is the sortkey code
--
create or replace trigger im_project_insert_tr
before insert on im_projects
for each row
declare
    v_max_child_sortkey             im_projects.max_child_sortkey%TYPE;
    v_parent_sortkey                im_projects.tree_sortkey%TYPE;
begin

    if :new.parent_id is null
    then
        :new.tree_sortkey := lpad(tree.int_to_hex(:new.project_id + 1000), 6, '0');

    else

        select tree_sortkey, tree.increment_key(max_child_sortkey)
        into v_parent_sortkey, v_max_child_sortkey
        from im_projects
        where project_id = :new.parent_id
        for update of max_child_sortkey;

        update im_projects
        set max_child_sortkey = v_max_child_sortkey
        where project_id = :new.parent_id;

	:new.tree_sortkey := v_parent_sortkey || v_max_child_sortkey;
    end if;

    :new.max_child_sortkey := null;
end im_project_insert_tr;
/
show errors

create or replace trigger im_projects_update_tr
before update on im_projects
for each row
declare
        v_parent_sk		im_projects.tree_sortkey%TYPE;
        v_max_child_sortkey     im_projects.max_child_sortkey%TYPE;
        v_old_parent_length     integer;
begin
	if :new.project_id != :old.project_id 
	   or ( (:new.parent_id != :old.parent_id) 
	        and 
		(:new.parent_id is not null or :old.parent_id is not null) ) then
	   -- the tree sortkey is going to change so get the new one and update it and all its
	   -- children to have the new prefix...
	   v_old_parent_length := length(:new.tree_sortkey) + 1;

	   if :new.parent_id is null then
	        v_parent_sk := lpad(tree.int_to_hex(:new.project_id + 1000), 6, '0');
	   else
		SELECT tree_sortkey, tree.increment_key(max_child_sortkey)
		INTO v_parent_sk, v_max_child_sortkey
		FROM im_projects
		WHERE project_id = :new.parent_id
		FOR UPDATE;

		UPDATE im_projects
		SET max_child_sortkey = v_max_child_sortkey
		WHERE project_id = :new.parent_id;

		v_parent_sk := v_parent_sk || v_max_child_sortkey;
	   end if;

	   UPDATE im_projects
	   SET tree_sortkey = v_parent_sk || substr(tree_sortkey, v_old_parent_length)
	   WHERE tree_sortkey between :new.tree_sortkey and tree.right(:new.tree_sortkey);
	end if;
end im_projects_update_tr;
/
show errors

-- ------------------------------------------------------------
-- Project Package
-- ------------------------------------------------------------

create or replace package im_project
is
    function new (
	project_id	in integer default null,
	object_type	in varchar default 'im_project',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	project_name	in im_projects.project_name%TYPE,
	project_nr	in im_projects.project_nr%TYPE,
	project_path	in im_projects.project_path%TYPE,
	parent_id	in im_projects.parent_id%TYPE default null,
	company_id	in im_projects.company_id%TYPE,
	project_type_id	in im_projects.project_type_id%TYPE default 85,
	project_status_id in im_projects.project_status_id%TYPE default 76
    ) return im_projects.project_id%TYPE;

    procedure del (project_id in integer);
    function name (project_id in integer) return varchar;
    function type (project_id in integer) return integer;
end im_project;
/
show errors



create or replace package body im_project
is

	function new (
		project_id	in integer default null,
		object_type	in varchar default 'im_project',
		creation_date	in date default sysdate,
		creation_user	in integer default null,
		creation_ip	in varchar default null,
		context_id	in integer default null,
		project_name	in im_projects.project_name%TYPE,
		project_nr	in im_projects.project_nr%TYPE,
		project_path	in im_projects.project_path%TYPE,
		parent_id	in im_projects.parent_id%TYPE default null,
		company_id	in im_projects.company_id%TYPE,
		project_type_id	in im_projects.project_type_id%TYPE default 93,
		project_status_id in im_projects.project_status_id%TYPE default 76
	) return im_projects.project_id%TYPE
	is
		v_project_id		im_projects.project_id%TYPE;
	begin
		v_project_id := acs_object.new (
			object_id	=>		project_id,
			object_type	=>		object_type,
			creation_date	=>	creation_date,
			creation_user	=>	creation_user,
			creation_ip	=>		creation_ip,
			context_id	=>		context_id
		);

		insert into im_projects (
			project_id, project_name, project_nr, 
			project_path, parent_id, company_id, project_type_id, 
			project_status_id 
		) values (
			v_project_id, project_name, project_nr, 
			project_path, parent_id, company_id, project_type_id, 
			project_status_id
		);
		return v_project_id;
	end new;


	-- Delete a single project (if we know its ID...)
	procedure del (project_id in integer)
	is
		v_project_id		integer;
	begin
		-- copy the variable to desambiguate the var name
		v_project_id := project_id;

		-- Erase the im_projects item associated with the id
		delete from 	im_projects
		where		project_id = v_project_id;

		-- Erase all the priviledges
		delete from 	acs_permissions
		where		object_id = v_project_id;

		acs_object.del(v_project_id);
	end del;

	function name (project_id in integer) return varchar
	is
		v_project_id	integer;
		v_name		im_projects.project_name%TYPE;
	begin
		v_project_id := project_id;

		select	project_name
		into	v_name
		from	im_projects
		where	project_id = v_project_id;
	
		return v_name;
	end name;

	function type (project_id in integer) return integer
	is
		v_type_id	integer;
	begin
		select	project_type_id
		into	v_type_id
		from	im_projects
		where	project_id = type.project_id;
	
		return v_type_id;
	end type;


end im_project;
/
show errors


-- What types of urls do we ask for when creating a new project
-- and in what order?
create sequence im_url_types_type_id_seq start with 1;
create table im_url_types (
	url_type_id		integer not null primary key,
	url_type		varchar(200) not null 
				constraint im_url_types_type_un unique,
	-- we need a little bit of meta data to know how to ask 
	-- the user to populate this field
	to_ask			varchar(1000) not null,
	-- if we put this information into a table, what is the 
	-- header for this type of url?
	to_display		varchar(100) not null,
	display_order		integer default 1
);


-- An old ACS 3.4 Intranet table that is not currently in use.
-- However, it is currently included to facilitate the porting
-- process to OpenACS 5.0

create table im_project_url_map (
	project_id		not null 
				constraint im_project_url_map_project_fk
				references im_projects,
	url_type_id		not null
				constraint im_project_url_map_url_type_fk
				references im_url_types,
	url			varchar(250),
	-- each project can have exactly one type of each type
	-- of url
	primary key (project_id, url_type_id)
);

-- We need to create an index on url_type_id if we ever want to ask
-- "What are all the staff servers?"
create index im_proj_url_url_proj_idx on 
im_project_url_map(url_type_id, project_id);



create or replace function im_proj_url_from_type ( 
	v_project_id IN integer, 
	v_url_type IN varchar )
return varchar
IS 
	v_url 		im_project_url_map.url%TYPE;
BEGIN
	begin
	select url 
	into v_url 
	from 
		im_url_types, 
		im_project_url_map
	where 
		project_id=v_project_id
		and im_url_types.url_type_id=im_project_url_map.url_type_id
		and url_type=v_url_type;
	
	exception when others then null;
	end;
	return v_url;
END;
/
show errors;


--------------------------------------------------------------
-- Import definitions common to all DBs




-- /packages/intranet-core/sql/postgres/intranet-projects.sql
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

-- Projects
--
-- Each project can have any number of sub-projects

select acs_object_type__create_type (
        'im_projectoffice',            -- object_type
        'Project',               -- pretty_name
        'Projects',              -- pretty_plural
        'im_biz_object',        -- supertype
        'im_projects',           -- table_name
        'project_id',            -- id_column
        'im_project',            -- package_name
        'f',                    -- abstract_p
        null,                   -- type_extension_table
        'im_project__name'       -- name_method
);

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
	company_id		integer not null
				constraint im_projects_company_fk 
				references im_companies,
	-- type of actions pursued during the project 
	-- implementation, for example "ERP Installation" or
	-- "ERP Upgrade", ...
	project_type_id		integer not null 
				constraint im_projects_prj_type_fk 
				references im_categories,
	-- status in the project cycle, from "potential", "quoting", ... to
	-- "open", "invoicing", "paid", "closed"
	project_status_id	integer not null 
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
	project_budget		float
);

create index im_project_parent_id_idx on im_projects(parent_id);
-- create index im_project_status_id_idx on im_projects(project_status_id);
-- create index im_project_project_nr_idx on im_projects(project_nr);

-- Dont allow the same name for the same company+level
alter table im_projects add
	constraint im_projects_name_un 
	unique(project_name, company_id, parent_id);


-- ------------------------------------------------------------
-- Project Package
-- ------------------------------------------------------------

-- Setup the list of roles that a user can take with
-- respect to a project:
--	Full Member (1300) and
--	Project Manager (1301)
--
insert into im_biz_object_role_map values ('im_project',85,1300);
insert into im_biz_object_role_map values ('im_project',85,1301);
insert into im_biz_object_role_map values ('im_project',86,1300);
insert into im_biz_object_role_map values ('im_project',86,1301);

create or replace function im_project__new (
        integer, varchar, timestamptz, integer, varchar, integer,
        varchar, varchar, varchar, integer, integer, integer, integer
) returns integer as '
DECLARE
        office_id       alias for $1;
        object_type     alias for $2;
        creation_date   alias for $3;
        creation_user   alias for $4;
        creation_ip     alias for $5;
        context_id      alias for $6;

	project_name	alias for $7;
	project_nr	alias for $8;
	project_path	alias for $9;
	parent_id	alias for $10;
	company_id	alias for $11;
	project_type_id	alias for $12;
	project_status_id alias for $13;

	v_project_id	  integer;
BEGIN
       v_project_id := acs_object.new (
                office_id,
                object_type,
                creation_date,
                creation_user,
                creation_ip,
                context_id
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
end;' language 'plpgsql';

create or replace function im_project__del (integer) returns integer as '
DECLARE
        v_project_id             alias for $1;
BEGIN
	-- Erase the im_projects item associated with the id
	delete from 	im_projects
	where		project_id = v_project_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_project_id;

	acs_object.del(v_project_id);
end;' language 'plpgsql';

create or replace function im_project__name (integer) returns varchar as '
DECLARE
	v_project_id	alias for $1;
        v_name		varchar;
BEGIN
	select	project_name
	into	v_name
	from	im_projects
	where	project_id = v_project_id;

	return v_name;
end;' language 'plpgsql';


-- What types of urls do we ask for when creating a new project
-- and in what order?
create sequence im_url_types_type_id_seq start 1;
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


create table im_project_url_map (
	project_id		integer not null 
				constraint im_project_url_map_project_fk
				references im_projects,
	url_type_id		integer not null
				constraint im_project_url_map_url_type_fk
				references im_url_types,
	url			varchar(4000),
	-- each project can have exactly one type of each type
	-- of url
	primary key (project_id, url_type_id)
);

-- We need to create an index on url_type_id if we ever want to ask
-- "What are all the staff servers?"
create index im_proj_url_url_proj_idx on 
im_project_url_map(url_type_id, project_id);


create or replace function im_proj_url_from_type ( integer, varchar) 
returns varchar as '
DECLARE
	v_project_id	alias for $1;
	v_url_type	alias for $2;
	v_url 		varchar;
BEGIN
	begin
	select url 
	into v_url 
	from 	im_url_types, 
		im_project_url_map
	where	project_id=v_project_id
		and im_url_types.url_type_id=im_project_url_map.url_type_id
		and url_type=v_url_type;
	
	exception when others then null;
	end;
	return v_url;
end;' language 'plpgsql';

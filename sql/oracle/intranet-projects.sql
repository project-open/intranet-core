-- /packages/intranet/sql/oracle/intranet-projects.sql
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
show errors


create table im_projects (
	project_id		integer
				constraint im_projects_pk 
				primary key 
				constraint im_project_prj_fk 
				references acs_objects,
	project_name		varchar(1000) not null
				constraint im_projects_name_un unique,
	project_nr		varchar(100) not null
				constraint im_projects_nr_un unique,
	project_path		varchar(100) not null
				constraint im_projects_path_un unique,
	parent_id		integer 
				constraint im_projects_parent_fk 
				references im_projects,
	customer_id		integer not null
				constraint im_projects_customer_fk 
				references im_customers,
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
	customer_id	in im_projects.customer_id%TYPE,
	project_type_id	in im_projects.project_type_id%TYPE default 85,
	project_status_id in im_projects.project_status_id%TYPE default 76
    ) return im_projects.project_id%TYPE;

    procedure del (project_id in integer);
    function name (project_id in integer) return varchar;
    function type (project_id in integer) return integer;
end im_project;
/
show errors



-- Setup the list of roles that a user can take with
-- respect to a project:
--	Full Member (1300) and
--	Project Manager (1301)
--
insert into im_biz_object_role_map values ('im_project',85,1300);
insert into im_biz_object_role_map values ('im_project',85,1301);
insert into im_biz_object_role_map values ('im_project',86,1300);
insert into im_biz_object_role_map values ('im_project',86,1301);


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
		customer_id	in im_projects.customer_id%TYPE,
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
			project_path, parent_id, customer_id, project_type_id, 
			project_status_id 
		) values (
			v_project_id, project_name, project_nr, 
			project_path, parent_id, customer_id, project_type_id, 
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


-- Table to store all changes in the project status field,
-- to be able to track the evolution of the project history 
-- in a timeline.

create table im_projects_status_audit (
	project_id		integer,
	project_status_id	integer,
	audit_date		date
);
create index im_proj_status_aud_id_idx on im_projects_status_audit(project_id);

create or replace trigger im_projects_status_audit_tr
before update or delete on im_projects
for each row
begin
	insert into im_projects_status_audit (
		project_id, project_status_id, audit_date
	) values (
		:old.project_id, :old.project_status_id, sysdate
	);
end im_projects_status_audit_tr;
/
show errors


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



-- Create an "internal" project implementing P/O
declare
	v_project_id		integer;
	v_internal_customer_id	integer;
	v_rel_id		integer;
	v_user_id		integer;
begin
	select customer_id
	into v_internal_customer_id
	from im_customers
	where customer_path = 'internal';

	v_project_id := im_project.new(
		object_type	=> 'im_project',
		project_name	=> 'Project/Open Installation',
		project_nr	=> 'po_install',
		project_path	=> 'po_install',
		customer_id	=> v_internal_customer_id
	);

	-- Add some users
	-- 1300 is full member, 1301 is PM, 1302 is Key Account
	select party_id	into v_user_id
	from parties where email='project.manager@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1301
	);

	select party_id	into v_user_id
	from parties where email='staff.member1@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='system.administrator@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='senior.manager@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='free.lance1@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);
end;
/
commit;


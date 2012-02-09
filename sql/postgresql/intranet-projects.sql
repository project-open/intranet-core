-- /packages/intranet-core/sql/postgres/intranet-projects.sql
--
-- Copyright (C) 1999-2008 various parties
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
-- @author	unknown@arsdigita.com
-- @author	frank.bergmann@project-open.com
-- @author	juanjoruizx@yahoo.es

-- Projects
--
-- Each project can have any number of sub-projects

select acs_object_type__create_type (
	'im_project',		-- object_type
	'Project',		-- pretty_name
	'Projects',		-- pretty_plural
	'im_biz_object',	-- supertype
	'im_projects',		-- table_name
	'project_id',		-- id_column
	'im_project',		-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_project__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_project', 'im_projects', 'project_id');

update acs_object_types set
	status_type_table = 'im_projects',
	status_column = 'project_status_id',
	type_column = 'project_type_id'
where object_type = 'im_project';

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_project','view','/intranet/projects/view?project_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_project','edit','/intranet/projects/new?project_id=');



create table im_projects (
	project_id			integer
					constraint im_projects_pk 
					primary key 
					constraint im_project_prj_fk 
					references acs_objects,
	project_name			varchar(1000) not null,
	project_nr			varchar(100) not null,
	project_path			varchar(100) not null,
	parent_id			integer 
					constraint im_projects_parent_fk 
					references im_projects,
	tree_sortkey			varbit,
	max_child_sortkey		varbit,

	-- Should be customer_id, but got renamed badly...
	company_id			integer not null
					constraint im_projects_company_fk 
					references im_companies,
	-- Should be customer_project_nr. Refers to the customers
	-- reference to our project.
	company_project_nr		varchar(200),
	-- Field indicating the final_customer if we are a subcontractor
	final_company			varchar(200),
	-- type of actions pursued during the project 
	-- implementation, for example "ERP Installation" or
	-- "ERP Upgrade", ...
	project_type_id			integer not null 
					constraint im_projects_prj_type_fk 
					references im_categories,
	-- status in the project cycle, from "potential", "quoting", ... to
	-- "open", "invoicing", "paid", "closed"
	project_status_id		integer not null 
					constraint im_projects_prj_status_fk 
					references im_categories,
	description			text,
	billing_type_id			integer
					constraint im_project_billing_fk
					references im_categories,
	start_date			timestamptz,
	end_date			timestamptz,
	-- make sure the end date is after the start date
					constraint im_projects_date_const 
					check((end_date::date - start_date::date) >= 0),	
	note				text,
	-- project leader is responsible for the operational execution
	project_lead_id			integer 
					constraint im_projects_prj_lead_fk 
					references users,
	-- supervisor is the manager responsible for the financial success
	supervisor_id			integer 
					constraint im_projects_supervisor_fk 
					references users,
	-- board sponsor
	corporate_sponsor_id		integer
					constraint im_projects_sponsor_fk
					references users,
	requires_report_p		char(1) default('t')
					constraint im_project_requires_report_p 
					check (requires_report_p in ('t','f')),
	-- Total project budget (top-down planned)
	project_budget			float,
	project_budget_currency		char(3)
					constraint im_projects_budget_currency_fk
					references currency_codes(iso),
	-- Max number of hours for project.
	-- Does not require "view_finance" permission
	project_budget_hours		float,
	-- completion perc. estimation
	percent_completed		float
					constraint im_project_percent_completed_ck
					check (
						percent_completed >= 0 
						and percent_completed <= 100
					),
	-- green, yellow or red?
	on_track_status_id		integer
					constraint im_project_on_track_status_id_fk
					references im_categories,
	-- Should this project appear in the list of templates?
	template_p			char(1) default('f')
					constraint im_project_template_p
					check (requires_report_p in ('t','f')),
	company_contact_id		integer
					constraint im_project_company_contact_id_fk
					references users,
	sort_order			integer,
	cost_quotes_cache		numeric(12,2) default 0,
	cost_invoices_cache		numeric(12,2) default 0,
	cost_timesheet_planned_cache	numeric(12,2) default 0,
	cost_purchase_orders_cache	numeric(12,2) default 0,
	cost_bills_cache		numeric(12,2) default 0,
	cost_timesheet_logged_cache	numeric(12,2) default 0,
	cost_delivery_notes_cache	numeric(12,2) default 0,
	cost_expense_planned_cache	numeric(12,2) default 0,
	cost_expense_logged_cache	numeric(12,2) default 0,
	reported_hours_cache		numeric(12,2) default 0,
	reported_days_cache		numeric(12,2) default 0,
	-- Dirty field indicates that the cache needs to be recalculated
	cost_cache_dirty		timestamptz,

	-- Presales Pipeline
	presales_probability		numeric(5,2),
	presales_value			numeric(12,2),

	-- Groups of projects = "program"
	-- To be added to the ProjectNewPage via DynField
	program_id			integer
					constraint im_projects_program_id
					references im_projects
);


-- Speed up tree queries
create index im_project_parent_id_idx on im_projects(parent_id);


-- Speed up child-sortkey queries
create index im_project_treesort_idx on im_projects(tree_sortkey);

-- Relaxed unique constraint for tasks...
alter table im_projects add constraint 
im_projects_path_un UNIQUE (project_nr, company_id, parent_id);




-- This is the sortkey code
--
create or replace function im_project_insert_tr ()
returns opaque as '
declare
	v_max_child_sortkey		im_projects.max_child_sortkey%TYPE;
	v_parent_sortkey		im_projects.tree_sortkey%TYPE;
begin

	if new.parent_id is null
	then
	new.tree_sortkey := int_to_tree_key(new.project_id+1000);

	else

	select tree_sortkey, tree_increment_key(max_child_sortkey)
	into v_parent_sortkey, v_max_child_sortkey
	from im_projects
	where project_id = new.parent_id
	for update;

	update im_projects
	set max_child_sortkey = v_max_child_sortkey
	where project_id = new.parent_id;

	new.tree_sortkey := v_parent_sortkey || v_max_child_sortkey;

	end if;

	new.max_child_sortkey := null;

	return new;
end;' language 'plpgsql';

create trigger im_project_insert_tr
before insert on im_projects
for each row
execute procedure im_project_insert_tr();



create or replace function im_projects_update_tr () returns opaque as '
declare
	v_parent_sk	varbit default null;
	v_max_child_sortkey	varbit;
	v_old_parent_length	integer;
begin
	if new.project_id = old.project_id
	and ((new.parent_id = old.parent_id)
		or (new.parent_id is null
		and old.parent_id is null)) then

	return new;

	end if;

	-- the tree sortkey is going to change so get the new one and update it and all its
	-- children to have the new prefix...
	v_old_parent_length := length(new.tree_sortkey) + 1;

	if new.parent_id is null then
	v_parent_sk := int_to_tree_key(new.project_id+1000);
	else
		SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
		INTO v_parent_sk, v_max_child_sortkey
		FROM im_projects
		WHERE project_id = new.parent_id
		FOR UPDATE;

		UPDATE im_projects
		SET max_child_sortkey = v_max_child_sortkey
		WHERE project_id = new.parent_id;

		v_parent_sk := v_parent_sk || v_max_child_sortkey;
	end if;

	UPDATE im_projects
	SET tree_sortkey = v_parent_sk || substring(tree_sortkey, v_old_parent_length)
	WHERE tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);

	return new;
end;' language 'plpgsql';

create trigger im_projects_update_tr after update
on im_projects
for each row
execute procedure im_projects_update_tr ();


-- Create unique indices instead of constraints
-- because we need the coalesce(parent_id,0).
create unique index im_projects_name_un on im_projects (project_name, company_id, coalesce(parent_id,0));
create unique index im_projects_nr_un on im_projects (project_nr, company_id, coalesce(parent_id,0));
create unique index im_projects_path_un on im_projects (project_path, company_id, coalesce(parent_id,0));


-- Optional Indices for larger systems:
-- create index im_project_status_id_idx on im_projects(project_status_id);
-- create index im_project_type_id_idx on im_projects(project_type_id);
-- create index im_project_project_nr_idx on im_projects(project_nr);


-- ------------------------------------------------------------
-- Project Package
-- ------------------------------------------------------------

create or replace function im_project__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, integer, integer, integer
) returns integer as '
DECLARE
	p_project_id	alias for $1;
	p_object_type	alias for $2;
	p_creation_date   alias for $3;
	p_creation_user   alias for $4;
	p_creation_ip	alias for $5;
	p_context_id	alias for $6;

	p_project_name	alias for $7;
	p_project_nr	alias for $8;
	p_project_path	alias for $9;
	p_parent_id	alias for $10;
	p_company_id	alias for $11;
	p_project_type_id	alias for $12;
	p_project_status_id alias for $13;

	v_project_id	integer;
BEGIN
	v_project_id := acs_object__new (
		p_project_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_biz_objects (object_id) values (v_project_id);

	insert into im_projects (
		project_id, project_name, project_nr, 
		project_path, parent_id, company_id, project_type_id, 
		project_status_id 
	) values (
		v_project_id, p_project_name, p_project_nr, 
		p_project_path, p_parent_id, p_company_id, p_project_type_id, 
		p_project_status_id
	);
	return v_project_id;
end;' language 'plpgsql';

create or replace function im_project__delete (integer) returns integer as '
DECLARE
	v_project_id		alias for $1;
BEGIN
	-- Erase the im_projects item associated with the id
	delete from 	im_projects
	where		project_id = v_project_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_project_id;

	PERFORM	acs_object__delete(v_project_id);

	return 0;
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
	to_ask			text not null,
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
	url			text,
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
		and im_url_types.url_type_id=v_url_type
		and url_type=v_url_type;
	
	end;
	return v_url;
end;' language 'plpgsql';



-- Helper functions to make our queries easier to read
-- and to avoid outer joins with parent projects etc.
create or replace function im_project_name_from_id (integer)
returns varchar as '
DECLARE
	p_project_id	alias for $1;
	v_project_name	varchar;
BEGIN
	select project_name
	into v_project_name
	from im_projects
	where project_id = p_project_id;

	return v_project_name;
end;' language 'plpgsql';


create or replace function im_project_nr_from_id (integer)
returns varchar as '
DECLARE
	p_project_id	alias for $1;
	v_name		varchar;
BEGIN
	select project_nr
	into v_name
	from im_projects
	where project_id = p_project_id;

	return v_name;
end;' language 'plpgsql';



create or replace function im_project_managers_enumerator (integer) 
returns setof integer as '
declare
	p_project_id		alias for $1;

	v_project_id		integer;
	v_parent_id		integer;
	v_project_lead_id	integer;
	v_count			integer;
BEGIN
	v_project_id := p_project_id;
	v_count := 100;

	WHILE (v_project_id is not null AND v_count > 0) LOOP
		select	parent_id, project_lead_id into v_parent_id, v_project_lead_id
		from	im_projects where project_id = v_project_id;

		IF v_project_lead_id is not null THEN RETURN NEXT v_project_lead_id; END IF;
		v_project_id := v_parent_id;
		v_count := v_count - 1;
	END LOOP;

	RETURN;
end;' language 'plpgsql';



-- Indent a project 4 spaces for everyl level...
CREATE or REPLACE FUNCTION im_project_level_spaces(integer)
RETURNS varchar as $body$
DECLARE
	p_level		alias for $1;
	v_result	varchar;
	i		integer;
BEGIN
	v_result := '';
	FOR i IN 1..p_level LOOP
		v_result := v_result || '    ';
	END LOOP;
	RETURN v_result;
END; $body$ LANGUAGE 'plpgsql';


-- Returns a space separated list of the project_nr of the parents
CREATE or REPLACE FUNCTION im_project_nr_parent_list(integer, varchar, integer)
RETURNS varchar as $body$
DECLARE
	p_project_id		alias for $1;
	p_spacer		alias for $2;
	p_level			alias for $3;

	v_result		varchar;
	v_project_nr		varchar;
	v_parent_id		integer;
BEGIN
	-- End of recursion.
	IF p_project_id is NULL THEN RETURN ''; END IF;

	-- Error checking to avoid infinite loops within the DB...
	IF p_level > 10 THEN RETURN '- infinite loop with project_id='||p_project_id; END IF;

	-- Get the NR of the current project plus the parent_id
	select	p.project_nr, p.parent_id
	into	v_project_nr, v_parent_id
	from	im_projects p 
	where	p.project_id = p_project_id;

	-- Recurse for the parent projects
	v_result = im_project_nr_parent_list(v_parent_id, p_spacer, p_level+1);
	IF v_result != '' THEN v_result := v_result || p_spacer; END IF;
	v_result := v_result || v_project_nr;

	RETURN v_result;
END; $body$ LANGUAGE 'plpgsql';


-- Shortcut function with only one argument
CREATE or REPLACE FUNCTION im_project_nr_parent_list(integer)
RETURNS varchar as $body$
DECLARE
	p_project_id		alias for $1;
BEGIN
	RETURN im_project_nr_parent_list(p_project_id, ' ', 0);
END; $body$ LANGUAGE 'plpgsql';


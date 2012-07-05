-- /packages/intranet-core/sql/oracle/intranet-biz-objects.sql
--
-- Copyright (C) 1999 - 2009 ]project-open[
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
-- @author frank.bergmann@project-open.com

-- Business objects can be associated to 
-- users using a "role", which depends on the Busines
-- Object (OpenACS object type ) and the "Object Type" 
-- (this is a field common to all of these objects).


-- ------------------------------------------------------------
-- Business Object
-- ------------------------------------------------------------

-- BizObjects have in a common "type()" method that allows
-- to select suitable roles for them in which to assign
-- members.

select acs_object_type__create_type (
	'im_biz_object',	-- object_type
	'Business Object',	-- pretty_name
	'Business Objects',	-- pretty_plural
	'acs_object',		-- supertype
	'im_biz_objects',	-- table_name
	'object_id',		-- id_column
	'im_biz_object',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_biz_object__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_biz_object', 'im_biz_objects', 'object_id');

CREATE TABLE im_biz_objects (
	object_id 		integer
				constraint im_biz_object_id_pk
				primary key
				constraint im_biz_object_id_fk
				references acs_objects,
	-- Information about object locking.
	-- Stores the information of the last person
	-- clicking on the "Edit" button of an object.
	lock_user		integer
				constraint im_biz_object_lock_user_fk
				references persons,
	lock_date		timestamptz
	lock_ip			text
);



-- ---------------------------------------------------------------
-- Extend the OpenACS type system by subtypes and status

alter table acs_object_types
add status_column character varying(30);

alter table acs_object_types
add type_column character varying(30);

alter table acs_object_types
add status_type_table character varying(30);


-- ---------------------------------------------------------------
-- Find out the status and type of business objects in a generic way

CREATE OR REPLACE FUNCTION im_biz_object__get_type_id (integer)
RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;

	v_query			varchar;
	v_object_type		varchar;
	v_supertype		varchar;
	v_table			varchar;
	v_id_column		varchar;
	v_type_column		varchar;

	row			RECORD;
	v_result_id		integer;
BEGIN
	-- Get information from SQL metadata system
	select	ot.object_type, ot.supertype, ot.status_type_table, ot.type_column
	into	v_object_type, v_supertype, v_table, v_type_column
	from	acs_objects o, acs_object_types ot
	where	o.object_id = p_object_id
		and o.object_type = ot.object_type;

	-- Check if the object has a supertype and update table necessary
	WHILE v_table is null AND ''acs_object'' != v_supertype AND ''im_biz_object'' != v_supertype LOOP
		select	ot.supertype, ot.table_name
		into	v_supertype, v_table
		from	acs_object_types ot
		where	ot.object_type = v_supertype;
	END LOOP;

	-- Get the id_column for v_table
	select	aott.id_column into v_id_column from acs_object_type_tables aott
	where	aott.object_type = v_object_type and aott.table_name = v_table;

	IF v_table is null OR v_id_column is null OR v_type_column is null THEN
		return 0;
	END IF;

	-- Funny way, but this is the only option to EXECUTE in PG 8.0 and below.
	v_query := '' select '' || v_type_column || '' as result_id '' || '' from '' || v_table || 
		'' where '' || v_id_column || '' = '' || p_object_id;
	FOR row IN EXECUTE v_query
	LOOP
		v_result_id := row.result_id;
		EXIT;
	END LOOP;

	return v_result_id;
END;' language 'plpgsql';


-- Get the object status for generic objects
-- This function relies on the information in the OpenACS SQL metadata
-- system, so that errors in the OO configuration will give errors here.
-- Basically, the acs_object_types table contains the name and the column
-- of the table that stores the "status_id" for the given object type.
-- We will pull out this information and then dynamically create a SQL
-- statement to extract this information.
---
CREATE OR REPLACE FUNCTION im_biz_object__get_status_id (integer)
RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;

	v_object_type		varchar;
	v_supertype		varchar;

	v_status_table		varchar;
	v_status_column		varchar;
	v_status_table_id_col	varchar;

	v_query			varchar;
	row			RECORD;
	v_result_id		integer;
BEGIN
	-- Get information from SQL metadata system
	select	ot.object_type, ot.supertype, ot.status_type_table, ot.status_column
	into	v_object_type, v_supertype, v_status_table, v_status_column
	from	acs_objects o, acs_object_types ot
	where	o.object_id = p_object_id and o.object_type = ot.object_type;

	-- In the case that the information about should not be set up correctly:
	-- Check if the object has a supertype and update table and id_column if necessary
	WHILE v_status_table is null AND ''acs_object'' != v_supertype AND ''im_biz_object'' != v_supertype LOOP
		select	ot.supertype, ot.status_type_table, ot.id_column
		into	v_supertype, v_status_table, v_status_table_id_col
		from	acs_object_types ot
		where	ot.object_type = v_supertype;
	END LOOP;

	-- Get the id_column for the v_status_table (not the objects main table...)
	select	distinct aott.id_column into v_status_table_id_col from acs_object_type_tables aott
	where	aott.object_type = v_object_type and aott.table_name = v_status_table;

	-- Avoid reporting an error. However, this may make it more difficult diagnosing errors.
	IF v_status_table is null OR v_status_table_id_col is null OR v_status_column is null THEN
		return 0;
	END IF;

	-- Funny way, but this is the only option to get a value from an EXECUTE in PG 8.0 and below.
	v_query := '' select '' || v_status_column || '' as result_id '' || '' from '' || v_status_table || 
		'' where '' || v_status_table_id_col || '' = '' || p_object_id;
	FOR row IN EXECUTE v_query
	LOOP
		v_result_id := row.result_id;
		EXIT;
	END LOOP;

	return v_result_id;
END;' language 'plpgsql';



-----------------------------------------------------------------------
-- Set the status of Biz Objects in a generic way


CREATE OR REPLACE FUNCTION im_biz_object__set_status_id (integer, integer) RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;
	p_status_id		alias for $2;
	v_object_type		varchar;
	v_supertype		varchar;	v_table			varchar;
	v_id_column		varchar;	v_column		varchar;
	row			RECORD;
BEGIN
	-- Get information from SQL metadata system
	select	ot.object_type, ot.supertype, ot.table_name, ot.id_column, ot.status_column
	into	v_object_type, v_supertype, v_table, v_id_column, v_column
	from	acs_objects o, acs_object_types ot
	where	o.object_id = p_object_id
		and o.object_type = ot.object_type;

	-- Check if the object has a supertype and update table and id_column if necessary
	WHILE ''acs_object'' != v_supertype AND ''im_biz_object'' != v_supertype LOOP
		select	ot.supertype, ot.table_name, ot.id_column
		into	v_supertype, v_table, v_id_column
		from	acs_object_types ot
		where	ot.object_type = v_supertype;
	END LOOP;

	IF v_table is null OR v_id_column is null OR v_column is null THEN
		RAISE NOTICE ''im_biz_object__set_status_id: Bad metadata: Null value for %'',v_object_type;
		return 0;
	END IF;

	update	acs_objects
	set	last_modified = now()
	where	object_id = p_object_id;

	EXECUTE ''update ''||v_table||'' set ''||v_column||''=''||p_status_id||
		'' where ''||v_id_column||''=''||p_object_id;

	return 0;
END;' language 'plpgsql';



-- compatibility for WF calls
CREATE OR REPLACE FUNCTION im_biz_object__set_status_id (integer, varchar, integer) RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;
	p_dummy			alias for $2;
	p_status_id		alias for $3;
BEGIN
	return im_biz_object__set_status_id (p_object_id, p_status_id::integer);
END;' language 'plpgsql';




-----------------------------------------------------------
-- Store a "view" and an "edit" URLs for each object type.
--
-- fraber 041015: referential integrity to acs_object_types
-- removed because this would require to insert elements into
-- this table _after_ the objects have been created, which is
-- very error prone for DM creation.
--
CREATE TABLE im_biz_object_urls (
	object_type		varchar(1000),
	url_type		varchar(1000)
				constraint im_biz_obj_urls_url_type_ck
				check(url_type in ('view', 'edit')),
	url			text,
		constraint im_biz_obj_urls_pk
		primary key(object_type, url_type)
);



-----------------------------------------------------------
-- Store information about the open/closed status of 
-- hierarchical business objects including projects etc.
--

-- Store the o=open/c=closed status for business objects
-- at certain page URLs.
--
CREATE TABLE im_biz_object_tree_status (
		object_id	integer
				constraint im_biz_object_tree_status_object_nn 
				not null
				constraint im_biz_object_tree_status_object_fk
				references acs_objects on delete cascade,
		user_id		integer
				constraint im_biz_object_tree_status_user_nn 
				not null
				constraint im_biz_object_tree_status_user_fk
				references persons on delete cascade,
		page_url	text
				constraint im_biz_object_tree_status_page_nn 
				not null,

		open_p		char(1)
				constraint im_biz_object_tree_status_open_ck
				CHECK (open_p = 'o'::bpchar OR open_p = 'c'::bpchar),
		last_modified	timestamptz,

	primary key  (object_id, user_id, page_url)
);






-----------------------------------------------------------
--- Business Object PL/SQL API
--
create or replace function im_biz_object__new (integer,varchar,timestamptz,integer,varchar,integer)
returns integer as '
declare
	p_object_id	alias for $1;
	p_object_type	alias for $2;
	p_creation_date	alias for $3;
	p_creation_user	alias for $4;
	p_creation_ip	alias for $5;
	p_context_id	alias for $6;

	v_object_id	integer;
begin
	v_object_id := acs_object__new (
		p_object_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);
	insert into im_biz_objects (object_id) values (v_object_id);
	return v_object_id;

end;' language 'plpgsql';

-- Delete a single object (if we know its ID...)
create or replace function im_biz_object__delete (integer)
returns integer as '
declare
	object_id	alias for $1;
	v_object_id	integer;
begin
	-- Erase the im_biz_objects item associated with the id
	delete from 	im_biz_objects
	where		object_id = del.object_id;

	PERFORM acs_object.del(del.object_id);
	return 0;
end;' language 'plpgsql';


create or replace function im_biz_object__name (integer)
returns varchar as '
declare
	object_id	alias for $1;
begin
	return "undefined for im_biz_object";
end;' language 'plpgsql';


-- Function to determine the type_id of a "im_biz_object".
-- It's a bit ugly to do this via SWITCH, but there aren't many
-- new "Biz Objects" to be added to the system...

create or replace function im_biz_object__type (integer)
returns integer as '
declare
	p_object_id		alias for $1;
	v_object_type		varchar;
	v_biz_object_type_id	integer;
begin

	-- get the object type
	select	object_type
	into	v_object_type
	from	acs_objects
	where	object_id = p_object_id;

	-- Initialize the return value
	v_biz_object_type_id = null;

	IF ''im_project'' = v_object_type THEN

		select	project_type_id
		into	v_biz_object_type_id
		from	im_projects
		where	project_id = p_object_id;

	ELSIF ''im_company'' = v_object_type THEN

		select	company_type_id
		into	v_biz_object_type_id
		from	im_companies
		where	company_id = p_object_id;

	END IF;

	return v_biz_object_type_id;

end;' language 'plpgsql';





-- ------------------------------------------------------------
-- Valid Roles for Biz Objects
-- ------------------------------------------------------------

-- Maps from (acs_object_type + object_type_id) into object_role_id.
-- For example projects (im_project) with type "translation" can 
-- have the object_roles "Translator", "Editor", "Project Manager" etc.
-- This table doesn't actually restrict (RI) the roles between
-- business objects and members, but serves to select "appropriate"
-- membership relationships in the add_member.tcl page and its
-- neighbours.
--
create table im_biz_object_role_map (
	acs_object_type	varchar(1000),
	object_type_id	integer
			constraint im_bizo_rmap_object_type_fk
			references im_categories,
	object_role_id	integer
			constraint im_bizo_rmap_object_role_fk
			references im_categories,
	constraint im_bizo_rmap_un
	unique (acs_object_type, object_type_id, object_role_id)
);


-- ------------------------------------------------------------
-- Intranet Membership Relation
-- ------------------------------------------------------------

create table im_biz_object_members (
	rel_id			integer
				constraint im_biz_object_members_rel_fk
				references acs_rels (rel_id)
				constraint im_biz_object_members_rel_pk
				primary key,
				-- Intranet Project Role
	object_role_id		integer not null
				constraint im_biz_object_members_role_fk
				references im_categories,
				-- Percentage of assignation of resource
	percentage		numeric(8,2) default 100,
				-- Reference to the original 
	skill_profile_rel_id	integer
				constraint im_biz_object_members_skill_profile_rel_fk
				references im_biz_object_members
);

select acs_rel_type__create_type (
	'im_biz_object_member',		-- relationship (object) name
	'Biz Object Relation',		-- pretty name
	'Biz Object Relations',		-- pretty plural
	'relationship',			-- supertype
	'im_biz_object_members',	-- table_name
	'rel_id',			-- id_column
	'im_biz_object_member',		-- package_name
	'acs_object',			-- object_type_one
	'member',			-- role_one
	0,				-- min_n_rels_one
	null,				-- max_n_rels_one
	'person',			-- object_type_two
	'member',			-- role_two
	0,				-- min_n_rels_two
	null				-- max_n_rels_two
);

-- ------------------------------------------------------------
-- Project Membership Packages
-- ------------------------------------------------------------

-- New version of the PlPg/SQL routine with percentage parameter
--
create or replace function im_biz_object_member__new (
integer, varchar, integer, integer, integer, numeric, integer, varchar)
returns integer as '
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_biz_object_member
	p_object_id		alias for $3;	-- object_id_one
	p_user_id		alias for $4;	-- object_id_two
	p_object_role_id	alias for $5;	-- type of relationship
	p_percentage		alias for $6;	-- percentage of assignation
	p_creation_user		alias for $7;	-- null
	p_creation_ip		alias for $8;	-- null

	v_rel_id		integer;
	v_count			integer;
BEGIN
	select	count(*) into v_count from acs_rels
	where	object_id_one = p_object_id
		and object_id_two = p_user_id;

	IF v_count > 0 THEN 
		-- Return the lowest rel_id (might be several?)
		select	min(rel_id) into v_rel_id
		from	acs_rels
		where	object_id_one = p_object_id
			and object_id_two = p_user_id;

		return v_rel_id;
	END IF;

	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,	
		p_object_id,
		p_user_id,
		p_object_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_biz_object_members (
		rel_id, object_role_id, percentage
	) values (
		v_rel_id, p_object_role_id, p_percentage
	);

	return v_rel_id;
end;' language 'plpgsql';


-- Downward compatibility - offers the same API as before
-- with percentage = null
create or replace function im_biz_object_member__new (
integer, varchar, integer, integer, integer, integer, varchar)
returns integer as '
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_biz_object_member
	p_object_id		alias for $3;	-- object_id_one
	p_user_id		alias for $4;	-- object_id_two
	p_object_role_id	alias for $5;	-- type of relationship
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null
BEGIN
	return im_biz_object_member__new (
		p_rel_id, 
		p_rel_type, 
		p_object_id, 
		p_user_id, 
		p_object_role_id, 
		null, 
		p_creation_user, 
		p_creation_ip
	);
end;' language 'plpgsql';






create or replace function im_biz_object_member__delete (integer, integer)
returns integer as '
DECLARE
	p_object_id	alias for $1;
	p_user_id	alias for $2;

	v_rel_id	integer;
BEGIN
	select	rel_id
	into	v_rel_id
	from	acs_rels
	where	object_id_one = p_object_id
		and object_id_two = p_user_id;

	delete	from im_biz_object_members
	where	object_role_id = v_rel_id;

	PERFORM acs_rel__delete(v_rel_id);
	return 0;
end;' language 'plpgsql';




-- Return a TCL list of the member_ids of the members of a 
-- business object.
create or replace function im_biz_object_member__list (integer)
returns varchar as $body$
DECLARE
	p_object_id	alias for $1;
	v_members	varchar;
	row		record;
BEGIN
	v_members := '';
	FOR row IN 
		select	r.rel_id,
			r.object_id_two as party_id,
			coalesce(bom.object_role_id::varchar, '""') as role_id,
			coalesce(bom.percentage::varchar, '""') as percentage
		from	acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			r.object_id_one = p_object_id
		order by party_id
	LOOP
		IF '' != v_members THEN v_members := v_members || ' '; END IF;
		v_members := v_members || '{' || row.party_id || ' ' || row.role_id || ' ' || row.percentage || ' ' || row.rel_id || '}';
	END LOOP;

	return v_members;
end;$body$ language 'plpgsql';



-- ------------------------------------------------------------
-- Add a gif for every object type
-- ------------------------------------------------------------

alter table acs_object_types
add object_type_gif text default 'default_object_type_gif';



update acs_object_types set object_type_gif = 'table'			where object_type = 'im_biz_object';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_biz_object_member';
update acs_object_types set object_type_gif = 'package'			where object_type = 'im_company';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_company_employee_rel';
update acs_object_types set object_type_gif = 'plugin'			where object_type = 'im_component_plugin';
update acs_object_types set object_type_gif = 'computer'		where object_type = 'im_conf_item';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_conf_item_project_rel';
update acs_object_types set object_type_gif = 'page_world'		where object_type = 'im_cost';
update acs_object_types set object_type_gif = 'calculator' 		where object_type = 'im_cost_center';
update acs_object_types set object_type_gif = 'table_add'		where object_type = 'im_dynfield_attribute';
update acs_object_types set object_type_gif = 'table_edit'		where object_type = 'im_dynfield_widget';
update acs_object_types set object_type_gif = 'money'			where object_type = 'im_expense';
update acs_object_types set object_type_gif = 'money_add'		where object_type = 'im_expense_bundle';
update acs_object_types set object_type_gif = 'comment'			where object_type = 'im_forum_topic';
update acs_object_types set object_type_gif = 'phone'			where object_type = 'im_freelance_rfq';
update acs_object_types set object_type_gif = 'phone_sound'		where object_type = 'im_freelance_rfq_answer';
update acs_object_types set object_type_gif = 'folder_page'		where object_type = 'im_fs_file';
update acs_object_types set object_type_gif = 'user_suit'		where object_type = 'im_gantt_person';
update acs_object_types set object_type_gif = 'cog'			where object_type = 'im_gantt_project';
update acs_object_types set object_type_gif = 'report_key'		where object_type = 'im_indicator';
update acs_object_types set object_type_gif = 'page_add'		where object_type = 'im_investment';
update acs_object_types set object_type_gif = 'page'			where object_type = 'im_invoice';
update acs_object_types set object_type_gif = 'page_link'		where object_type = 'im_invoice_item';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_key_account_rel';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_mail_from';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_mail_to';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_mail_related_to';
update acs_object_types set object_type_gif = 'box'			where object_type = 'im_material';
update acs_object_types set object_type_gif = 'palette'			where object_type = 'im_menu';
update acs_object_types set object_type_gif = 'note'			where object_type = 'im_note';
update acs_object_types set object_type_gif = 'package_link'		where object_type = 'im_office';
update acs_object_types set object_type_gif = 'group'			where object_type = 'im_profile';
update acs_object_types set object_type_gif = 'cog'			where object_type = 'im_project';
update acs_object_types set object_type_gif = 'sum'			where object_type = 'im_release_item';
update acs_object_types set object_type_gif = 'page_refresh'		where object_type = 'im_repeating_cost';
update acs_object_types set object_type_gif = 'report'			where object_type = 'im_report';
update acs_object_types set object_type_gif = 'table_sort'		where object_type = 'im_rest_object_type';
update acs_object_types set object_type_gif = 'tag_blue'		where object_type = 'im_ticket';
update acs_object_types set object_type_gif = 'tag_blue_add'		where object_type = 'im_ticket_queue';
update acs_object_types set object_type_gif = 'link'			where object_type = 'im_ticket_ticket_rel';
update acs_object_types set object_type_gif = 'tab'			where object_type = 'im_timesheet_conf_object';
update acs_object_types set object_type_gif = 'page_green'		where object_type = 'im_timesheet_invoice';
update acs_object_types set object_type_gif = 'cog_go'			where object_type = 'im_timesheet_task';
update acs_object_types set object_type_gif = 'page_red'		where object_type = 'im_trans_invoice';
update acs_object_types set object_type_gif = 'cog_edit'		where object_type = 'im_trans_task';
update acs_object_types set object_type_gif = 'cup'			where object_type = 'im_user_absence';

-- Important OpenACS object types
update acs_object_types set object_type_gif = 'email_edit'		where object_type = 'acs_mail_body';
update acs_object_types set object_type_gif = 'email_open'		where object_type = 'acs_mail_gc_object';
update acs_object_types set object_type_gif = 'email_link'		where object_type = 'acs_mail_link';
update acs_object_types set object_type_gif = 'email_link'		where object_type = 'acs_mail_multipart';
update acs_object_types set object_type_gif = 'email_attach'		where object_type = 'acs_mail_queue_message';
update acs_object_types set object_type_gif = 'email'			where object_type = 'acs_message';
update acs_object_types set object_type_gif = 'table'			where object_type = 'acs_object';
update acs_object_types set object_type_gif = 'telephone'		where object_type = 'authority';
update acs_object_types set object_type_gif = 'bug'			where object_type = 'bt_bug';
update acs_object_types set object_type_gif = 'bug_edit'		where object_type = 'bt_bug_revision';
update acs_object_types set object_type_gif = 'bug_go'			where object_type = 'bt_patch';
update acs_object_types set object_type_gif = 'date'			where object_type = 'calendar';
update acs_object_types set object_type_gif = 'date_edit'		where object_type = 'cal_item';
update acs_object_types set object_type_gif = 'group_gear'		where object_type = 'group';
update acs_object_types set object_type_gif = 'bell'			where object_type = 'notification';
update acs_object_types set object_type_gif = 'bell_delete'		where object_type = 'notification_delivery_method';
update acs_object_types set object_type_gif = 'bell_add'		where object_type = 'notification_interval';
update acs_object_types set object_type_gif = 'bell_go'			where object_type = 'notification_reply';
update acs_object_types set object_type_gif = 'bell_link'		where object_type = 'notification_request';
update acs_object_types set object_type_gif = 'bell_error'		where object_type = 'notification_type';
update acs_object_types set object_type_gif = 'package'			where object_type = 'apm_application';
update acs_object_types set object_type_gif = 'package'			where object_type = 'apm_package';
update acs_object_types set object_type_gif = 'package_green'		where object_type = 'apm_package_version';
update acs_object_types set object_type_gif = 'package_link'		where object_type = 'apm_parameter';
update acs_object_types set object_type_gif = 'package_link'		where object_type = 'apm_parameter_value';
update acs_object_types set object_type_gif = 'package'			where object_type = 'apm_service';
update acs_object_types set object_type_gif = 'user_red'		where object_type = 'party';
update acs_object_types set object_type_gif = 'user_green'		where object_type = 'person';
update acs_object_types set object_type_gif = 'script_gear'		where object_type = 'survsimp_question';
update acs_object_types set object_type_gif = 'script_save'		where object_type = 'survsimp_response';
update acs_object_types set object_type_gif = 'script'			where object_type = 'survsimp_survey';
update acs_object_types set object_type_gif = 'user'			where object_type = 'user';

-- Relationships
update acs_object_types set object_type_gif = 'link'			where object_type = 'admin_rel';
update acs_object_types set object_type_gif = 'link'			where object_type = 'composition_rel';
update acs_object_types set object_type_gif = 'link'			where object_type = 'cr_item_child_rel';
update acs_object_types set object_type_gif = 'link'			where object_type = 'cr_item_rel';
update acs_object_types set object_type_gif = 'link'			where object_type = 'membership_rel';
update acs_object_types set object_type_gif = 'link'			where object_type = 'relationship';
update acs_object_types set object_type_gif = 'link'			where object_type = 'user_blob_response_rel';
update acs_object_types set object_type_gif = 'link'			where object_type = 'user_portrait_rel';

-- Workflow
update acs_object_types set object_type_gif = 'arrow_refresh'		where object_type = 'workflow';
update acs_object_types set object_type_gif = 'arrow_refresh'		where object_type = 'ticket_generic_wf';
update acs_object_types set object_type_gif = 'arrow_refresh'		where object_type = 'ticket_workflow_generic_wf';
update acs_object_types set object_type_gif = 'arrow_refresh'		where object_type = 'timesheet_approval_wf';
update acs_object_types set object_type_gif = 'arrow_refresh'		where object_type = 'vacation_approval_wf';
update acs_object_types set object_type_gif = 'arrow_refresh'		where object_type = 'workflow_case_log_entry';
update acs_object_types set object_type_gif = 'arrow_refresh' 		where object_type = 'expense_approval_wf';
update acs_object_types set object_type_gif = 'arrow_refresh' 		where object_type = 'feature_request_wf';
update acs_object_types set object_type_gif = 'arrow_refresh' 		where object_type = 'project_approval_wf';
update acs_object_types set object_type_gif = 'arrow_refresh' 		where object_type = 'rfc_approval_wf';


-- Less used OpenACS object types
update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'acs_activity';
update acs_object_types set object_type_gif = 'lightning'		where object_type = 'acs_event';
update acs_object_types set object_type_gif = 'email'			where object_type = 'acs_message_revision';
update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'acs_named_object';
update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'acs_reference_repository';

update acs_object_types set object_type_gif = 'script'			where object_type = 'acs_sc_contract';
update acs_object_types set object_type_gif = 'script_palette'		where object_type = 'acs_sc_implementation';
update acs_object_types set object_type_gif = 'script_code'		where object_type = 'acs_sc_msg_type';
update acs_object_types set object_type_gif = 'script_go'		where object_type = 'acs_sc_operation';

update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'ams_object_revision';
update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'application_group';
update acs_object_types set object_type_gif = 'comments'		where object_type = 'chat_room';
update acs_object_types set object_type_gif = 'comment_edit'		where object_type = 'chat_transcript';

update acs_object_types set object_type_gif = 'image_link'		where object_type = 'content_extlink';
update acs_object_types set object_type_gif = 'folder_image'		where object_type = 'content_folder';
update acs_object_types set object_type_gif = 'image'			where object_type = 'content_item';
update acs_object_types set object_type_gif = 'image_add'		where object_type = 'content_keyword';
update acs_object_types set object_type_gif = 'folder_image'		where object_type = 'content_module';
update acs_object_types set object_type_gif = 'image_edit'		where object_type = 'content_revision';
update acs_object_types set object_type_gif = 'image_link'		where object_type = 'content_symlink';
update acs_object_types set object_type_gif = 'images'			where object_type = 'content_template';

update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'dynamic_group_type';
update acs_object_types set object_type_gif = 'page_world'		where object_type = 'etp_page_revision';
update acs_object_types set object_type_gif = 'image'			where object_type = 'image';

update acs_object_types set object_type_gif = 'layout_content'		where object_type = 'journal_article';
update acs_object_types set object_type_gif = 'layout'			where object_type = 'journal_entry';
update acs_object_types set object_type_gif = 'layout_header'		where object_type = 'journal_issue';

update acs_object_types set object_type_gif = 'newspaper'		where object_type = 'news_item';
update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'postal_address';
update acs_object_types set object_type_gif = 'link_error'		where object_type = 'rel_constraint';
update acs_object_types set object_type_gif = 'link_add'		where object_type = 'rel_segment';
update acs_object_types set object_type_gif = 'sitemap'			where object_type = 'site_node';
update acs_object_types set object_type_gif = 'default_object_type_gif'	where object_type = 'workflow_lite';





--------------------------------------------------------------
-- Definitions common to all DBs

\i ../common/intranet-biz-objects.sql




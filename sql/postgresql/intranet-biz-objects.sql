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
-- @author	  frank.bergmann@project-open.com

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
				references acs_objects
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
	select	aott.id_column into v_status_table_id_col from acs_object_type_tables aott
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
        object_id       alias for $1;
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
        object_id       alias for $1;
begin
	return "undefined for im_biz_object";
end;' language 'plpgsql';


-- Function to determine the type_id of a "im_biz_object".
-- It's a bit ugly to do this via SWITCH, but there aren't many
-- new "Biz Objects" to be added to the system...

create or replace function im_biz_object__type (integer)
returns integer as '
declare
        p_object_id             alias for $1;
        v_object_type           varchar;
        v_biz_object_type_id    integer;
begin

        -- get the object type
        select  object_type
        into    v_object_type
        from    acs_objects
        where   object_id = p_object_id;

        -- Initialize the return value
        v_biz_object_type_id = null;

        IF ''im_project'' = v_object_type THEN

                select  project_type_id
                into    v_biz_object_type_id
                from    im_projects
                where   project_id = p_object_id;

        ELSIF ''im_company'' = v_object_type THEN

                select  company_type_id
                into    v_biz_object_type_id
                from    im_companies
                where   company_id = p_object_id;

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
	percentage		numeric(8,2) default 100
);

select acs_rel_type__create_type (
   'im_biz_object_member',	-- relationship (object) name
   'Biz Object Relation',	-- pretty name
   'Biz Object Relations',	-- pretty plural
   'relationship',		-- supertype
   'im_biz_object_members',	-- table_name
   'rel_id',			-- id_column
   'im_biz_object_member',	-- package_name
   'acs_object',		-- object_type_one
   'member',			-- role_one
    0,				-- min_n_rels_one
    null,			-- max_n_rels_one
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
        p_object_id       alias for $1;
	p_user_id	  alias for $2;

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



--------------------------------------------------------------
-- Definitions common to all DBs

\i ../common/intranet-biz-objects.sql




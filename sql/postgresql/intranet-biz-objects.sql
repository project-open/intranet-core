-- /packages/intranet-core/sql/oracle/intranet-biz-objects.sql
--
-- Copyright (C) 1999-2004 Project/Open
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

-- Project/Open Business objects can be associated to 
-- users using a "role", which depends on the Busines
-- Object (OpenACS object type ) and the "Object Type" 
-- (this is a field common to all of these objects).


-- ------------------------------------------------------------
-- Project/Open Business Object
-- ------------------------------------------------------------

-- BizObjects have in a common "type()" method that allows
-- to select suitable roles for them in which to assign
-- members.

CREATE FUNCTION inline_0 ()
RETURNS integer AS '
begin
	PERFORM acs_object_type__create_type (
		''im_biz_object'',	-- object_type
		''Business Object'',	-- pretty_name
		''Business Objects'',	-- pretty_plural
		''acs_object'',		-- supertype
		''im_biz_objects'',	-- table_name
		''object_id'',		-- id_column
		''im_biz_object'',	-- package_name
		''f'',			-- abstract_p
		null,			-- type_extension_table
		''im_biz_object__name''	-- name_method
	);
	return 0;
end;' LANGUAGE 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();


CREATE TABLE im_biz_objects (
	object_id 		integer
				constraint im_biz_object_id_pk
				primary key
				constraint im_biz_object_id_fk
				references acs_objects
);


-- Store a "view" and an "edit" URLs for each object type.
CREATE TABLE im_biz_object_urls (
	object_type		varchar(1000)
				constraint im_biz_obj_urls_object_type_fk
				references acs_object_types,
	url_type		varchar(100)
				constraint im_biz_obj_urls_url_type_ck
				check(url_type in ('view', 'edit')),
	url			varchar(1000),
		constraint im_biz_obj_urls_pk
		primary key(object_type, url_type)
);

create or replace function im_biz_object__new (integer,varchar,timestamptz,integer,varchar,integer)
returns integer as '
declare
	object_id	alias for $1;
	object_type	alias for $2;
	creation_date	alias for $3;
	creation_user	alias for $4;
	creation_ip	alias for $5;
	context_id	alias for $6;

	v_object_id	integer;
begin
	v_object_id := acs_object__new (
		object_id,
		object_type,
		creation_date,
		creation_user,
		creation_ip,
		context_id
	);
	insert into im_biz_objects (object_id) values (v_object_id);
	return v_object_id;

end;' language 'plpgsql';

-- Delete a single object (if we know its ID...)
create or replace function im_biz_object__del (integer)
returns integer as '
declare
        object_id       alias for $1;
	v_object_id	integer;
begin
	-- Erase the im_biz_objects item associated with the id
	delete from 	im_biz_objects
	where		object_id = del.object_id;

	PERFORM acs_object.del(del.object_id);
end;' language 'plpgsql';

create or replace function im_biz_object__name (integer)
returns varchar as '
declare
        object_id       alias for $1;
begin
	return "undefined for im_biz_object";
end;' language 'plpgsql';



-- ------------------------------------------------------------
-- Roles for all Biz Objects
-- ------------------------------------------------------------

-- Project/Open Core only knows about Member and PM
-- Project/Translation adds Translator, Proof Reader, ...
-- Project/Advertizing adds Producer, Designer, Texter, ...
-- Project/IT adds Business Analyst, Architect, Developer, ...

-- ToDo: Insert category hierarchy to be able to ask:
-- Is this an "object administrator" or a "full member"?

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1300, 'Full Member', 'Intranet Biz Object Role', 
	'member', 'Full Member');

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1301, 'Project Manager', 'Intranet Biz Object Role', 
	'project-manager', 'Project Manager');

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1302, 'Key Account', 'Intranet Biz Object Role', 
	'key-account', 'Key Account Manager');

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1303, 'Office Manager', 'Intranet Biz Object Role', 
	'office-manager', 'Office Manager');

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
	acs_object_type	varchar
			constraint im_bizo_rmap_o_type_fk
			references acs_object_types,
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
	rel_id		integer
			constraint im_biz_object_members_rel_fk
			references acs_rels (rel_id)
			constraint im_biz_object_members_rel_pk
			primary key,
	object_role_id	integer not null
			constraint im_biz_object_members_role_fk
			references im_categories
			-- Intranet Project Role
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

create or replace function im_biz_object_member__new (
integer, varchar, integer, integer, integer, integer, varchar)
returns integer as '
DECLARE
	rel_id		alias for $1;
	rel_type	alias for $2;
	object_id	alias for $3;
	user_id		alias for $4;
	object_role_id	alias for $5;
	creation_user	alias for $6;
	creation_ip	alias for $7;

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel.new (
		rel_id,
		rel_type,	
		object_id,
		user_id,
		object_id,
		creation_user,
		creation_ip
	);

	insert into im_biz_object_members (
	       rel_id, object_role_id
	) values (
	       v_rel_id, new.object_role_id
	);

	return v_rel_id;
end;' language 'plpgsql';


create or replace function im_biz_object_member__del (integer)
returns integer as '
DECLARE
        object_id       alias for $1;
	v_rel_id	integer;
BEGIN
	select	rel_id
	into	v_rel_id
	from	acs_rels
	where	object_id_one = del.object_id
		and object_id_two = del.user_id;

	delete	from im_biz_object_members
	where	object_role_id = v_rel_id;

	PERFORM acs_rel.del(v_rel_id);
end;' language 'plpgsql';


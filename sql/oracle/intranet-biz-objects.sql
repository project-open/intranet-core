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

begin
    acs_object_type.create_type (
	supertype =>		'acs_object',
	object_type =>		'im_biz_object',
	pretty_name =>		'P/O Business Object',
	pretty_plural =>	'P/O Business Objects',
	table_name =>		'im_biz_objects',
	id_column =>		'object_id',
	package_name =>		'im_biz_object',
	type_extension_table =>	null,
	name_method =>		'im_biz_object.name'
    );
end;
/
show errors


CREATE TABLE im_biz_objects (
	object_id 		integer
				constraint im_biz_object_id_pk
				primary key
				constraint im_biz_object_id_fk
				references acs_objects
);


-- Store a "view" and an "edit" URLs for each object type.
--
-- fraber 041015: referential integrity to acs_object_types
-- removed because this would require to insert elements into
-- this table _after_ the objects have been created, which is
-- very error prone for DM creation.
--
CREATE TABLE im_biz_object_urls (
	object_type		varchar(1000),
	url_type		varchar(100)
				constraint im_biz_obj_urls_url_type_ck
				check(url_type in ('view', 'edit')),
	url			varchar(1000),
		constraint im_biz_obj_urls_pk
		primary key(object_type, url_type)
);


create or replace package im_biz_object
is
    function new (
	object_id	in integer,
	object_type	in varchar,
	creation_date	in date,
	creation_user	in integer,
	creation_ip	in varchar,
	context_id	in integer
    ) return im_biz_objects.object_id%TYPE;

    procedure del (object_id in integer);
    function name (object_id in integer) return varchar;
    function type (object_id in integer) return integer;
end im_biz_object;
/
show errors


create or replace package body im_biz_object
is
    function new (
	object_id	in integer,
	object_type	in varchar,
	creation_date	in date,
	creation_user	in integer,
	creation_ip	in varchar,
	context_id	in integer
    ) return im_biz_objects.object_id%TYPE
    is
	v_object_id	im_biz_objects.object_id%TYPE;
    begin
	v_object_id := acs_object.new (
		object_id =>		object_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);
	insert into im_biz_objects (object_id) values (v_object_id);
	return v_object_id;
    end new;


    -- Delete a single object (if we know its ID...)
    procedure del (object_id in integer)
    is
	v_object_id	integer;
    begin
	-- Erase the im_biz_objects item associated with the id
	delete from 	im_biz_objects
	where		object_id = del.object_id;

	acs_object.del(del.object_id);
    end del;

    function name (object_id in integer) return varchar
    is
    begin
	return 'abstract class error';
    end name;

    function type (object_id in integer) return integer
    is
    begin
	return -1;
    end type;

end im_biz_object;
/
show errors

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
	rel_id		constraint im_biz_object_members_rel_fk
			references acs_rels (rel_id)
			constraint im_biz_object_members_rel_pk
			primary key,
	object_role_id	integer not null
			constraint im_biz_object_members_role_fk
			references im_categories
			-- Intranet Project Role
);

-- BEGIN
--    acs_rel_type.create_role ('pm', 'Project Manager', 'Project Managers');
-- END;
-- /


BEGIN
	acs_rel_type.create_type (
		rel_type => 'im_biz_object_member',
		pretty_name => 'Biz Object Relation',
		pretty_plural => 'Biz Object Relations',
		table_name => 'im_biz_object_members',
		id_column => 'rel_id',
		package_name => 'im_biz_object_member',
		object_type_one => 'acs_object',
		min_n_rels_one => 0, 
		max_n_rels_one => null,
		object_type_two => 'person', 
		role_two => 'member',
		min_n_rels_two => 0, max_n_rels_two => null
	);
END;
/
commit;


-- ------------------------------------------------------------
-- Project Membership Packages
-- ------------------------------------------------------------

create or replace package im_biz_object_member
as
	function new (
		rel_id		in im_biz_object_members.rel_id%TYPE default null,
		rel_type	in acs_rels.rel_type%TYPE default 'im_biz_object_member',
		object_id	in integer,
		user_id		in integer,
		object_role_id	in integer,
		creation_user	in acs_objects.creation_user%TYPE default null,
		creation_ip	in acs_objects.creation_ip%TYPE default null
	) return im_biz_object_members.rel_id%TYPE;

	procedure del (
		object_id	in integer,
		user_id		in integer
	);
end im_biz_object_member;
/

create or replace package body im_biz_object_member
as

    function new (
	rel_id		in im_biz_object_members.rel_id%TYPE default null,
	rel_type	in acs_rels.rel_type%TYPE default 'im_biz_object_member',
	object_id	in integer,
	user_id		in integer,
	object_role_id	in integer,
	creation_user	in acs_objects.creation_user%TYPE default null,
	creation_ip	in acs_objects.creation_ip%TYPE default null
    ) return im_biz_object_members.rel_id%TYPE
    is
	v_rel_id integer;
    begin
	v_rel_id := acs_rel.new (
		rel_id		=> rel_id,
		rel_type	=> rel_type,
		object_id_one	=> object_id,
		object_id_two	=> user_id,
		context_id	=> object_id,
		creation_user	=> creation_user,
		creation_ip	=> creation_ip
	);

	insert into im_biz_object_members
	(rel_id, object_role_id)
	values
	(v_rel_id, new.object_role_id);

	return v_rel_id;
  end;

  procedure del (
	object_id	in integer,
	user_id		in integer
  )
  is
	v_rel_id	integer;
  begin
	select rel_id
	into v_rel_id
	from acs_rels
	where	object_id_one = del.object_id
		and object_id_two = del.user_id;

	delete
	from im_biz_object_members
	where object_role_id = v_rel_id;

	acs_rel.del(v_rel_id);
  end;

end im_biz_object_member;
/
show errors


--------------------------------------------------------------
-- Categories, views etc. common to all databases


@../common/intranet-biz-objects.sql

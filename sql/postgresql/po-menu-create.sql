-- /packages/intranet-core/sql/postgres/intranet-menu-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

---------------------------------------------------------
-- Menus
--
-- Dynamic Menus are necessary to allow Project/Open modules
-- to extend the po-core at some point in the future, without
-- that po-core would know about these extensions right now.

CREATE FUNCTION inline_0 ()
RETURNS integer AS '
begin
	PERFORM acs_object_type__create_type (
	''po_menu'',		-- object_type
 	''Menu'',		-- pretty_name
	''Menus'',		-- pretty_plural
	''group'',		-- supertype
	''po_menus'',		-- table_name
	''menu_id'',		-- id_column
	null,			-- package_name
	''f'',			-- abstract_p
	null,			-- type_extension_table
	null			-- name_method
	);
	return 0;
end;' LANGUAGE 'plpgsql';

SELECT inline_0 ();

DROP FUNCTION inline_0 ();


-- Each po_menu has the super_type of "group"
-- which corresponds to its "administrative group" (members
-- and admins of this group have read/write rights on the
-- biz object).

CREATE TABLE po_menus (
	menu_id 		integer
				constraint po_menu_id_pk
				primary key
				constraint po_menu_id_fk
				references acs_objects,
	name			varchar(200),
	url			varchar(200),
	sort_order		integer,
	parent_menu_id		integer
				constraint po_parent_menu_id_fk
				references po_menus
);

CREATE FUNCTION po_menu__new (
	integer,varchar,timestamptz,integer,varchar,integer,
	varchar,varchar,integer,integer
)
RETURNS integer AS '
declare
	p_menu_id		alias for $1;	-- default null
	p_object_type		alias for $2;
	p_creation_date		alias for $3;	-- default now()
	p_creation_user		alias for $4;	-- default null
	p_creation_ip		alias for $5;	-- default null
	p_context_id		alias for $6;
	
	p_name			alias for $7;
	p_url			alias for $8;
	p_sort_order		alias for $9;
	p_parent_menu_id	alias for $10;

	v_menu_id		po_menus.menu_id%TYPE;
begin
	v_menu_id := acs_object__new (
		p_menu_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into po_menus (
		menu_id, name, url, sort_order, parent_menu_id
	) values (
		v_menu_id, p_name, p_url, p_sort_order, p_parent_menu_id
	);

	return v_menu_id;

end;' LANGUAGE 'plpgsql';


CREATE FUNCTION po_menu__delete (
	integer
)
RETURNS integer AS '
declare
	p_menu_id		alias for $1;
begin
	-- Erase the po_menus item associated with the id
	delete from 	po_menus
	where		menu_id = p_menu_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = p_menu_id;

	PERFORM acs_object__delete(p_menu_id);

	return 0;

end;' LANGUAGE 'plpgsql';


-- function to return the name of the po_menus item
CREATE FUNCTION po_menu__name (
	integer
)
RETURNS varchar AS '
declare
	p_menu_id	alias for $1;
	v_name		varchar;
begin
	select	name
	into	v_name
	from	po_menus
	where	menu_id = p_menu_id;

	return v_name;

end;' LANGUAGE 'plpgsql';



CREATE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_menu		integer;
	v_companies	integer;
begin
	-- Top Level Menu

	select po_menu__new (
		null,''po_menu'',now(),0,null,null,
		''Projects'',''/po-core/projects/'',1,null
	) into v_menu;

	select po_menu__new (
		null,''po_menu'',now(),0,null,null,
		''Admin'',''/admin/'',2,null
	) into v_menu;

	select po_menu__new (
		null,''po_menu'',now(),0,null,null,
		''Companies'',''/po-core/companies/'',3,null
	) into v_companies;

	select po_menu__new (
		null,''po_menu'',now(),0,null,null,
		''Invoices'',''/po-invoicing/invoices/'',4,null
	) into v_menu;


	-- Companies Submenu
	select po_menu__new (
		null,''po_menu'',now(),0,null,null,
		''Companies'',''/po-core/companies/index?'',1,v_companies
	) into v_menu;

	select po_menu__new (
		null,''po_menu'',now(),0,null,null,
		''Providers'',''/po-core/companies/index?'',2,v_companies
	) into v_menu;

	select po_menu__new (
		null,''po_menu'',now(),0,null,null,
		''Partners'',''/po-core/companies/index?'',3,v_companies
	) into v_menu;

        return 0;
end;' LANGUAGE 'plpgsql';

SELECT inline_0 ();

DROP FUNCTION inline_0 ();



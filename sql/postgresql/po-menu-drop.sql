-- /po-core/sql/postgres/po-menu-drop.sql
--
-- Project/Open Core, fraber@fraber.de, 030828
--

DROP TABLE po_menus;

delete from acs_objects where object_type='po_menu';


DROP FUNCTION po_menu__new (
	integer,varchar,timestamptz,integer,varchar,integer,
	varchar,varchar,integer,integer
);


DROP FUNCTION po_menu__delete (
	integer
);

DROP FUNCTION po_menu__name (
	integer
);

-- drop the object_type
delete from acs_object_types where object_type='po_menu';

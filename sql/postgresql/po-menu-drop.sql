-- /packages/intranet-core/sql/postgres/intranet-core-drop.sql
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
-- @author      frank.bergmann@project-open.com

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

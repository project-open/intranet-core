-- /packages/intranet-core/sql/oracle/intranet-views.sql
--
-- Copyright (C) 2004 Project/Open
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
-- @author	guillermo.belcic@project-open.com
-- @author	frank.bergmann@project-open.com


---------------------------------------------------------
-- Views
--
-- Views are a kind of meta-data that determine how a user
-- can see business objects.
-- Every view has:
--	1. Filters - Determine what objects to see
--	2. Columns - Determine how to render columns.
--

create sequence im_views_seq start with 1000;
create table im_views (
	view_id			integer 
				constraint im_views_pk
				primary key,
	view_name		varchar(100) 
				constraint im_views_name_un
				not null unique,
	view_type_id		integer
				constraint im_views_type_fk
				references im_categories,
	view_status_id		integer
				constraint im_views_status_fk
				references im_categories,
	visible_for		varchar(1000),
	view_sql		varchar(4000),
				-- order for restore
	sort_order		integer
);

create sequence im_view_columns_seq start with 1000;
create table im_view_columns (
	column_id		integer 
				constraint im_view_columns_pk
				primary key,
	view_id			integer not null 
				constraint im_view_view_id_fk
				references im_views,
	-- group_id=NULL identifies the default view.
	-- however, there may be customized views for a specific group
	group_id		integer
				constraint im_view_columns_group_id_fk
				references groups,
	column_name		varchar(100) not null,
	-- tcl command being executed using "eval" for rendering the column
	column_render_tcl	varchar(4000),
	-- extra SQL components necessary in order to display this
	-- column. All entries without "," or "and".
	extra_select		varchar(4000),
	extra_from		varchar(4000),
	extra_where		varchar(4000),
	-- where to display the column?
	sort_order		integer not null,
	-- how to order the SQL when the "Column Name" is selected?
	order_by_clause		varchar(4000),
	-- set of permission tokens that allow viewing this column,
	-- separated with spaces and OR-joined
	visible_for		varchar(1000)
);

---------------------------------------------------------
-- Import view definition common to all DBs

@../common/intranet-views.sql
@../common/intranet-core-backup.sql


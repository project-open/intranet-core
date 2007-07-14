-- /packages/intranet-core/sql/postgres/intranet-categories.sql
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
-- @author	unknown@arsdigita.com
-- @author	frank.bergmann@project-open.com


-------------------------------------------------------------
-- Categories
--
-- we use categories as a universal storage for business
-- object states and types, instead of a zillion of 
-- tables like 'im_project_status' and 'im_project_type'.

create sequence im_categories_seq start 100000;
create table im_categories (
	category_id		integer 
				constraint im_categories_pk
				primary key,
	category		varchar(50) not null,
	category_description	varchar(4000),
	category_type		varchar(50),
	category_gif		varchar(100) default 'category',
	enabled_p		char(1) default 't'
				constraint im_enabled_p_ck
				check(enabled_p in ('t','f')),
                                -- used to indicate "abstract" super-categorys
                                -- that are not valid values for objects.
                                -- For example: "Translation Project" is not a
                                -- project_type, but a class of project_types.
	parent_only_p		char(1) default 'f'
				constraint im_parent_only_p_ck
				check(parent_only_p in ('t','f')),
	sort_order		integer default 0
);

-- fraber 040320: Don't allow for duplicated entries!
create unique index im_categories_cat_cat_type_idx on im_categories(category, category_type);


-- optional system to put categories in a hierarchy.
-- This table stores the "transitive closure" of the
-- is-a relationship between categories in a kind of matrix.
-- Let's asume: B isa A and C isa B. So we'll store
-- the tupels (C,A), (C,B) and (B,A).
--
-- This structure is a very fast structure for asking:
--
--	"is category A a subcategory of B?"
--
-- but requires n^2 storage space in the worst case and
-- it's a mess retracting settings from the hierarchy.
-- We won't have very deep hierarchies, so storage complexity
-- is not going to be a problem.

create table im_category_hierarchy (
	parent_id		integer
				constraint im_parent_category_fk
				references im_categories,
	child_id		integer
				constraint im_child_category_fk
				references im_categories,
				constraint category_hierarchy_un 
				unique (parent_id, child_id)
);
create index im_cat_hierarchy_parent_id_idx on im_category_hierarchy(parent_id);
create index im_cat_hierarchy_child_id_idx on im_category_hierarchy(child_id);


-- Some helper functions to make our queries easier to read
create or replace function im_category_from_id (integer)
returns varchar as '
DECLARE
	p_category_id	alias for $1;
	v_category	varchar(50);
BEGIN
	select category
	into v_category
	from im_categories
	where category_id = p_category_id;

	return v_category;
end;' language 'plpgsql';


-------------------------------------------------------------
-- Helper function/view to return all sub-categories of a main category
-------------------------------------------------------------


create or replace function im_sub_categories (
	integer
) returns setof integer as '
declare
	p_cat			alias for $1;
	v_cat			integer;
	row			RECORD;
BEGIN
	FOR row IN
		select  child_id
		from    im_category_hierarchy
		where   parent_id = p_cat
		UNION
		select  p_cat
	LOOP
	    RETURN NEXT row.child_id;
	END LOOP;

	RETURN;
end;' language 'plpgsql';

-- Test query
-- select * from im_sub_categories(81);





-------------------------------------------------------------
-- Import category definitions common to all DBs

\i ../common/intranet-categories.sql



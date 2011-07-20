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


-- Create a fake object type for categories
-- We willl need this for the REST interface etc.
select acs_object_type__create_type (
	'im_category',		-- object_type
	'PO Category',		-- pretty_name
	'PO Categories',	-- pretty_plural
	'acs_object',		-- supertype
	'im_categories',	-- table_name
	'category_id',		-- id_column
	'intranet-core',	-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_category_from_id'	-- name_method
);



-- Reserve the first 10000000 category IDs as constants for the system.
create sequence im_categories_seq start 10000000;


create table im_categories (
	category_id		integer 
				constraint im_categories_pk
				primary key,
	category		varchar(50) not null,
	category_description	text,
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
	sort_order		integer default 0,
	aux_int1		integer,
	aux_int2		integer,
	aux_string1		text,
	aux_string2		text
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
		select	child_id
		from	im_category_hierarchy
		where	parent_id = p_cat
	    UNION
		select	p_cat
	LOOP
		RETURN NEXT row.child_id;
	END LOOP;

	RETURN;
end;' language 'plpgsql';

-- Test query
-- select * from im_sub_categories(81);



create or replace function im_category_parents (
	integer
) returns setof integer as $body$
declare
	p_cat			alias for $1;
	v_cat			integer;
	row			RECORD;
BEGIN
	FOR row IN
		select	c.category_id
		from	im_categories c,
			im_category_hierarchy h
		where	c.category_id = h.parent_id and
			h.child_id = p_cat and
			(c.enabled_p = 't' OR c.enabled_p is NULL)
	LOOP
		RETURN NEXT row.category_id;
	END LOOP;

	RETURN;
end;$body$ language 'plpgsql';


-- Select out the lowest parent of the category.
-- This makes sense as a fast approximation, but 
-- isn't correct. 
-- ToDo: Pull out the real top-level parent
--
create or replace function im_category_min_parent (
	integer
) returns integer as $body$
declare
	p_cat			alias for $1;
	v_cat			integer;
BEGIN
	select	min(c.category_id) into v_cat
	from	im_categories c,
		im_category_hierarchy h
	where	c.category_id = h.parent_id and
		h.child_id = p_cat and
		(c.enabled_p = 't' OR c.enabled_p is NULL);

	RETURN v_cat;
end;$body$ language 'plpgsql';


-- Test query
select * from im_category_parents(81);



create or replace function im_category_path_to_category (integer)
returns varchar as $body$
BEGIN
	RETURN im_category_path_to_category($1,0);
END;
$body$ language 'plpgsql';


create or replace function im_category_path_to_category (integer, integer)
returns varchar as $body$
declare
	p_cat_id		alias for $1;
	p_loop			alias for $2;
	v_cat			varchar;
	v_path			varchar;
	v_longest_path		varchar;
	row			RECORD;
BEGIN
	-- Avoid infinite loops...
	IF p_loop > 5 THEN return ''; END IF;

	-- Add leading zeros until code has 8 digits.
	-- This way all category codes have the same length.
	v_cat := p_cat_id;
	WHILE length(v_cat) < 8 LOOP v_cat := '0'||v_cat; END LOOP;

	-- Look out for the parent with the longest path
	v_longest_path := '';
	FOR row IN
		-- Get all (enabled) parents
		select	ch.parent_id
		from	im_category_hierarchy ch,
			im_categories c
		where	ch.child_id = p_cat_id and
			ch.parent_id = c.category_id and
			ch.parent_id != p_cat_id and
			(c.enabled_p is null or c.enabled_p = 't')
	LOOP
		v_path = im_category_path_to_category(row.parent_id, p_loop+1);
		IF v_longest_path = '' THEN v_longest_path := v_path; END IF;
		IF length(v_path) > length(v_longest_path) THEN v_longest_path := v_path; END IF;
	END LOOP;

	RETURN v_longest_path || v_cat;
end;$body$ language 'plpgsql';

-- Test query
select im_category_path_to_category (83);





-------------------------------------------------------------
-- Insert a category for upgrade scripts - gracefully
-------------------------------------------------------------


CREATE OR REPLACE FUNCTION im_category_new (
	integer, varchar, varchar, varchar
) RETURNS integer as '
DECLARE
	p_category_id		alias for $1;
	p_category		alias for $2;
	p_category_type		alias for $3;
	p_description		alias for $4;

	v_count			integer;
BEGIN
	select	count(*) into v_count from im_categories
	where	(category = p_category and category_type = p_category_type) OR
		category_id = p_category_id;
	IF v_count > 0 THEN return 0; END IF;

	insert into im_categories(category_id, category, category_type, category_description)
	values (p_category_id, p_category, p_category_type, p_description);

	RETURN 0;
end;' language 'plpgsql';

CREATE OR REPLACE FUNCTION im_category_new (
	integer, varchar, varchar
) RETURNS integer as '
DECLARE
	p_category_id		alias for $1;
	p_category		alias for $2;
	p_category_type		alias for $3;
BEGIN
	RETURN im_category_new(p_category_id, p_category, p_category_type, NULL);
end;' language 'plpgsql';


-- Compatibility for Malte
-- ToDo: Remove
CREATE OR REPLACE FUNCTION im_category__new (
        integer, varchar, varchar, varchar
) RETURNS integer as '
DECLARE
        p_category_id           alias for $1;
        p_category              alias for $2;
        p_category_type         alias for $3;
        p_description           alias for $4;
BEGIN
        RETURN im_category_new(p_category_id, p_category, p_category_type, p_description);
end;' language 'plpgsql';


CREATE OR REPLACE FUNCTION im_category_hierarchy_new (
	integer, integer
) RETURNS integer as '
DECLARE
	p_child_id		alias for $1;
	p_parent_id		alias for $2;

	row			RECORD;
	v_count			integer;
BEGIN
	IF p_child_id is null THEN 
		RAISE NOTICE ''im_category_hierarchy_new: bad category 1: "%" '',p_child_id;
		return 0;
	END IF;

	IF p_parent_id is null THEN 
		RAISE NOTICE ''im_category_hierarchy_new: bad category 2: "%" '',p_parent_id; 
		return 0;
	END IF;
	IF p_child_id = p_parent_id THEN return 0; END IF;

	select	count(*) into v_count from im_category_hierarchy
	where	child_id = p_child_id and parent_id = p_parent_id;
	IF v_count = 0 THEN
		insert into im_category_hierarchy(child_id, parent_id)
		values (p_child_id, p_parent_id);
	END IF;

	-- Loop through the parents of the parent
	FOR row IN
		select	parent_id
		from	im_category_hierarchy
		where	child_id = p_parent_id
	LOOP
		PERFORM im_category_hierarchy_new (p_child_id, row.parent_id);
	END LOOP;

	RETURN 0;
end;' language 'plpgsql';


CREATE OR REPLACE FUNCTION im_category_hierarchy_new (
	varchar, varchar, varchar
) RETURNS integer as '
DECLARE
	p_child			alias for $1;
	p_parent		alias for $2;
	p_cat_type		alias for $3;

	v_child_id		integer;
	v_parent_id		integer;
BEGIN
	select	category_id into v_child_id from im_categories
	where	category = p_child and category_type = p_cat_type;
	IF v_child_id is null THEN 
		RAISE NOTICE ''im_category_hierarchy_new: bad category 1: "%" '',p_child; 
		return 0;
	END IF;

	select	category_id into v_parent_id from im_categories
	where	category = p_parent and category_type = p_cat_type;
	IF v_parent_id is null THEN 
		RAISE NOTICE ''im_category_hierarchy_new: bad category 2: "%" '',p_parent; 
		return 0;
	END IF;

	return im_category_hierarchy_new (v_child_id, v_parent_id);

	RETURN 0;
end;' language 'plpgsql';




-------------------------------------------------------------
-- Import category definitions common to all DBs

\i ../common/intranet-categories.sql



-- /www/doc/sql/intranet.sql
--
-- Project/Open Core Module, fraber@fraber.de, 030828
-- A complete revision of June 1999 by dvr@arsdigita.com
--

-------------------------------------------------------------
-- Country Codes
--

create table country_codes (
	country_code		char(2) 
				constraint po_country_code_pk
				primary key,
	country_name		varchar(50),
	enabled_p		char(1) default 't'
				constraint po_co_co_enabled_p_ck
				check(enabled_p in ('t','f'))
);


-------------------------------------------------------------
-- Currentcy Codes
--

create table currency_codes (
	currency_code		char(3)
				constraint po_currency_code_pk
				primary key,
	currency_name		varchar(50),
	enabled_p		char(1) default 't'
				constraint po_cu_co_enabled_p
				check(enabled_p in ('t','f'))
);



-------------------------------------------------------------
-- Categories
--
-- we use these for categorizing content, registering user interest
-- in particular areas, organizing archived Q&A threads
-- we also may use this as a mailing list to keep users up
-- to date with what goes on at the site

create sequence po_categories_seq start 1;
create table po_categories (
	category_id		integer not null
				constraint po_category_pk
				primary key,
	category		varchar(50) not null,
	category_description	varchar(4000),
	-- optional value for custom use
	category_value		varchar(4000),
	category_type		varchar(50),
	super_category		integer
				constraint po_super_category_fk
				references po_categories,
	-- language probably would weight higher than activity
	profiling_weight	integer default 1
				constraint po_profiling_weight_ck
				check(profiling_weight >= 0),
	enabled_p		char(1) default 'f'
				constraint po_enabled_p_ck
				check(enabled_p in ('t','f'))
);

-- optional system to put po_categories in a hierarchy
-- (see /doc/user-profiling.html)
-- we use a UNIQUE constraint instead of PRIMARY key
-- because we use rows with NULL parent_category_id to
-- signify the top-level po_categories

create table po_category_hierarchy (
	parent_category_id	integer
				constraint po_parent_category_fk
				references po_categories,
	child_category_id	integer
				constraint po_child_category_fk
				references po_categories,
	unique (parent_category_id, child_category_id)
);



create function po_category_from_id (integer)
returns varchar as '
declare
  p_category_id		alias for $1;
  v_category		varchar;
begin
    select category
    from po_categories
    into v_category
    where category_id = p_category_id;

    return v_category;

end;' language 'plpgsql';



-- function permission_p
create function po_permission_p (integer,integer,varchar)
returns boolean as '
declare
  object_id	alias for $1;
  party_id	alias for $2;
  privilege	alias for $3;
begin

    return acs_permission__permission_p (object_id, party_id, privilege);

end;' language 'plpgsql';




-------------------------------------------------------------
-- Offices
--
-- Denotes physical locations with an address held by a company.
--


CREATE FUNCTION inline_0 ()
RETURNS integer AS '
begin
	PERFORM acs_object_type__create_type (
	''po_office'',		-- object_type
 	''Office'',		-- pretty_name
	''Offices'',		-- pretty_plural
	''group'',		-- supertype
	''po_offices'',		-- table_name
	''office_id'',		-- id_column
	null,			-- package_name
	''f'',			-- abstract_p
	null,			-- type_extension_table
	null			-- name_method
	);
	return 0;
end;' LANGUAGE 'plpgsql';

SELECT inline_0 ();

DROP FUNCTION inline_0 ();


create table po_offices (
	office_id		integer
				constraint po_office_pk
				primary key
				constraint po_office_pk_fk
				references acs_objects,
	-- standard P/O business objects fields
	name			varchar(200),
				constraint po_office_name_un 
				unique (name),
	short_name		varchar(100),
				constraint po_office_short_name_un 
				unique (short_name),
	admin_group_id		integer
				constraint po_office_admin_group_fk 
				references groups,
	status_id		integer
				constraint po_office_status_fk
				references po_categories,
	type_id			integer
				constraint po_office_type_fk
				references po_categories,
	note			varchar(4000),
	-- object specific fields
	phone			varchar(50),
	fax			varchar(50),
	address_line1		varchar(80),
	address_line2		varchar(80),
	address_city		varchar(80),
	address_state		varchar(80),
	address_postal_code	varchar(80),
	address_country_code	char(2)
				constraint po_address_country_code_fk
				references country_codes(country_code),
	contact_person_id	integer
				constraint po_contact_person_fk
				references parties
);


-- views on intranet po_categories to make queries cleaner

create view po_project_status as
select category_id as project_status_id, category as project_status
from po_categories
where category_type = 'Project Status';

create view po_project_types as
select category_id as project_type_id, category as project_type
from po_categories
where category_type = 'Project Type';

create view po_company_status as
select category_id as company_status_id, category as company_status
from po_categories
where category_type = 'Company Status';

create view po_company_types as
select category_id as company_type_id, category as company_type
from po_categories
where category_type = 'Company Type';

create view po_annual_revenue as
select category_id as revenue_id, category as revenue
from po_categories
where category_type = 'Annual Revenue';



\i po-company-create.sql
\i po-project-create.sql
\i po-core-categories.sql
\i po-core-dynviews.sql

\i po-menu-create.sql


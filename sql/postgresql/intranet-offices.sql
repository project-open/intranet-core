-- /packages/intranet/sql/postgres/intranet-offices.sql
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
-- @author      unknown@arsdigita.com
-- @author      frank.bergmann@project-open.com


--------------------------------------------------------------
-- Offices
--
-- An office is a physical place belonging to the company itself
-- or to a company.
--

select acs_object_type__create_type (
	'im_office',		-- object_type
	'Office',		-- pretty_name
	'Offices',		-- pretty_plural
	'im_biz_object',	-- supertype
	'im_offices',		-- table_name
	'office_id',		-- id_column
	'im_office',		-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_office__name'	-- name_method
);


create table im_offices (
	office_id		integer 
				constraint im_offices_office_id_pk 
				primary key
				constraint im_offices_office_id_fk 
				references acs_objects,
	office_name		varchar(1000) not null
				constraint im_offices_name_un unique,
	office_path		varchar(100) not null
				constraint im_offices_path_un unique,
	office_status_id	integer not null
				constraint im_offices_cust_stat_fk
				references im_categories,
	office_type_id		integer not null
				constraint im_offices_cust_type_fk
				references im_categories,
				-- "pointer" back to the company of the office
				-- no foreign key to companies yet - we still
				-- need to define the table ..
	company_id		integer,
				-- is this office and contact information public?
	public_p		char(1) default 'f'
				constraint im_offices_public_p_ck 
				check(public_p in ('t','f')),
	phone			varchar(50),
	fax			varchar(50),
	address_line1		varchar(80),
	address_line2		varchar(80),
	address_city		varchar(80),
	address_state		varchar(80),
	address_postal_code	varchar(80),
	address_country_code	char(2) 
				constraint if_address_country_code_fk 
				references country_codes(iso),
	contact_person_id	integer 
				constraint im_offices_cont_per_fk
				references users,
	landlord		varchar(4000),
	--- who supplies the security service, the code for
	--- the door, etc.
	security		varchar(4000),
	note			varchar(4000)
);


create or replace function im_office__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer
) returns integer as '
declare
        p_office_id     alias for $1;
        p_object_type     alias for $2;
        p_creation_date   alias for $3;
        p_creation_user   alias for $4;
        p_creation_ip     alias for $5;
        p_context_id      alias for $6;

	p_office_name	alias for $7;
	p_office_path	alias for $8;
	p_office_type_id  alias for $9;
	p_office_status_id alias for $10;
	p_company_id	alias for $11;

        v_object_id     integer;
begin
	v_object_id := acs_object__new (
		p_office_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);
	insert into im_offices (
		office_id, office_name, office_path, 
		office_type_id, office_status_id, company_id
	) values (
		v_object_id, p_office_name, p_office_path, 
		p_office_type_id, p_office_status_id, p_company_id
	);
	return v_object_id;
end;' language 'plpgsql';

-- Delete a single office (if we know its ID...)
create or replace function im_office__del (integer) returns integer as '
DECLARE
	v_office_id		alias for $1;
BEGIN
	-- Erase the im_offices item associated with the id
	delete from im_offices
	where office_id = v_office_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_office_id;

	acs_object.del(v_office_id);
end;' language 'plpgsql';

create or replace function im_office__name (integer) returns varchar as '
DECLARE
	v_name	im_offices.office_name%TYPE;
BEGIN
	select	office_name
	into	v_name
	from	im_offices
	where	office_id = name.office_id;

	return v_name;
end;' language 'plpgsql';


-- Setup the list of roles that a user can take with
-- respect to a office:
--	Full Member (1300) and
--	Office Manager (1303)
--
insert into im_biz_object_role_map values ('im_office',85,1300);
insert into im_biz_object_role_map values ('im_office',85,1303);



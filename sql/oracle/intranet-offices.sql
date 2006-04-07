-- /packages/intranet/sql/oracle/intranet-offices.sql
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

begin
    acs_object_type.create_type (
	supertype =>		'im_biz_object',
	object_type =>		'im_office',
	pretty_name =>		'Office',
	pretty_plural =>	'Offices',
	table_name =>		'im_offices',
	id_column =>		'office_id',
	package_name =>		'im_office',
	type_extension_table =>	null,
	name_method =>		'im_office.name'
    );
end;
/
show errors


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



create or replace package im_office
is
    function new (
	office_id	in integer default null,
	object_type	in varchar default 'im_office',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	office_name	in varchar,
	office_path	in varchar,
	-- Main Office office type
	office_type_id in  integer default 170,
	-- "Active" office status
	office_status_id in integer default 160,
	company_id	in integer default null
    ) return integer;

    procedure del (office_id in integer);
    function name (office_id in integer) return varchar;
    function type (office_id in integer) return integer;
end im_office;
/
show errors


create or replace package body im_office
is
    function new (
	office_id	in integer default null,
	object_type	in varchar,
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	office_name	in varchar,
	office_path	in varchar,
	-- Main Office office type
	office_type_id in  integer default 170,
	-- "Active" office status
	office_status_id in integer default 160,
	company_id	in integer default null
    ) return integer
    is
	v_office_id		integer;
    begin

	v_office_id := acs_object.new (
		object_id =>		office_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	insert into im_offices (
		office_id, office_name, office_path, 
		office_type_id, office_status_id, company_id
	) values (
		v_office_id, office_name, office_path, 
		office_type_id, office_status_id, company_id
	);
	return v_office_id;
    end new;


    -- Delete a single office (if we know its ID...)
    procedure del (office_id in integer)
    is
	v_office_id		integer;
    begin
	-- copy the variable to desambiguate the var name
	v_office_id := office_id;

	-- Erase the im_offices item associated with the id
	delete from im_offices
	where office_id = v_office_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_office_id;
	acs_object.del(v_office_id);
    end del;

    function name (office_id in integer) return varchar
    is
	v_name	im_offices.office_name%TYPE;
    begin
	select	office_name
	into	v_name
	from	im_offices
	where	office_id = name.office_id;

	return v_name;
    end name;

    function type (office_id in integer) return integer
    is
	v_type_id	integer;
    begin
	select	office_type_id
	into	v_type_id
	from	im_offices
	where	office_id = type.office_id;

	return v_type_id;
    end type;

end im_office;
/
show errors


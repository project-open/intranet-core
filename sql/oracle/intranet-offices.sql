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
-- or to a customer.
--

begin
    acs_object_type.create_type (
	supertype =>		'acs_object',
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
				-- avoid using the OpenACS permission system
				-- because we have to ask frequently:
				-- "Who has read permissions on this object".
	admin_group_id		integer not null
				constraint im_offices_admin_group_fk
				references groups,
	office_name		varchar(1000) not null
				constraint im_offices_name_un unique,
	office_path		varchar(100) not null
				constraint im_offices_path_un unique,
	office_status_id	integer not null
				constraint im_offices_cust_stat_fk
				references categories,
	office_type_id		integer not null
				constraint im_offices_cust_type_fk
				references categories,
				-- "pointer" back to the company of the office
				-- no foreign key to customers yet - we still
				-- need to define the table ..
	customer_id		integer,
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
	customer_id	in integer default null
    ) return integer;

    procedure del (office_id in integer);
    procedure name (office_id in integer);
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
	customer_id	in integer default null
    ) return integer
    is
	v_office_id		integer;
	v_admin_group_id	integer;
    begin

	v_office_id := acs_object.new (
		object_id =>		office_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	v_admin_group_id := acs_group.new(
		group_name => office_name
	);

	insert into im_offices (
		office_id, admin_group_id, office_name, office_path, 
		office_type_id, office_status_id, customer_id
	) values (
		v_office_id, v_admin_group_id, office_name, office_path, 
		office_type_id, office_status_id, customer_id
	);
	return v_office_id;
    end new;


    -- Delete a single office (if we know its ID...)
    procedure del (office_id in integer)
    is
	v_office_id		integer;
	v_admin_group_id	integer;
    begin
	-- copy the variable to desambiguate the var name
	v_office_id := office_id;

	-- determine the admin group
	select admin_group_id
	into v_admin_group_id
	from im_offices
	where office_id = v_office_id;

	-- Erase the im_offices item associated with the id
	delete from im_offices
	where office_id = v_office_id;

	-- now: delete the administration group
	acs_group.del(v_admin_group_id);

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_office_id;
	acs_object.del(v_office_id);
    end del;

    procedure name (office_id in integer)
    is
	v_name	im_offices.office_name%TYPE;
    begin
	select	office_name
	into	v_name
	from	im_offices
	where	office_id = office_id;
    end name;
end im_office;
/
show errors


-- Create the "Main Office" office, representing the company itself
declare
    v_office_id	integer;
begin
    v_office_id := im_office.new(
	object_type	=> 'im_office',
	office_name	=> 'Project/Open Main Office',
	office_path	=> 'po_main_office'
    );
end;
/
show errors;

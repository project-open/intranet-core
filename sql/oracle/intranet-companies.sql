-- /packages/intranet/sql/intranet-core-create.sql
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


---------------------------------------------------------
-- Companies
--
-- We store simple information about a company.
-- All contact information goes in the associated
-- offices.
--


begin
    acs_object_type.create_type (
	supertype =>		'im_biz_object',
	object_type =>		'im_company',
	pretty_name =>		'Company',
	pretty_plural =>	'Companies',
	table_name =>		'im_companies',
	id_column =>		'company_id',
	package_name =>		'im_company',
	type_extension_table =>	null,
	name_method =>		'im_company.name'
    );
end;
/
show errors


create table im_companies (
	company_id 		integer
				constraint im_companies_pk
				primary key 
				constraint im_companies_cust_id_fk
				references acs_objects,
	company_name		varchar(1000) not null
				constraint im_companies_name_un unique,
				-- where are the files in the filesystem?
	company_path		varchar(100) not null
				constraint im_companies_path_un unique,
	main_office_id		integer not null
				constraint im_companies_office_fk
				references im_offices,
	deleted_p		char(1) default('f')
				constraint im_companies_deleted_p 
				check(deleted_p in ('t','f')),
	company_status_id	integer not null
				constraint im_companies_cust_stat_fk
				references im_categories,
	company_type_id	integer not null
				constraint im_companies_cust_type_fk
				references im_categories,
	crm_status_id		integer 
				constraint im_companies_crm_status_fk
				references im_categories,
	primary_contact_id	integer 
				constraint im_companies_prim_cont_fk
				references users,
	accounting_contact_id	integer 
				constraint im_companies_acc_cont_fk
				references users,
	note			varchar(4000),
	referral_source		varchar(1000),
	annual_revenue_id	integer 
				constraint im_companies_ann_rev_fk
				references im_categories,
				-- keep track of when status is changed
	status_modification_date date,
				-- and what the old status was
	old_company_status_id	integer 
				constraint im_companies_old_cust_stat_fk
				references im_categories,
				-- is this a company we can bill?
	billable_p		char(1) default('f')
				constraint im_companies_billable_p_ck 
				check(billable_p in ('t','f')),
				-- What kind of site does the company want?
	site_concept		varchar(100),
				-- Who in Client Services is the manager?
	manager_id		integer 
				constraint im_companies_manager_fk
				references users,
				-- How much do they pay us?
	contract_value		integer,
				-- When does the company start?
	start_date		date,
	vat_number		varchar(100)
);



create or replace package im_company
is
    function new (
	company_id	in integer default null,
	object_type	in varchar default 'im_company',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	company_name	in varchar,
	company_path	in varchar,
	main_office_id	in integer,
	company_type_id in  integer default 51,
	company_status_id in integer default 46
    ) return integer;

    procedure del (company_id in integer);
    function name (company_id in integer) return varchar;
    function type (company_id in integer) return integer;
end im_company;
/
show errors


create or replace package body im_company
is

    function new (
	company_id	in integer default null,
	object_type	in varchar,
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	company_name	in varchar,
	company_path	in varchar,
	main_office_id	in integer,
	company_type_id in  integer default 51,
	company_status_id in integer default 46
    ) return integer
    is
	v_company_id		integer;
    begin
	v_company_id := acs_object.new (
		object_id =>		company_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	insert into im_companies (
		company_id, company_name, company_path, 
		company_type_id, company_status_id, main_office_id
	) values (
		v_company_id, company_name, company_path, 
		company_type_id, company_status_id, main_office_id
	);

	-- Set the link back from the office to the company
	update im_offices
	set company_id = v_company_id
	where office_id = main_office_id;

	return v_company_id;
    end new;


    -- Delete a single company (if we know its ID...)
    procedure del (company_id in integer)
    is
	v_company_id		integer;
    begin
	-- copy the variable to desambiguate the var name
	v_company_id := company_id;

	-- make sure to remove links from all offices to this company.
	update im_offices
	set company_id = null
	where company_id = v_company_id;

	-- Erase the im_companies item associated with the id
	delete from im_companies
	where company_id = v_company_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_company_id;
	acs_object.del(v_company_id);
    end del;

    function name (company_id in integer) return varchar
    is
	v_name	im_companies.company_name%TYPE;
    begin
	select	company_name
	into	v_name
	from	im_companies
	where	company_id = name.company_id;

	return v_name;

    end name;

    function type (company_id in integer) return integer
    is
	v_type_id	integer;
    begin
	select	company_type_id
	into	v_type_id
	from	im_companies
	where	company_id = type.company_id;

	return v_type_id;
    end type;

end im_company;
/
show errors



---------------------------------------------------------
-- Setup Demo Data
---------------------------------------------------------

prompt *** Creating "Internal" company, representing the company itself
DECLARE
    v_office_id		integer;
    v_company_id	integer;
BEGIN
    -- First setup the main office
    v_office_id := im_office.new(
        object_type     => 'im_office',
        office_name     => 'Project/Open Main Office',
        office_path     => 'po_main_office'
    );

    v_company_id := im_company.new(
	object_type	=> 'im_company',
	company_name	=> 'Internal',
	company_path	=> 'internal',
	main_office_id	=> v_office_id,
	-- 'Internal' company type
	company_type_id => 53,
	-- 'Active' status
	company_status_id => 46
    );
end;
/



prompt *** -- Create the "TecnoLoge" company
DECLARE
    v_office_id		integer;
    v_company_id	integer;
BEGIN
    -- First setup the main office
    v_office_id := im_office.new(
        object_type     => 'im_office',
        office_name     => 'TecnoLoge Main Office',
        office_path     => 'tecnologoe_main_office'
    );

    v_company_id := im_company.new(
	object_type	=> 'im_company',
	company_name	=> 'TecnoLoge',
	company_path	=> 'tecnologe',
	main_office_id	=> v_office_id,
	-- IT Consulting
	company_type_id => 55,
	-- 'Active' status
	company_status_id => 46
    );
end;
/
commit;


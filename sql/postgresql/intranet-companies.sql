-- /packages/intranet/sql/postgres/intranet-core-create.sql
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

select acs_object_type__create_type (
        'im_company',		-- object_type
        'Company',		-- pretty_name
        'Companies',		-- pretty_plural
        'im_biz_object',	-- supertype
        'im_companies',		-- table_name
        'company_id',		-- id_column
        'im_company',		-- package_name
        'f',			-- abstract_p
        null,			-- type_extension_table
        'im_company__name'	-- name_method
);


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
	vat_number		varchar(100),
				-- Default value for VAT
	default_vat		numeric(12,1) default 0,
				-- default payment days
	default_payment_days	integer,
				-- Default invoice template
	default_invoice_template_id	integer
				constraint im_companies_def_invoice_template_fk
				references im_categories
				-- Default payment method
	default_payment_method_id	integer
				constraint im_companies_def_invoice_payment_fk
				references im_categories
);


create or replace function im_company__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer
) returns integer as '
DECLARE
	p_company_id      alias for $1;
	p_object_type     alias for $2;
	p_creation_date   alias for $3;
	p_creation_user   alias for $4;
	p_creation_ip     alias for $5;
	p_context_id      alias for $6;

	p_company_name	      alias for $7;
	p_company_path	      alias for $8;
	p_main_office_id      alias for $9;
	p_company_type_id     alias for $10;
	p_company_status_id   alias for $11;

	v_company_id	      integer;
BEGIN
	v_company_id := acs_object__new (
		p_company_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_companies (
		company_id, company_name, company_path, 
		company_type_id, company_status_id, main_office_id
	) values (
		v_company_id, p_company_name, p_company_path, 
		p_company_type_id, p_company_status_id, p_main_office_id
	);

	-- Set the link back from the office to the company
	update	im_offices
	set	company_id = v_company_id
	where	office_id = p_main_office_id;

	return v_company_id;
end;' language 'plpgsql';


create or replace function im_company__delete (integer) returns integer as '
DECLARE
	v_company_id	     alias for $1;
BEGIN
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

	PERFORM acs_object__delete(v_company_id);

	return 0;
end;' language 'plpgsql';

create or replace function im_company__name (integer) returns varchar as '
DECLARE
	v_company_id	alias for $1;
	v_name		varchar;
BEGIN
	select	company_name
	into	v_name
	from	im_companies
	where	company_id = v_company_id;

	return v_name;
end;' language 'plpgsql';

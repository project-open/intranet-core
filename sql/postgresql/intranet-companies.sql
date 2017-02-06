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

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_company', 'im_companies', 'company_id');

update acs_object_types set
        status_type_table = 'im_companies',
        status_column = 'company_status_id',
        type_column = 'company_type_id'
where object_type = 'im_company';

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_company','view','/intranet/companies/view?company_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_company','edit','/intranet/companies/new?company_id=');



create table im_companies (
	company_id 			integer
					constraint im_companies_pk
					primary key 
					constraint im_companies_cust_id_fk
					references acs_objects,
	company_name			varchar(1000) not null
					constraint im_companies_name_un unique,
					-- where are the files in the filesystem?
	company_path			varchar(100) not null
					constraint im_companies_path_un unique,
	main_office_id			integer not null
					constraint im_companies_office_fk
					references im_offices,
	deleted_p			char(1) default('f')
					constraint im_companies_deleted_p 
					check(deleted_p in ('t','f')),
	company_status_id		integer not null
					constraint im_companies_cust_stat_fk
					references im_categories,
	company_type_id			integer not null
					constraint im_companies_cust_type_fk
					references im_categories,
	crm_status_id			integer 
					constraint im_companies_crm_status_fk
					references im_categories,
	primary_contact_id		integer 
					constraint im_companies_prim_cont_fk
					references users,
	accounting_contact_id		integer 
					constraint im_companies_acc_cont_fk
					references users,
	note				text,
	referral_source			text,
	annual_revenue_id		integer 
					constraint im_companies_ann_rev_fk
					references im_categories,
					-- keep track of when status is changed
	status_modification_date	date,
					-- and what the old status was
	old_company_status_id		integer 
					constraint im_companies_old_cust_stat_fk
					references im_categories,
					-- is this a company we can bill?
	billable_p			char(1) default('f')
					constraint im_companies_billable_p_ck 
					check(billable_p in ('t','f')),
					-- What kind of site does the company want?
	site_concept			varchar(100),
					-- Who in Client Services is the manager?
	manager_id			integer 
					constraint im_companies_manager_fk
					references users,
					-- How much do they pay us?
	contract_value			integer,
					-- When does the company start?
	start_date			date,
	vat_number			varchar(100),
					-- Default value for VAT
	default_vat			numeric(12,1) default 0,
					-- Default value for VAT
	default_tax			numeric(12,1) default 0,
					-- default payment days
	default_payment_days		integer,
					-- Default payment method
	default_payment_method_id	integer
					constraint im_companies_def_invoice_payment_fk
					references im_categories,
	default_invoice_template_id	integer
					constraint im_companies_def_invoice_template_fk
					references im_categories,
	default_quote_template_id	integer
					constraint im_companies_def_quote_template_fk
					references im_categories,
	default_delnote_template_id	integer
					constraint im_companies_def_delnote_template_fk
					references im_categories,
	default_bill_template_id	integer
					constraint im_companies_def_bill_template_fk
					references im_categories,
	default_po_template_id		integer	
					constraint im_companies_def_po_template_fk
					references im_categories
);


create or replace function im_company__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer
) returns integer as $body$
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

	-- Make a party - required for contacts
	insert into parties (party_id) values (v_company_id);
	insert into im_biz_objects (object_id) values (v_company_id);

	-- Set the link back from the office to the company
	update	im_offices
	set	company_id = v_company_id
	where	office_id = p_main_office_id;

	return v_company_id;
end;$body$ language 'plpgsql';


create or replace function im_company__delete (integer) 
returns integer as $body$
DECLARE
	p_company_id	     alias for $1;

	v_office_id	     integer;
BEGIN
	-- make sure to remove links from all offices to this company.
	update im_offices
	set company_id = null
	where company_id = p_company_id;

	-- Erase the im_companies item associated with the id
	delete from im_companies
	where company_id = p_company_id;

	-- Delete entry from parties
	delete from parties where party_id = p_company_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = p_company_id;

	-- Delete context references to this company
	update acs_objects set
		context_id = null
	where
		context_id = p_company_id;

	-- Delete the acs_object
	PERFORM acs_object__delete(p_company_id);

	return 0;
end;$body$ language 'plpgsql';


create or replace function im_company__name (integer) 
returns varchar as $body$
DECLARE
	p_company_id	alias for $1;
	v_name		varchar;
BEGIN
	select	company_name
	into	v_name
	from	im_companies
	where	company_id = p_company_id;

	return v_name;
end;$body$ language 'plpgsql';


-- Returns a TCL list of company_id suitable to stuff into a
-- TCL hash array of all companies associated to a specific user.
create or replace function im_company_list_for_user_html (integer) 
returns varchar as $body$
DECLARE
	p_user_id	alias for $1;

	v_html		varchar;
	row		RECORD;
BEGIN
	v_html := '';
	FOR row IN
		select	c.company_id
		from	im_companies c,
			acs_rels r
		where	r.object_id_one = c.company_id and
			r.object_id_two = p_user_id
		order by
			lower(c.company_name)
	LOOP
		IF '' != v_html THEN v_html := v_html || ' '; END IF;
		v_html := v_html || row.company_id;
	END LOOP;

	return v_html;
end;$body$ language 'plpgsql';









-------------------------------------------------------------------
-- Create relationships between BizObject and Persons
-------------------------------------------------------------------


-------------------------------------------------------------------
-- "Employee of a Company" relationship
-- It doesn't matter if it's the "internal" company, a customer
-- company or a provider company.
-- Instances of this relationship are created whenever ...??? ToDo
-- Usually included DynFields:
--	- Position
--
-- ]po[ HR information is actually attached to a specific subtype
-- of this rel "internal employee"
-- In ]po[ we will create a "im_company_employee_rel" IF:
--	- The user is an "Employee" and its the "internal" company.
--	- The user is a "Customer" and the company is a "customer".
--	- The user is a "Freelancer" and the company is a "provider".

SELECT acs_rel_type__create_role('employee', '#acs-translations.role_employee#', '#acs-translations.role_employee_plural#');
SELECT acs_rel_type__create_role('employer', '#acs-translations.role_employer#', '#acs-translations.role_employer_plural#');

SELECT acs_object_type__create_type(
	'im_company_employee_rel',			-- object_type
	'Company-Employee Relationship',		-- pretty_name
	'Company-Employee Relationships',		-- pretty_plural
	'im_biz_object_member',				-- supertype
	'im_company_employee_rels',			-- table_name
	'employee_rel_id',				-- id_column
	'intranet-core-company-employee-rel', 		-- package_name
	'f',						-- abstract_p
	null,						-- type_extension_table
	NULL						-- name_method
);

create table im_company_employee_rels (
	employee_rel_id		integer
				REFERENCES acs_rels
				ON DELETE CASCADE
	CONSTRAINT im_company_employee_rel_id_pk PRIMARY KEY
);


insert into acs_rel_types (
	rel_type, object_type_one, role_one,
	min_n_rels_one, max_n_rels_one,
	object_type_two, role_two, min_n_rels_two, max_n_rels_two
) values (
	'im_company_employee_rel', 'im_company', 'employer', 
	'1', NULL,
	'party', 'employee', '1', NULL
);



create or replace function im_company_employee_rel__new (
	integer, varchar, integer, integer, integer, integer, varchar, integer
) returns integer as $body$
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_company_employee_rel
	p_object_id_one		alias for $3;
	p_object_id_two		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_object_id_one,
		p_object_id_two,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_company_employee_rels (
	       rel_id, sort_order
	) values (
	       v_rel_id, p_sort_order
	);

	return v_rel_id;
end;$body$ language 'plpgsql';


create or replace function im_company_employee_rel__delete (integer)
returns integer as $body$
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_company_employee_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;$body$ language 'plpgsql';



------------------------------------------------------------------
-- "Key Account Manager" relationship
--
-- A "key account" is a member of group "Employees" who is entitled
-- to manage a customer or provider company.
--
-- Typical extension field for this relationship:
--	- Contract Value (to be signed by this key account)
--
-- Instances of this rel are created by ]po[ if and only if we
-- create a im_biz_object_membership rel with type "Key Account".

SELECT acs_rel_type__create_role('key_account', '#acs-translations.role_key_account#', '#acs-translations.role_key_account_plural#');
SELECT acs_rel_type__create_role('company', '#acs-translations.role_company#', '#acs-translations.role_company_plural#');

SELECT acs_object_type__create_type (
	'im_key_account_rel',
	'#intranet-core.key_account_rel#',
	'#intranet-core.key_account_rels#',
	'im_biz_object_member',
	'im_key_account_rels',
	'key_account_rel_id',
	'intranet-core-key-account-rel', 
	'f',
	null,
	NULL
);

create table im_key_account_rels (
	key_account_rel_id	integer
				REFERENCES acs_rels
				ON DELETE CASCADE
	CONSTRAINT im_key_account_rel_id_pk PRIMARY KEY
);


insert into acs_rel_types (
	rel_type, object_type_one, role_one,
	min_n_rels_one, max_n_rels_one,
	object_type_two, role_two, min_n_rels_two, max_n_rels_two
) values (
	'im_key_account_rel', 'im_company', 'company',
	'1', NULL,
	'party', 'key_account', '1', NULL
);



create or replace function im_key_account_rel__new (
	integer, varchar, integer, integer, integer, integer, varchar, integer
) returns integer as $body$
DECLARE
	p_rel_id		alias for $1;	-- null
	p_rel_type		alias for $2;	-- im_key_account_rel
	p_object_id_one		alias for $3;
	p_object_id_two		alias for $4;
	p_context_id		alias for $5;
	p_creation_user		alias for $6;	-- null
	p_creation_ip		alias for $7;	-- null

	v_rel_id	integer;
BEGIN
	v_rel_id := acs_rel__new (
		p_rel_id,
		p_rel_type,
		p_object_id_one,
		p_object_id_two,
		p_context_id,
		p_creation_user,
		p_creation_ip
	);

	insert into im_key_account_rels (
	       rel_id, sort_order
	) values (
	       v_rel_id, p_sort_order
	);

	return v_rel_id;
end;$body$ language 'plpgsql';


create or replace function im_key_account_rel__delete (integer)
returns integer as $body$
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_key_account_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;$body$ language 'plpgsql';


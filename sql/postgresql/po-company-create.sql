-- /packages/intranet-core/sql/postgres/intranet-company-create.sql
--
-- Copyright (C) 1999-2004 Project/Open
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
-- @author      various@arsdigita.com
-- @author      frank.bergmann@project-open.com


---------------------------------------------------------
-- Companies
--
-- Legal institutions without physical location.
-- However, there is a "main_office"
--

CREATE FUNCTION inline_0 ()
RETURNS integer AS '
begin
	PERFORM acs_object_type__create_type (
	''po_company'',		-- object_type
 	''Company'',		-- pretty_name
	''Companies'',		-- pretty_plural
	''group'',		-- supertype
	''po_companies'',	-- table_name
	''company_id'',		-- id_column
	null,			-- package_name
	''f'',			-- abstract_p
	null,			-- type_extension_table
	null			-- name_method
	);
	return 0;
end;' LANGUAGE 'plpgsql';

SELECT inline_0 ();

DROP FUNCTION inline_0 ();


-- Each po_company has the super_type of "group"
-- which corresponds to its "administrative group" (members
-- and admins of this group have read/write rights on the
-- biz object).

CREATE TABLE po_companies (
	company_id 		integer
				constraint po_company_pk
				primary key
				constraint po_company_fk
				references acs_objects,
	-- standard P/O business objects fields
	name			varchar(200),
				constraint po_company_name_un 
				unique (name),
	short_name		varchar(100),
				constraint po_company_short_name_un 
				unique (short_name),
	admin_group_id		integer
				constraint po_company_admin_group_fk 
				references groups,
	status_id		integer
				constraint po_company_status_fk
				references po_categories,
	type_id			integer
				constraint po_company_type_fk
				references po_categories,
	note			varchar(4000),
	-- object specific fields
	crm_status_id		integer
				constraint po_crm_status_fk
				references po_categories,
	primary_contact_id	integer
				constraint po_primary_contact_fk
				references parties,
	accounting_contact_id	integer
				constraint po_accounting_contact_fk
				references parties,
	referral_source		varchar(1000),
	annual_revenue_id	integer
				constraint po_annual_revenue_fk
				references po_categories,
	-- is this a company we can bill?
	billable_p		char(1) default 't'
				constraint po_billable_p_ck
				check(billable_p in ('t','f')),
	vat_number		varchar(100),
	-- the main office is automatically defined when creating a new company
	main_office_id		integer
				constraint po_main_office_fk
				references po_offices
);

comment on table po_companies is '
	Companies are legal entities with associated users and a lot
	of other objects such as offices, partners, ...
';

comment on column po_companies.company_id is '
	Primary Key, also PK of the associated administrative group.
';


CREATE FUNCTION po_company__new (
	integer,varchar,timestamptz,integer,varchar,integer,
	varchar,varchar,integer,integer,integer,varchar,
	integer,integer,integer,varchar,integer,char(1),varchar,integer
)
RETURNS integer AS '
declare
	p_company_id		alias for $1;	-- default null
	p_object_type		alias for $2;
	p_creation_date		alias for $3;	-- default now()
	p_creation_user		alias for $4;	-- default null
	p_creation_ip		alias for $5;	-- default null
	p_context_id		alias for $6;
	
	p_name			alias for $7;
	p_short_name		alias for $8;
	p_admin_group_id	alias for $9;
	p_status_id		alias for $10;
	p_type_id		alias for $11;
	p_note			alias for $12;

	p_crm_status_id		alias for $13;
	p_primary_contact_id	alias for $14;
	p_accounting_contact_id	alias for $15;
	p_referral_source	alias for $16;
	p_annual_revenue_id	alias for $17;
	p_billable_p		alias for $18;
	p_vat_number		alias for $19;
	p_main_office_id	alias for $20;

	v_company_id		po_companies.company_id%TYPE;
	v_email			varchar;
	v_url			varchar;
begin
	v_email := '''';
	v_url := '''';

	v_company_id := acs_group__new (
		p_company_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		null,
		v_url,
		p_name,
		null,
		p_context_id
	);

	insert into po_companies (
		company_id, name, short_name, admin_group_id, 
		status_id, type_id, note, crm_status_id, 
		primary_contact_id, accounting_contact_id, 
		referral_source, annual_revenue_id,
		billable_p, vat_number, main_office_id
	) values (
		v_company_id, p_name, p_short_name, p_admin_group_id, 
		p_status_id, p_type_id, p_note, p_crm_status_id, 
		p_primary_contact_id, p_accounting_contact_id,
		p_referral_source, p_annual_revenue_id,
		p_billable_p, p_vat_number, p_main_office_id
	);

	return v_company_id;

end;' LANGUAGE 'plpgsql';


CREATE FUNCTION po_company__delete (
	integer
)
RETURNS integer AS '
declare
	p_company_id		alias for $1;
begin
	-- Erase the po_companies item associated with the id
	delete from 	po_companies
	where		company_id = p_company_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = p_company_id;

	PERFORM acs_group__delete(p_company_id);

	return 0;

end;' LANGUAGE 'plpgsql';


-- function to return the name of the po_companies item
CREATE FUNCTION po_company__name (
	integer
)
RETURNS varchar AS '
declare
	p_company_id	alias for $1;
	v_name		varchar;
begin
	select	group_name
	into	v_name
	from	groups
	where	group_id = p_company_id;

	return v_name;

end;' LANGUAGE 'plpgsql';


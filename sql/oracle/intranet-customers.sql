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
-- Customers
--
-- We store simple information about a customer.
-- All contact information goes in the associated
-- admin_group and offices.
--


begin
    acs_object_type.create_type (
	supertype =>		'im_biz_object',
	object_type =>		'im_customer',
	pretty_name =>		'Customer',
	pretty_plural =>	'Customers',
	table_name =>		'im_customers',
	id_column =>		'customer_id',
	package_name =>		'im_customer',
	type_extension_table =>	null,
	name_method =>		'im_customer.name'
    );
end;
/
show errors


create table im_customers (
	customer_id 		integer
				constraint im_customers_pk
				primary key 
				constraint im_customers_cust_id_fk
				references acs_objects,
				-- avoid using the OpenACS permission system
				-- because we have to ask frequently:
				-- "Who has read permissions on this object".
	admin_group_id		integer not null
				constraint im_customers_admin_group_fk
				references groups,
	customer_name		varchar(1000) not null
				constraint im_customers_name_un unique,
				-- where are the files in the filesystem?
	customer_path		varchar(100) not null
				constraint im_customers_path_un unique,
	main_office_id		integer not null
				constraint im_customers_office_fk
				references im_offices,
	deleted_p		char(1) default('f')
				constraint im_customers_deleted_p 
				check(deleted_p in ('t','f')),
	customer_status_id	integer not null
				constraint im_customers_cust_stat_fk
				references categories,
	customer_type_id	integer not null
				constraint im_customers_cust_type_fk
				references categories,
	crm_status_id		integer 
				constraint im_customers_crm_status_fk
				references categories,
	primary_contact_id	integer 
				constraint im_customers_prim_cont_fk
				references users,
	accounting_contact_id	integer 
				constraint im_customers_acc_cont_fk
				references users,
	note			varchar(4000),
	referral_source		varchar(1000),
	annual_revenue_id	integer 
				constraint im_customers_ann_rev_fk
				references categories,
				-- keep track of when status is changed
	status_modification_date date,
				-- and what the old status was
	old_customer_status_id	integer 
				constraint im_customers_old_cust_stat_fk
				references categories,
				-- is this a customer we can bill?
	billable_p		char(1) default('f')
				constraint im_customers_billable_p_ck 
				check(billable_p in ('t','f')),
				-- What kind of site does the customer want?
	site_concept		varchar(100),
				-- Who in Client Services is the manager?
	manager_id		integer 
				constraint im_customers_manager_fk
				references users,
				-- How much do they pay us?
	contract_value		integer,
				-- When does the customer start?
	start_date		date,
	vat_number		varchar(100)
);



-- Setup the list of roles that a user can take with
-- respect to a customer:
--      Full Member (1300) and
--      Key Account Manager (1302)
--
insert into im_biz_object_role_map values ('im_customer',85,1300);
insert into im_biz_object_role_map values ('im_customer',85,1302);




create or replace package im_customer
is
    function new (
	customer_id	in integer default null,
	object_type	in varchar,
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	customer_name	in varchar,
	customer_path	in varchar,
	main_office_id	in integer,
	customer_type_id in  integer default 51,
	customer_status_id in integer default 46
    ) return integer;

    procedure del (customer_id in integer);
    function name (customer_id in integer) return varchar;
    function type (customer_id in integer) return integer;
end im_customer;
/
show errors


create or replace package body im_customer
is

    function new (
	customer_id	in integer default null,
	object_type	in varchar,
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	customer_name	in varchar,
	customer_path	in varchar,
	main_office_id	in integer,
	customer_type_id in  integer default 51,
	customer_status_id in integer default 46
    ) return integer
    is
	v_customer_id		integer;
	v_admin_group_id	integer;
    begin
	v_customer_id := acs_object.new (
		object_id =>		customer_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
	);

	v_admin_group_id := acs_group.new(
		group_name => customer_name
	);

	insert into im_customers (
		customer_id, admin_group_id, customer_name, customer_path, 
		customer_type_id, customer_status_id, main_office_id
	) values (
		v_customer_id, v_admin_group_id, customer_name, customer_path, 
		customer_type_id, customer_status_id, main_office_id
	);

	-- Set the link back from the office to the customer
	update im_offices
	set customer_id = v_customer_id
	where office_id = main_office_id;

	return v_customer_id;
    end new;


    -- Delete a single customer (if we know its ID...)
    procedure del (customer_id in integer)
    is
	v_customer_id		integer;
	v_admin_group_id	integer;
    begin
	-- copy the variable to desambiguate the var name
	v_customer_id := customer_id;

	-- make sure to remove links from all offices to this customer.
	update im_offices
	set customer_id = null
	where customer_id = v_customer_id;

	-- determine the admin group
	select admin_group_id
	into v_admin_group_id
	from im_customers
	where customer_id = v_customer_id;

	-- Erase the im_customers item associated with the id
	delete from im_customers
	where customer_id = v_customer_id;

	-- now: delete the administration group
	acs_group.del(v_admin_group_id);

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_customer_id;
	acs_object.del(v_customer_id);
    end del;

    function name (customer_id in integer) return varchar
    is
	v_name	im_customers.customer_name%TYPE;
    begin
	select	customer_name
	into	v_name
	from	im_customers
	where	customer_id = name.customer_id;

	return v_name;

    end name;

    function type (customer_id in integer) return integer
    is
	v_type_id	integer;
    begin
	select	customer_type_id
	into	v_type_id
	from	im_customers
	where	customer_id = type.customer_id;

	return v_type_id;
    end type;

end im_customer;
/
show errors


-- Create the "Internal" customer, representing the company itself
DECLARE
    v_office_id		integer;
    v_customer_id	integer;
BEGIN
    -- First setup the main office
    v_office_id := im_office.new(
        object_type     => 'im_office',
        office_name     => 'Project/Open Main Office',
        office_path     => 'po_main_office'
    );

    v_customer_id := im_customer.new(
	object_type	=> 'im_customer',
	customer_name	=> 'Internal',
	customer_path	=> 'internal',
	main_office_id	=> v_office_id,
	-- 'Internal' customer type
	customer_type_id => 53,
	-- 'Active' status
	customer_status_id => 46
    );
end;
/
show errors;

-- /packages/intranet/sql/intranet-core-create.sql
--
-- Project/Open Core Module, fraber@fraber.de, 030828
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- Copyright (C) 1999-2004 ArsDigita, Frank Bergmann and others
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


-------------------------------------------------------------
-- Categories
--
-- Values for ObjectType/ObjectStatus of all
-- major business objects such as project, customer,
-- user, ...
--
@intranet-categories.sql



-------------------------------------------------------------
-- Countries & Currencies
--
-- Required for im_facilities etc. to be able to define
-- location of an office etc..

@intranet-country-codes.sql
@intranet-currency-codes.sql


-------------------------------------------------------------
-- Users_Contact information
--
-- Table from ACS 3.4 data model copied into the Intranet 
-- in order to facilitate the porting process. However, this
-- information should be incorporated into a im_users table
-- or something similar in the future.

create table users_contact (
	user_id			integer 
				constraint users_contact_pk
				primary key
				constraint users_contact_pk_fk
				references users,
	home_phone		varchar(100),
	priv_home_phone		integer,
	work_phone		varchar(100),
	priv_work_phone 	integer,
	cell_phone		varchar(100),
	priv_cell_phone 	integer,
	pager			varchar(100),
	priv_pager		integer,
	fax			varchar(100),
	priv_fax		integer,
				-- AOL Instant Messenger
	aim_screen_name		varchar(50),
	priv_aim_screen_name	integer,
				-- MSN Instanet Messenger
	msn_screen_name		varchar(50),
	priv_msn_screen_name	integer,
				-- also ICQ
	icq_number		varchar(50),
	priv_icq_number		integer,
				-- Which address should we mail to?
	m_address		char(1) check (m_address in ('w','h')),
				-- home address
	ha_line1		varchar(80),
	ha_line2		varchar(80),
	ha_city			varchar(80),
	ha_state		varchar(80),
	ha_postal_code		varchar(80),
	ha_country_code		char(2) 
				constraint users_contact_ha_cc_fk
				references country_codes(iso),
	priv_ha			integer,
				-- work address
	wa_line1		varchar(80),
	wa_line2		varchar(80),
	wa_city			varchar(80),
	wa_state		varchar(80),
	wa_postal_code		varchar(80),
	wa_country_code		char(2)
				constraint users_contact_wa_cc
				references country_codes(iso),
	priv_wa			integer,
				-- used by the intranet module
	note			varchar(4000),
	current_information	varchar(4000)
);


-------------------------------------------------------------
-- Facilities
--
-- fraber 030826: Start loading with im_facilies, because
-- customers and other tables depend on them.
--
-- Facilities seem to represent the location of an "office",
-- allowing several offices to share the same facility.
-- This distinction is in this data model since the early
-- days of Philip Greenspun, but it is not being used
-- currently (office = facility)
--

create table im_facilities (
	facility_id		integer
				constraint im_facilities_id_pk 
				primary key
				constraint im_facilities_id_fk 
				references groups,
	facility_name		varchar(1000) not null
				constraint im_facilities_name_un unique,
	facility_path		varchar(100)
				constraint im_facilities_path_un unique,
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
				constraint im_facilities_cont_per_fk
				references users,
	landlord		varchar(4000),
	--- who supplies the security service, the code for
	--- the door, etc.
	security		varchar(4000),
	note			varchar(4000)
);


---------------------------------------------------------
-- Customers
--
-- We store simple information about a customer.
-- All contact information goes in the associated
-- facilities.
--

create table im_customers (
	customer_id 		primary key 
				constraint im_customers_cust_id_fk
				references groups,
	customer_name		varchar(1000) not null
				constraint im_customers_name_un unique,
				-- where are the files in the filesystem?
	customer_path		varchar(100) not null
				constraint im_customers_path_un unique,
	deleted_p		char(1) default('f')
				constraint im_customers_deleted_p 
				check(deleted_p in ('t','f')),
	customer_status_id	integer 
				constraint im_customers_cust_stat_fk
				references categories,
	customer_type_id	integer 
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
				-- When does the project start?
	start_date		date,
	vat_number		varchar(100),
	facility_id		integer
				constraint im_customers_facility_fk
				references im_facilities
);



-- What types of urls do we ask for when creating a new project
-- and in what order?
create sequence im_url_types_type_id_seq start with 1;
create table im_url_types (
	url_type_id		integer not null primary key,
	url_type		varchar(200) not null 
				constraint im_url_types_type_un unique,
	-- we need a little bit of meta data to know how to ask 
	-- the user to populate this field
	to_ask			varchar(1000) not null,
	-- if we put this information into a table, what is the 
	-- header for this type of url?
	to_display		varchar(100) not null,
	display_order		integer default 1
);
	

-----------------------------------------------------------
-- Projects
--
-- The project_id of every project corresponds to a group
-- which holds the project members (convention from ACS 3.4 Intranet).
--
-- Each project can have any number of sub-projects


create table im_projects (
	project_id		integer
				constraint im_projects_pk 
				primary key 
				constraint im_project_prj_fk 
				references groups,
	project_name		varchar(1000) not null
				constraint im_projects_name_un unique,
	project_nr		varchar(100) not null
				constraint im_projects_nr_un unique,
	project_path		varchar(100) not null
				constraint im_projects_path_un unique,
	parent_id		integer 
				constraint im_projects_parent_fk 
				references im_projects,
	customer_id		integer not null
				constraint im_projects_customer_fk 
				references im_customers,
	project_type_id		not null 
				constraint im_projects_prj_type_fk 
				references categories,
	project_status_id	not null 
				constraint im_projects_prj_status_fk 
				references categories,
	description		varchar(4000),
	bill_hourly_p		char(1) 
				constraint im_projects_bill_hourly_check
				check (bill_hourly_p in ('t','f')),
	start_date		date,
	end_date		date,
				-- make sure the end date is after the start date
				constraint im_projects_date_const 
				check( end_date - start_date >= 0 ),	
	note			varchar(4000),
	project_lead_id		integer 
				constraint im_projects_prj_lead_fk 
				references users,
	supervisor_id		integer 
				constraint im_projects_supervisor_fk 
				references users,
	requires_report_p	char(1) default('t')
				constraint im_project_requires_report_p 
				check (requires_report_p in ('t','f')),
	project_budget		number(12,2)
);
create index im_project_parent_id_idx on im_projects(parent_id);


-- Table to store all changes in the project status field,
-- to be able to track the evolution of the project history 
-- in a timeline.

create table im_projects_status_audit (
	project_id		integer,
	project_status_id	integer,
	audit_date		date
);
create index im_proj_status_aud_id_idx on im_projects_status_audit(project_id);

create or replace trigger im_projects_status_audit_tr
before update or delete on im_projects
for each row
begin
	insert into im_projects_status_audit (
		project_id, project_status_id, audit_date
	) values (
		:old.project_id, :old.project_status_id, sysdate
	);
end im_projects_status_audit_tr;
/
show errors


-- An old ACS 3.4 Intranet table tha is not currently in use.
-- However, it is currently included to facilitate the porting
-- process to OpenACS 5.0

create table im_project_url_map (
	project_id		not null 
				constraint im_project_url_map_project_fk
				references im_projects,
	url_type_id		not null
				constraint im_project_url_map_url_type_fk
				references im_url_types,
	url			varchar(250),
	-- each project can have exactly one type of each type
	-- of url
	primary key (project_id, url_type_id)
);

-- We need to create an index on url_type_id if we ever want to ask
-- "What are all the staff servers?"
create index im_proj_url_url_proj_idx on 
im_project_url_map(url_type_id, project_id);



--------------------------------------------------------------
-- Offices
--
-- The organizational component of an offcie/facility couple.
-- Is also identified by a group for management purposes.
--

create table im_offices (
	office_id	integer 
			constraint im_offices_office_id_pk 
			primary key
			constraint im_offices_office_id_fk 
			references groups,
	office_name	varchar(1000) not null
			constraint im_offices_name_un unique,
	office_path	varchar(100) not null
			constraint im_offices_path_un unique,
	facility_id 	integer
			constraint im_offices_facility_id 
			references im_facilities
			constraint im_offices_facility_id_nn not null,
	--- is this office and contact information public?
	public_p	char(1) default 'f'
			constraint im_offices_public_p_ck 
			check(public_p in ('t','f'))
);




--------------------------------------------------------------
-- Views
--------------------------------------------------------------


-- Function to add a new member to a user_group
create or replace procedure user_group_member_add (
	p_group_id IN integer,
	p_user_id IN integer,
	p_role IN varchar)
IS
	v_system_user_id	integer;
	v_rel_id		integer;
BEGIN
	v_system_user_id := 0;
        v_rel_id := membership_rel.new(
                object_id_one    => p_group_id,
                object_id_two    => p_user_id,
                creation_user    => v_system_user_id,
                creation_ip      => '0:0:0:0'
         );
end;
/
show errors


-- we store simple information about a customer
-- all contact information goes in the address book
create table im_partners (
	partner_id 		integer
				constraint im_partner_pk
				primary key 
				constraint im_partner_partner_id_fk
				references groups,
	partner_name		varchar(1000) not null
				constraint im_partners_name_un unique,
	partner_path		varchar(100) not null
				constraint im_partners_path_un unique,
	deleted_p		char(1) default('f') 
				constraint im_partners_deleted_p 
				check(deleted_p in ('t','f')),
	partner_type_id		integer
				constraint im_partner_type_fk
				references categories,
	partner_status_id	integer
				constraint im_partner_status_fk
				references categories,
	primary_contact_id	integer
				constraint im_partner_contact_fk
				references users,
	url			varchar(200),
	note			varchar(4000),
	referral_source		varchar(1000),
	annual_revenue_id	integer
				constraint im_partner_ann_rev_fk
				references categories
);



-- Some helper functions to make our queries easier to read

create or replace function im_category_from_id (p_category_id IN integer)
return varchar
IS
	v_category	varchar(50);
BEGIN
	select category
	into v_category
	from categories
	where category_id = p_category_id;

	return v_category;

end im_category_from_id;
/
show errors;




create or replace function ad_group_member_p (
    p_user_id IN integer,
    p_group_id IN integer
)
return char
IS
    ad_group_member_p    char(1);
BEGIN
    select decode(count(*), 0, 'f', 't')
    into ad_group_member_p
    from group_member_map
    where     group_id = p_group_id
              and member_id = p_user_id;

    return ad_group_member_p;

END ad_group_member_p;
/
show errors


create or replace function im_proj_url_from_type ( 
	v_project_id IN integer, 
	v_url_type IN varchar )
return varchar
IS 
	v_url 		im_project_url_map.url%TYPE;
BEGIN
	begin
	select url 
	into v_url 
	from 
		im_url_types, 
		im_project_url_map
	where 
		project_id=v_project_id
		and im_url_types.url_type_id=im_project_url_map.url_type_id
		and url_type=v_url_type;
	
	exception when others then null;
	end;
	return v_url;
END;
/
show errors;




-- you can't do a JOIN with a CONNECT BY so we need a PL/SQL proc to
-- pull out user's name from user_id

create or replace function im_name_from_user_id(v_user_id IN integer)
return varchar
is
	v_full_name varchar(8000);
BEGIN
	select first_names || ' ' || last_name into v_full_name 
	from persons
	where person_id = v_user_id;
	return v_full_name;
END im_name_from_user_id;
/
show errors


create or replace function im_email_from_user_id(v_user_id IN integer)
return varchar
is
	v_email varchar(100);
BEGIN
	select email
	into v_email
	from parties
	where party_id = v_user_id;

	return v_email;
END im_email_from_user_id;
/
show errors


create or replace function im_initials_from_user_id(v_user_id IN integer)
return varchar
is
	v_initials varchar(2);
BEGIN
	select substr(first_names,1,1) || substr(last_name,1,1) into v_initials
	from persons
	where person_id = v_user_id;
	return v_initials;
END im_initials_from_user_id;
/
show errors



-- Populate all the status/type/url with the different types of 
-- data we are collecting

create or replace function im_first_letter_default_to_a ( 
	p_string IN varchar 
) 
RETURN char
IS
	v_initial	char(1);
BEGIN

	v_initial := substr(upper(p_string),1,1);

	IF v_initial IN (
		'A','B','C','D','E','F','G','H','I','J','K','L','M',
		'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
	) THEN
	RETURN v_initial;
	END IF;
	
	RETURN 'A';

END;
/
show errors;
	

-- ------------------------------------------------------------
-- Intranet Groups
--
-- Intranet groups serve to maintain permissions for
-- users.
-- ------------------------------------------------------------


create or replace procedure im_create_intranet_group (
        v_pretty_name IN varchar
)
IS
  v_system_user_id  integer;
  v_group_id        integer;
  v_rel_id	    integer;
  n_groups	    integer;
BEGIN

     -- Check that the group doesn't exist before
     select count(*)
     into n_groups
     from groups
     where group_name = v_pretty_name;

     -- only add the group if it didn't exist before...
     if n_groups = 0 then

	-- call procedure defined in community-core.sql to get system user
	v_system_user_id := 0;

	v_group_id := acs_group.new(
		context_id	 => null,
		group_id	 => null,
		creation_user    => v_system_user_id,
		creation_ip	 => '0:0:0:0',
		group_name	 => v_pretty_name
	 );

	v_rel_id := composition_rel.new(
		object_id_one    => -2,
		object_id_two    => v_group_id,
		creation_user    => v_system_user_id,
		creation_ip	 => '0:0:0:0'
	 );
      end if;
END;
/
show errors;



-- add an admin group for all kinds of objects
create or replace function im_create_administration_group (v_pretty_name IN varchar)
return integer
IS
  v_system_user_id  integer;
  v_group_id        integer;
BEGIN
	-- get system user
	v_system_user_id := 0;
	v_group_id := acs_group.new(
		context_id	 => null,
		group_id	 => null,
		creation_user    => v_system_user_id,
		creation_ip	 => '0:0:0:0',
		group_name	 => v_pretty_name
	 );
	return v_group_id;
END im_create_administration_group;
/
show errors;



-- Create the basic groups for intranet
begin
   im_create_intranet_group ('P/O Admins');
   im_create_intranet_group ('Customers'); 
   im_create_intranet_group ('Offices'); 
   im_create_intranet_group ('Employees'); 
   im_create_intranet_group ('Freelancers'); 
   im_create_intranet_group ('Project Managers'); 
   im_create_intranet_group ('Senior Managers'); 
   im_create_intranet_group ('Accounting'); 
end;
/
show errors;





-- -----------------------------------------------------------
-- Source additional files for Project/Open Core
-- 
-- views:
--	Defines how to render (HTML) the columns of "index" 
--	pages. This allows other modules to modify the
--	views of the Core pages, for example adding values
--	to the list that are defined in the additional
--	modules.
--
-- components:
--	Calls to TCL components that return a formatted
--	HTML widget. Allows modules to insert their components
--	into Core object pages (for instance the filestorage
--	component into project page).
--
-- menus:
--	Similar to components: Allows modules ot add their
--	menu entries to the main and submenus
--

@intranet-views.sql
@intranet-components.sql
@intranet-menus.sql


-- demodata:
--	Creates the users, customers and projects of a sample
--	company.
--
-- @intranet-demodata.sql



-- -----------------------------------------------------------
-- advance categories counter
-- drop sequence ad_category_id_seq;
-- create sequence ad_category_id_seq start with 10000;

drop sequence category_id_sequence;
create sequence category_id_sequence start with 2400;





-- /packages/intranet/sql/intranet-users.sql
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


-------------------------------------------------------------
-- Portrait Fields
--
alter table persons add portrait_checkdate date;
alter table persons add portrait_file varchar(400);
alter table persons add demo_group varchar(50);
alter table persons add demo_password varchar(50);


-------------------------------------------------------------
-- Skin Field
--

alter table users add skin integer;
alter table users alter column skin set default 0;


-------------------------------------------------------------
-- Tell OpenACS that users and persons are tables for
-- object type user
--

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('person', 'persons', 'person_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('person','users_contact','user_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('person','parties','party_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('person','im_employees','employee_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('user', 'users', 'user_id');


-------------------------------------------------------------
-- Fix extension tables for user


insert into acs_object_type_tables (object_type,table_name,id_column)
values ('user', 'persons', 'person_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('user','users_contact','user_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('user','parties','party_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('user','im_employees','employee_id');

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('user', 'users', 'user_id');

    
insert into im_employees (employee_id) 
select person_id 
from persons
where person_id not in (select employee_id from im_employees);



-- Fix bad entries from OpenACS
update acs_attributes 
	set table_name = 'persons' 
where object_type = 'person' and table_name is null;

-- Update status and type for persons/users
update acs_object_types
	set type_category_type = 'Intranet User Type',
	set type_category_status = 'Intranet User Status',
where object_type = 'person';


create or replace function inline_0 ()
returns integer as '
declare
	row		RECORD;
	v_category_id	integer;
begin
	FOR row IN
		select	g.*
		from	groups g,
			im_profiles p
		where	p.profile_id = g.group_id
        LOOP
		PERFORM im_category_new(nextval(''im_categories_seq'')::integer, row.group_name, ''Intranet User Type'');
		update im_categories set aux_int1 = row.group_id where category = row.group_name and category_type = ''Intranet User Type'';
        END LOOP;

        RETURN 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



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
				constraint users_contact_wa_cc_fk
				references country_codes(iso),
	priv_wa			integer,
				-- used by the intranet module
	note			text,
	current_information	text
);

------------------------------------------------------
-- A unified view on active users
-- (not deleted or banned)
--
create or replace view users_active as 
select
	u.user_id,
	u.username,
	u.screen_name,
	u.last_visit,
	u.second_to_last_visit,
	u.n_sessions,
	u.first_names,
	u.last_name,
	c.home_phone,
	c.priv_home_phone,
	c.work_phone,
	c.priv_work_phone,
	c.cell_phone,
	c.priv_cell_phone,
	c.pager,
	c.priv_pager,
	c.fax,
	c.priv_fax,
	c.aim_screen_name,
	c.priv_aim_screen_name,
	c.msn_screen_name,
	c.priv_msn_screen_name,
	c.icq_number,
	c.priv_icq_number,
	c.m_address,
	c.ha_line1,
	c.ha_line2,
	c.ha_city,
	c.ha_state,
	c.ha_postal_code,
	c.ha_country_code,
	c.priv_ha,
	c.wa_line1,
	c.wa_line2,
	c.wa_city,
	c.wa_state,
	c.wa_postal_code,
	c.wa_country_code,
	c.priv_wa,
	c.note,
 	c.current_information
from 
	registered_users u left outer join users_contact c on u.user_id = c.user_id
;


-- ToDo: Localize this function for Japanese
--
create or replace function im_name_from_user_id(integer)
returns varchar as '
DECLARE
	v_user_id	alias for $1;
	v_full_name	text;
BEGIN
	select first_names || '' '' || last_name into v_full_name 
	from persons
	where person_id = v_user_id;

	return v_full_name;

END;' language 'plpgsql';

create or replace function im_email_from_user_id(integer)
returns varchar as '
DECLARE
	v_user_id	alias for $1;
	v_email varchar(100);
BEGIN
	select email
	into v_email
	from parties
	where party_id = v_user_id;

	return v_email;
END;' language 'plpgsql';


create or replace function im_initials_from_user_id(integer)
returns varchar as '
DECLARE
	v_user_id	alias for $1;
	v_initials	varchar(2);
BEGIN
	select substr(first_names,1,1) || substr(last_name,1,1) into v_initials
	from persons
	where person_id = v_user_id;
	return v_initials;
END;' language 'plpgsql';


-- Shortcut to add a user to a profile (group)
-- Example:
--      im_profile_add_user('Employees', 456)
--
create or replace function im_profile_add_user (varchar, integer)
returns integer as '
DECLARE
        p_group_name    alias for $1;
        p_grantee_id    alias for $2;

        v_group_id      integer;
        v_rel_id        integer;
        v_count         integer;
BEGIN
        -- Get the group_id from group_name
        select group_id into v_group_id from groups
        where lower(group_name) = lower(p_group_name);
        IF v_group_id is null THEN RETURN 0; END IF;

        -- skip if the relationship already exists
        select  count(*) into v_count from acs_rels
        where   object_id_one = v_group_id
                and object_id_two = p_grantee_id
                and rel_type = ''membership_rel'';
        IF v_count > 0 THEN RETURN 0; END IF;

        v_rel_id := membership_rel__new(v_group_id, p_grantee_id);

        RETURN v_rel_id;
end;' language 'plpgsql';





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
	'im_company_employee_rel',
	'#intranet-contacts.company_employee_rel#',
	'#intranet-contacts.company_employee_rels#',
	'im_biz_object_member',
	'im_company_employee_rels',
	'employee_rel_id',
	'intranet-contacts.comp_emp', 
	'f',
	null,
	NULL
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
	object_type_two, role_two,min_n_rels_two, max_n_rels_two
) values (
	'im_company_employee_rel', 'im_company', 'employer', 
	'1', NULL,
	'person', 'employee', '1', NULL
);



create or replace function im_company_employee_rel__new (
	integer, varchar, integer, integer, integer, integer, varchar, integer
) returns integer as '
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
end;' language 'plpgsql';


create or replace function im_company_employee_rel__delete (integer)
returns integer as '
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_company_employee_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;' language 'plpgsql';



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
	'#intranet-contacts.key_account_rel#',
	'#intranet-contacts.key_account_rels#',
	'im_biz_object_member',
	'im_key_account_rels',
	'key_account_rel_id',
	'intranet-contacts.key_account', 
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
	object_type_two, role_two,min_n_rels_two, max_n_rels_two
) values (
	'im_key_account_rel', 'im_company', 'company',
	'1', NULL,
	'person', 'key_account', '1', NULL
);



create or replace function im_key_account_rel__new (
	integer, varchar, integer, integer, integer, integer, varchar, integer
) returns integer as '
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
end;' language 'plpgsql';


create or replace function im_key_account_rel__delete (integer)
returns integer as '
DECLARE
	p_rel_id	alias for $1;
BEGIN
	delete	from im_key_account_rels
	where	rel_id = p_rel_id;

	PERFORM acs_rel__delete(p_rel_id);
	return 0;
end;' language 'plpgsql';




-------------------------------------------------------------------
-- Categories 
-------------------------------------------------------------------


-- 22000-22999 Intranet User Type
SELECT im_category_new(22000, 'Registered Users', 'Intranet User Type');
SELECT im_category_new(22010, 'The Public', 'Intranet User Type');
SELECT im_category_new(22020, 'P/O Admins', 'Intranet User Type');
SELECT im_category_new(22030, 'Customers', 'Intranet User Type');
SELECT im_category_new(22040, 'Employees', 'Intranet User Type');
SELECT im_category_new(22050, 'Freelancers', 'Intranet User Type');
SELECT im_category_new(22060, 'Project Managers', 'Intranet User Type');
SELECT im_category_new(22070, 'Senior Managers', 'Intranet User Type');
SELECT im_category_new(22080, 'Accounting', 'Intranet User Type');
SELECT im_category_new(22090, 'Sales', 'Intranet User Type');
SELECT im_category_new(22100, 'HR Managers', 'Intranet User Type');
SELECT im_category_new(22110, 'Freelance Managers', 'Intranet User Type');



create or replace view im_user_type as
select
	category_id as user_type_id,
	category as user_type
from 	im_categories
where	category_type = 'Intranet User Type'
	and (enabled_p is null OR enabled_p = 't');


create or replace view im_user_status as
select
	category_id as user_status_id,
	category as user_status
from 	im_categories
where	category_type = 'Intranet User Status'
	and (enabled_p is null OR enabled_p = 't');


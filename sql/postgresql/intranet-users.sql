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

alter table users add skin_id integer default 0;


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

-- Should be "person" first field?
-- insert into acs_object_type_tables (object_type,table_name,id_column)
-- values ('user', 'users', 'user_id');


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



-- Fix bad entries from OpenACS
update acs_attributes 
	set table_name = 'persons' 
where object_type = 'person' and table_name is null;

-- Update status and type for persons/users
update acs_object_types set
	type_category_type = 'Intranet User Type',
	status_category_type = 'Intranet User Status'
where object_type = 'person';


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
	home_phone		text,
	priv_home_phone		integer,
	work_phone		text,
	priv_work_phone 	integer,
	cell_phone		text,
	priv_cell_phone 	integer,
	pager			text,
	priv_pager		integer,
	fax			text,
	priv_fax		integer,
				-- AOL Instant Messenger
	aim_screen_name		text,
	priv_aim_screen_name	integer,
				-- MSN Instanet Messenger
	msn_screen_name		text,
	priv_msn_screen_name	integer,
				-- also ICQ
	icq_number		text,
	priv_icq_number		integer,
				-- Which address should we mail to?
	m_address		char(1) check (m_address in ('w','h')),
				-- home address
	ha_line1		text,
	ha_line2		text,
	ha_city			text,
	ha_state		text,
	ha_postal_code		text,
	ha_country_code		char(2) 
				constraint users_contact_ha_cc_fk
				references country_codes(iso),
	priv_ha			integer,
				-- work address
	wa_line1		text,
	wa_line2		text,
	wa_city			text,
	wa_state		text,
	wa_postal_code		text,
	wa_country_code		char(2)
				constraint users_contact_wa_cc_fk
				references country_codes(iso),
	priv_wa			integer,
				-- used by the intranet module
	note			text,
	current_information	text
);


------------------------------------------------------
-- A unified view on active users (not deleted or banned)
--
create or replace view users_active as 
select
	u.user_id, u.username, u.screen_name, u.last_visit, u.second_to_last_visit, u.n_sessions, u.first_names, u.last_name,
	c.home_phone, c.priv_home_phone, c.work_phone, c.priv_work_phone, c.cell_phone, c.priv_cell_phone, c.pager, c.priv_pager,
	c.fax, c.priv_fax, c.aim_screen_name, c.priv_aim_screen_name, c.msn_screen_name, c.priv_msn_screen_name, c.icq_number,
	c.priv_icq_number, c.m_address, c.ha_line1, c.ha_line2, c.ha_city, c.ha_state, c.ha_postal_code, c.ha_country_code,
	c.priv_ha, c.wa_line1, c.wa_line2, c.wa_city, c.wa_state, c.wa_postal_code, c.wa_country_code, c.priv_wa,
	c.note, c.current_information
from	registered_users u left outer join users_contact c on u.user_id = c.user_id;



-- ToDo: Localize this function for Japanese
--
create or replace function im_name_from_user_id(integer)
returns varchar as $body$
DECLARE
	v_user_id	alias for $1;
	v_full_name	text;
BEGIN
	select first_names || ' ' || last_name into v_full_name 
	from persons
	where person_id = v_user_id;

	return v_full_name;
END;$body$ language 'plpgsql';


create or replace function im_name_from_user_id(int4, int4) returns varchar as $body$
DECLARE
	v_user_id	alias for $1;
	v_name_order	alias for $2;
	v_full_name	varchar(8000);
BEGIN
	IF 2 = v_name_order THEN
		select 	last_name || ' ' || first_names
		into 	v_full_name 
		from 	persons 
		where person_id = v_user_id;
	ELSEIF 3 = v_name_order THEN
		select 	last_name || ', ' || first_names 
		into 	v_full_name 
		from 	persons 
		where person_id = v_user_id;
	ELSE
		select 	first_names || ' ' || last_name 
		into 	v_full_name 
		from 	persons 
		where person_id = v_user_id;
	END IF;
	return v_full_name;
END;$body$ language 'plpgsql';



create or replace function im_email_from_user_id(integer)
returns varchar as $body$
DECLARE
	v_user_id	alias for $1;
	v_email varchar(100);
BEGIN
	select email
	into v_email
	from parties
	where party_id = v_user_id;

	return v_email;
END;$body$ language 'plpgsql';


create or replace function im_initials_from_user_id(integer)
returns varchar as $body$
DECLARE
	v_user_id	alias for $1;
	v_initials	varchar(2);
BEGIN
	select substr(first_names,1,1) || substr(last_name,1,1) into v_initials
	from persons
	where person_id = v_user_id;
	return v_initials;
END;$body$ language 'plpgsql';


-- Shortcut to add a user to a profile (group)
-- Example:
--      im_profile_add_user('Employees', 456)
--
create or replace function im_profile_add_user (varchar, integer)
returns integer as $body$
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
                and rel_type = 'membership_rel';
        IF v_count > 0 THEN RETURN 0; END IF;

        v_rel_id := membership_rel__new(v_group_id, p_grantee_id);

        RETURN v_rel_id;
end;$body$ language 'plpgsql';


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


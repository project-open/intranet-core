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


-- Shortcut to add a user to a profile (group)
-- Example:
--	im_profile_add_user('Employees', 456)
--
create or replace procedure im_profile_add_user (
		p_group_name IN varchar,
		p_grantee_id IN integer
)
IS
	v_group_id	integer;
	v_rel_id	integer;
BEGIN
	-- Get the group_id from group_name
	select group_id
	into v_group_id
	from groups
	where group_name = p_group_name;

	v_rel_id := membership_rel.new(
		object_id_one	=> v_group_id,
		object_id_two	=> p_grantee_id,
		member_state	=> 'approved'
	);
END;
/



------------------------------------------------------------------
prompt Setup a System Administrator
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'system.administrator@project-open.com',
		username => 'sysadmin',
		first_names => 'System',
		last_name => 'Administrator',
		screen_name => 'SysAdmin',
		password => '98A5362F10CA8A081B4363CF10EAF1A40A953BE7',
		salt => '1443DC5C16AEE3B04DD8D110BB069FE13EF1E976',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('P/O Admins',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup a Senior Manager
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'senior.manager@project-open.com',
		username => 'senman',
		first_names => 'Senior',
		last_name => 'Manager',
		screen_name => 'SenMan',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Senior Managers',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup a Project Manager
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'project.manager@project-open.com',
		username => 'proman',
		first_names => 'Project',
		last_name => 'Manager',
		screen_name => 'ProMan',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
	im_profile_add_user('Project Managers',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup Accounting
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'accounting@project-open.com',
		username => 'accounting',
		first_names => 'Ac',
		last_name => 'Counting',
		screen_name => 'Accounting',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
	im_profile_add_user('Accounting',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup an Employee
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'staff.member1@project-open.com',
		username => 'staffmem1',
		first_names => 'Staff',
		last_name => 'Member1',
		screen_name => 'StaffMem1',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup an Employee
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'staff.member2@project-open.com',
		username => 'staffmem2',
		first_names => 'Staff',
		last_name => 'Member2',
		screen_name => 'StaffMem2',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup a Customer Contact
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'customer1@project-open.com',
		username => 'customer1',
		first_names => 'Cus',
		last_name => 'Tomer1',
		screen_name => 'CusTomer1',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Customers',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup a Customer Contact
declare
        v_user_id       integer;
        v_rel_id        integer;
begin
        v_user_id := acs.add_user(
                email => 'customer2@project-open.com',
                username => 'customer2',
                first_names => 'Cus',
                last_name => 'Tomer2',
                screen_name => 'CusTomer2',
                password => '99C7819784E7520CF4E527A2307767B727E476BC',
                salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
                email_verified_p => 't',
                member_state => 'approved'
        );

        im_profile_add_user('Customers',v_user_id);
end;
/



------------------------------------------------------------------
prompt Setup Freelance1
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'free.lance1@project-open.com',
		username => 'freelance1',
		first_names => 'Free',
		last_name => 'Lance1',
		screen_name => 'Freelance1',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Freelancers',v_user_id);
end;
/

------------------------------------------------------------------
prompt Setup Freelance2
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'free.lance2@project-open.com',
		username => 'freelance2',
		first_names => 'Free',
		last_name => 'Lance2',
		screen_name => 'Freelance2',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Freelancers',v_user_id);
end;
/


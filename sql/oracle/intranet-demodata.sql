-- ------------------------------------------------------------
-- /packages/intranet-core/sql/oracle/intranet-population.sql
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

-- Sample Groups
-- 	User Profiles
-- 	Example Offices
-- 	Example Customers
-- Users

-- ------------------------------------------------------------
-- Sample Groups
-- ------------------------------------------------------------

-- Group_IDs:
-- 1	- 5	Administration Groups
-- 6	- 39	User Profiles
-- 40	- 49	Some Offices
-- 50	- 59	Some Customers
-- 60	- 69	Some Projects

-- 150	- 199: Varios
	-- 150: Mataro Office
	-- ...
-- 200	- 699: Projects
	-- 200: MySLS
-- 700	- ...: Not defined yet
--1000	- ...: System groups


create or replace procedure im_add_user_to_profile (
        p_group_name IN varchar,
        p_user_id IN integer) 
IS
        v_rel_id	integer;
        v_group_id	integer;
BEGIN
     -- Get the group_id from group_name
     select group_id
     into v_group_id
     from groups
     where group_name = p_group_name;

     v_rel_id := membership_rel.new(
	object_id_one    => v_group_id,
	object_id_two    => p_user_id,
        member_state     => 'approved'
     );
END;
/


-- ------------------------------------------------------------
-- Sample Users
-- ------------------------------------------------------------

declare
	v_user_id	integer;
	v_rel_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'general.manager@project-open.com',
	username	=> 'genman',	
	first_names	=> 'General',
	last_name	=> 'Manager',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'FAAD01BA850235FA69A6D7FD3C6A7869F1E9C1D7',
        salt		=> 'BA2D636552275B0225F4FB164FB8CA2FEC2A1CCE'
    );

    im_add_user_to_profile('Employees',v_user_id);
    im_add_user_to_profile('Senior Managers',v_user_id);
end;
/



declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'project.manager@project-open.com',
	username	=> 'proman',	
	first_names	=> 'Project',
	last_name	=> 'Manager',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'FAAD01BA850235FA69A6D7FD3C6A7869F1E9C1D7',
        salt		=> 'BA2D636552275B0225F4FB164FB8CA2FEC2A1CCE'
    );

    im_add_user_to_profile('Employees',v_user_id);
    im_add_user_to_profile('Project Managers',v_user_id);
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'staff.member@project-open.com',
	username	=> 'staffmem',	
	first_names	=> 'Staff',
	last_name	=> 'Member',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'FAAD01BA850235FA69A6D7FD3C6A7869F1E9C1D7',
        salt		=> 'BA2D636552275B0225F4FB164FB8CA2FEC2A1CCE'
    );

    im_add_user_to_profile('Employees',v_user_id);
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'accounting@project-open.com',
	username	=> 'accounting',	
	first_names	=> 'Ac',
	last_name	=> 'Counting',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'FAAD01BA850235FA69A6D7FD3C6A7869F1E9C1D7',
        salt		=> 'BA2D636552275B0225F4FB164FB8CA2FEC2A1CCE'
    );
    im_add_user_to_profile('Accounting',v_user_id);
    im_add_user_to_profile('Employees',v_user_id);
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'freeelance.one@project-open.com',
	username	=> 'freeone',	
	first_names	=> 'Freelance',
	last_name	=> 'One',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'FAAD01BA850235FA69A6D7FD3C6A7869F1E9C1D7',
        salt		=> 'BA2D636552275B0225F4FB164FB8CA2FEC2A1CCE'
    );

    im_add_user_to_profile('Freelancers',v_user_id);
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'freelance.two@project-open.com',
	username	=> 'freetwo',	
	first_names	=> 'Freelance',
	last_name	=> 'Two',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'FAAD01BA850235FA69A6D7FD3C6A7869F1E9C1D7',
        salt		=> 'BA2D636552275B0225F4FB164FB8CA2FEC2A1CCE'
    );

    im_add_user_to_profile('Freelancers',v_user_id);
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'client.contact@project-open.com',
	username	=> 'clicon',	
	first_names	=> 'Client',
	last_name	=> 'Contact',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'FAAD01BA850235FA69A6D7FD3C6A7869F1E9C1D7',
        salt		=> 'BA2D636552275B0225F4FB164FB8CA2FEC2A1CCE'
    );

    im_add_user_to_profile('Customers',v_user_id);
end;
/	

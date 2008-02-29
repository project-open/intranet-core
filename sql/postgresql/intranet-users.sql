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
	v_full_name	varchar(8000);
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
	v_initials varchar(2);
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

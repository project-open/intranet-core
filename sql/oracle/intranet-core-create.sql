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
-- Required for im_offices etc. to be able to define
-- a physical location.

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


---------------------------------------------------------
-- Import Business Objects
--

@intranet-offices.sql
@intranet-customers.sql
@intranet-projects.sql


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
-- permissions:
--	Define the im_profile object (just a group), "Privileges" 
--	and a matrix permissions between Profiles ("User Matrix").
--	These structures are queried by application specific 
--	permissions functions such as im_permission, 
--	im_project_permission, ...
--
-- menus:
--	Similar to components: Allows modules ot add their
--	menu entries to the main and submenus
--

@intranet-views.sql
@intranet-components.sql
@intranet-permissions.sql
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



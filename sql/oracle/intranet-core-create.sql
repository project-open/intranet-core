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
prompt *** intranet-categories
@intranet-categories.sql



-------------------------------------------------------------
-- Countries and Currencies
--
-- Required for im_offices etc. to be able to define
-- a physical location.

prompt *** intranet-country-codes
@intranet-country-codes.sql
prompt *** intranet-currency-codes
@intranet-currency-codes.sql


---------------------------------------------------------
-- Load User Data
--
prompt *** intranet-users
@intranet-users.sql


---------------------------------------------------------
-- Import Business Objects
--

prompt *** intranet-biz-objects
@intranet-biz-objects.sql
prompt *** intranet-offices
@intranet-offices.sql
prompt *** intranet-customers
@intranet-customers.sql
prompt *** intranet-projects
@intranet-projects.sql


-- Some helper functions to make our queries easier to read
create or replace function im_category_from_id (p_category_id IN integer)
return varchar
IS
	v_category	varchar(50);
BEGIN
	select category
	into v_category
	from im_categories
	where category_id = p_category_id;

	return v_category;

end im_category_from_id;
/
show errors;


------------------------------------------------------------
-- Check whether user_id is (some kind of) member of group_id.
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
    from acs_rels
    where
	object_id_one = p_group_id
	and object_id_two = p_user_id;

    return ad_group_member_p;

END ad_group_member_p;
/
show errors


------------------------------------------------------------
-- Check whether user_id is an administrator of group_id.
-- ToDo: Hardcoded implementation - replace by privilege
-- scheme that works through all types of business objects.
--
create or replace function ad_group_member_admin_role_p (
    p_user_id IN integer,
    p_group_id IN integer
)
return char
IS
    ad_group_member_p    char(1);
BEGIN
    select decode(count(*), 0, 'f', 't')
    into ad_group_member_p
    from
	acs_rels r,
	im_biz_object_members m,
	im_categories c
    where
	r.object_id_one = p_group_id
	and r.object_id_two = p_user_id
	and r.rel_id = m.rel_id
	and m.object_role_id = c.category_id
	and (c.category = 'Project Manager' or c.category = 'Key Account');

    return ad_group_member_p;

END ad_group_member_admin_role_p;
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

prompt *** intranet-views - Dynamic Views for ListPages
@intranet-views.sql
prompt *** intranet-core-backup - More Views for Reports and Backup
@intranet-core-backup.sql
prompt *** intranet-components - Dynamic Plug-in Components
@intranet-components.sql
prompt *** intranet-permissions - Horizontal and Vertical Permissions
@intranet-permissions.sql
prompt *** intranet-menus - Dynamic menus
@intranet-menus.sql

-- -----------------------------------------------------------
-- Load demo data
---
prompt *** intranet-potransdemo-data - Project/Open Translation Demo Data
@intranet-potransdemo-data.sql




-- -----------------------------------------------------------
-- We base our allocations, employee count, etc. around
-- a fundamental unit or block.
-- im_start_blocks record the dates these blocks
-- will start for this system.

create table im_start_blocks (
	start_block		date not null 
				constraint im_start_blocks_pk
				primary key,
				-- We might want to tag a larger unit
				-- For example, if start_block is the first
				-- Sunday of a week, those tagged with
				-- start_of_larger_unit_p might tag
				-- the first Sunday of a month
	start_of_larger_unit_p	char(1) default 'f'
				constraint im_start_blocks_larger_ck
				check (start_of_larger_unit_p in ('t','f')),
	note			varchar(4000)
);


-- Populate im_start_blocks. Start with Sunday, Jan 7th 1996
-- and end after inserting 550 weeks. Note that 550 is a 
-- completely arbitrary number. 
DECLARE
  v_max 			integer;
  v_i				integer;
  v_first_block_of_month	integer;
  v_next_start_block		date;
BEGIN
  v_max := 550;

  FOR v_i IN 0..v_max-1 LOOP
    -- for convenience, select out the next start block to insert into a variable
    select to_date('1996-01-07','YYYY-MM-DD') + v_i*7 
    into v_next_start_block 
    from dual;

    insert into im_start_blocks
    (start_block) 
    values
    (to_date(v_next_start_block));

    -- set the start_of_larger_unit_p flag if this is the first
    -- start block of the month
    update im_start_blocks
       set start_of_larger_unit_p='t'
     where start_block=to_date(v_next_start_block)
       and not exists (
	select 1 
          from im_start_blocks
         where to_char(start_block,'YYYY-MM') = 
	         to_char(v_next_start_block,'YYYY-MM')
               and start_of_larger_unit_p='t');
  END LOOP;
END;
/
show errors;





-- Create these entries at the very end,
-- because the objects types need to be there first.

insert into im_biz_object_urls (object_type, url_type, url) values (
'user','view','/intranet/users/view?user_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'user','edit','/intranet/users/new?user_id=');

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_project','view','/intranet/projects/view?project_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_project','edit','/intranet/projects/new?project_id=');

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_customer','view','/intranet/customers/view?customer_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_customer','edit','/intranet/customers/new?customer_id=');

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_office','view','/intranet/offices/view?office_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_office','edit','/intranet/offices/new?office_id=');

---
commit;


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
-- major business objects such as project, company,
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
prompt *** intranet-companies
@intranet-companies.sql
prompt *** intranet-projects
@intranet-projects.sql


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
@../common/intranet-core-backup.sql

prompt *** intranet-components - Dynamic Plug-in Components
@intranet-components.sql

prompt *** intranet-permissions - Horizontal and Vertical Permissions
@intranet-permissions.sql

prompt *** intranet-menus - Dynamic menus
@intranet-menus.sql

-- -----------------------------------------------------------
-- Load demo data
---



-- -----------------------------------------------------------
-- We base our financial information, allocations, etc. around
-- a fundamental unit or block.
-- im_start_blocks record the dates these blocks will start for 
-- this system.

create table im_start_weeks (
	start_block		date not null
				constraint im_start_weeks_pk
				primary key,
				-- We might want to tag a larger unit
				-- For example, if start_block is the first
				-- Sunday of a week, those tagged with
				-- start_of_larger_unit_p might tag
				-- the first Sunday of a month
	start_of_larger_unit_p	char(1) default 'f'
				constraint im_start_weeks_larger_ck
				check (start_of_larger_unit_p in ('t','f')),
	note			varchar(4000)
);

create table im_start_months (
        start_block             date not null
                                constraint im_start_months_pk
                                primary key,
                                -- We might want to tag a larger unit
                                -- For example, if start_block is the first
                                -- Sunday of a week, those tagged with
                                -- start_of_larger_unit_p might tag
                                -- the first Sunday of a month
        start_of_larger_unit_p  char(1) default 'f'
                                constraint im_start_months_larger_ck
                                check (start_of_larger_unit_p in ('t','f')),
        note                    varchar(4000)
);



-- Populate im_start_weeks. Start with Sunday, 
-- Jan 7th 1996 and end after inserting 1000 weeks. Note 
-- that 1000 is a completely arbitrary number. 
DECLARE
    v_max 			integer;
    v_i				integer;
    v_first_block_of_month	integer;
    v_next_start_week		date;
BEGIN
    v_max := 1000;

    FOR v_i IN 0..v_max-1 LOOP
	-- for convenience, select out the next start block to insert into a variable
	select to_date('1996-01-07','YYYY-MM-DD') + v_i*7 
	into v_next_start_week 
	from dual;

	insert into im_start_weeks (
		start_block
	) values (
		to_date(v_next_start_week)
	);

	-- set the start_of_larger_unit_p flag if this is the first
	-- start block of the month
	update im_start_weeks
	   set start_of_larger_unit_p='t'
	 where start_block=to_date(v_next_start_week)
	   and not exists (
	select 1 
	      from im_start_weeks
	     where to_char(start_block,'YYYY-MM') = 
	         to_char(v_next_start_week,'YYYY-MM')
	           and start_of_larger_unit_p='t');
    END LOOP;
END;
/
show errors;

-- Populate im_start_months. Start with im_start_weeks
-- dates and check for the beginning of a new month.
BEGIN
    for row in (select unique concat(to_char(start_block, 'YYYY-MM'),'-01') as first_day_in_month
		from im_start_weeks) loop

	insert into im_start_months 
	       (start_block) 
	       values (	to_date(row.first_day_in_month, 'YYYY-MM-DD')	);

     end loop;
END;
/
show errors;


-- /packages/intranet/sql/postgres/intranet-core-create.sql
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
\i intranet-categories.sql



-------------------------------------------------------------
-- Countries and Currencies
--
-- Required for im_offices etc. to be able to define
-- a physical location.

\i intranet-country-codes.sql
\i intranet-currency-codes.sql


---------------------------------------------------------
-- Load User Data
--
\i intranet-users.sql


---------------------------------------------------------
-- Import Business Objects
--

\i intranet-biz-objects.sql
\i intranet-offices.sql
\i intranet-companies.sql
\i intranet-projects.sql


---------------------------------------------------------
-- Extensions to acs-lang

\i intranet-notifications.sql



-- Populate all the status/type/url with the different types of 
-- data we are collecting

create or replace function im_first_letter_default_to_a (varchar) 
returns char as '
DECLARE
	p_string	alias for $1;
	v_initial	char(1);
BEGIN
	v_initial := substr(upper(p_string),1,1);

	IF v_initial IN (
		''A'',''B'',''C'',''D'',''E'',''F'',''G'',''H'',''I'',''J'',''K'',''L'',''M'',
		''N'',''O'',''P'',''Q'',''R'',''S'',''T'',''U'',''V'',''W'',''X'',''Y'',''Z''
	) THEN
	RETURN v_initial;
	END IF;
	
	RETURN ''A'';
end;' language 'plpgsql';

	


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

\i intranet-views.sql
-- \i intranet-core-backup.sql
\i intranet-components.sql
\i intranet-permissions.sql
\i intranet-menus.sql

-- -----------------------------------------------------------
-- Load demo data
---
-- \i intranet-potransdemo-data.sql




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
create or replace function inline_0 ()
returns integer as '
DECLARE
    v_max 			integer;
    v_i				integer;
    v_first_block_of_month	integer;
    v_next_start_week		date;
BEGIN
    v_max := 1000;

    FOR v_i IN 0..v_max-1 LOOP
	-- for convenience, select out the next start block to insert into a variable
	select to_date(''1996-01-07'',''YYYY-MM-DD'') + v_i*7 
	into v_next_start_week 
	from dual;

	insert into im_start_weeks (
		start_block
	) values (
		to_date(v_next_start_week,''YYYY-MM-DD'')
	);

	-- set the start_of_larger_unit_p flag if this is the first
	-- start block of the month
	update im_start_weeks
	   set start_of_larger_unit_p=''t''
	 where start_block=to_date(v_next_start_week,''YYYY-MM-DD'')
	   and not exists (
	select 1 
	      from im_start_weeks
	     where to_char(start_block,''YYYY-MM'') = 
	         to_char(v_next_start_week,''YYYY-MM'')
	           and start_of_larger_unit_p=''t'');
    END LOOP;
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Populate im_start_months. Start with im_start_weeks
-- dates and check for the beginning of a new month.
create or replace function inline_0 ()
returns integer as '
DECLARE
	row RECORD;
BEGIN
    for row in
	select distinct
	       to_char(start_block, ''YYYY-MM'') || ''-01'' as first_day_in_month
        from im_start_weeks
    loop
	insert into im_start_months (
		start_block
	) values (
		to_date(row.first_day_in_month,''YYYY-MM-DD'')
	);
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- create function to add_months
CREATE OR REPLACE FUNCTION add_months(date, int4)
  RETURNS date AS
'
DECLARE 
	p_date_in alias for $1;		-- date_id
	p_months alias for $2;		   -- months to add

	v_date_out     date;
begin
	select p_date_in + "interval"(p_months || '' months'') into v_date_out;
	return v_date_out;
end;'
  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION last_day(date)
  RETURNS date AS
'
DECLARE 
	p_date_in alias for $1;		-- date_id

	v_date_out	date;
begin
	select to_date(date_trunc(''month'',add_months(p_date_in,1)),''YYYY-MM-DD'') - 1 into v_date_out;
	return v_date_out;
end;'
  LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION trunc(date,varchar)
returns date as '
DECLARE 
	p_date_in	alias for $1;	-- date_in
	p_field		alias for $2;	-- field

	v_date_out	date;
BEGIN
	select date_trunc("p_field",p_date_in) into v_date_out;
	return v_date_out;
END;' language 'plpgsql';

create or replace function next_day (date, varchar) returns date as '
declare
	p_date_in alias for $1;		-- date_in
	p_day	  alias for $2;		   -- day

	v_date_out	date;
	value_to_add integer;
	
begin
	if lower(p_day) = ''sunday'' or lower(p_day) = ''sun'' then 
	   value_to_add := 0;
	   else
		if lower(p_day) = ''monday'' or lower(p_day) = ''mon'' then 
		   value_to_add := 1;
		else
		   if lower(p_day) = ''tuesday'' or lower(p_day) = ''tue'' then 
		      value_to_add := 2;
		   else 
		      if lower(p_day) = ''wednesday'' or lower(p_day) = ''wed'' then 
			value_to_add := 3;
		      else
			if lower(p_day) = ''thursday'' or lower(p_day) = ''thu'' then 
			   value_to_add := 4;
			else
			   if lower(p_day) = ''friday'' or lower(p_day) = ''fri'' then 
			      value_to_add := 5;
			   else
			      if lower(p_day) = ''saturday'' or lower(p_day) = ''sat'' then 
			         value_to_add := 6;   
			      end if;
			   end if;
			end if;
		      end if;
		   end if;
	    end if;
	 end if;

	 select p_date_in - date_part(''dow'', p_date_in)::int + value_to_add into v_date_out;
	 return v_date_out;
end;' language 'plpgsql';



-------------------------------------------------------------
-- Function used to enumerate days between stat_date and end_date
-------------------------------------------------------------


create or replace function im_day_enumerator (
	date, date
) returns setof date as '
declare
	p_start_date		alias for $1;
	p_end_date		alias for $2;
	v_date			date;
BEGIN
	v_date := p_start_date;
	WHILE (v_date < p_end_date) LOOP
		RETURN NEXT v_date;
		v_date := v_date + 1;
	END LOOP;
	RETURN;
end;' language 'plpgsql';


create or replace function im_day_enumerator_weekdays (
	date, date
) returns setof date as '
declare
	p_start_date		alias for $1;
	p_end_date		alias for $2;
	v_date			date;
	v_weekday		integer;
BEGIN
	v_date := p_start_date;
	WHILE (v_date < p_end_date) LOOP

		v_weekday := to_char(v_date, ''D'');
		IF v_weekday != 1 AND v_weekday != 7 THEN
			RETURN NEXT v_date;
		END IF;
		v_date := v_date + 1;
	END LOOP;
	RETURN;
end;' language 'plpgsql';


-- Test query
-- select * from im_day_enumerator(now()::date, now()::date + 7);
-- select * from im_day_enumerator_weekdays(now()::date, now()::date + 14);



 
-------------------------------------------------------------
-- Generic function to convert a "reference" into something
-- printable or searchable...
-------------------------------------------------------------

create or replace function im_name_from_id(integer)
returns varchar as '
DECLARE
	v_integer	alias for $1;
        v_result	varchar(4000);
BEGIN
	-- Try with category - probably the fastest
	select category
	into v_result
	from im_categories
	where category_id = v_integer;

	IF v_result is not null THEN return v_result; END IF;

	-- Try with ACS_OBJECT
	select acs_object__name(v_integer)
	into v_result;

        return v_result;
END;' language 'plpgsql';



create or replace function im_name_from_id(varchar)
returns varchar as '
DECLARE
        v_result	alias for $1;
BEGIN
        return v_result;
END;' language 'plpgsql';


create or replace function im_name_from_id(numeric)
returns varchar as '
DECLARE
        v_result	alias for $1;
BEGIN
        return v_result::varchar;
END;' language 'plpgsql';



create or replace function im_name_from_id(timestamptz)
returns varchar as '
DECLARE
        v_timestamp	alias for $1;
BEGIN
        return to_char(v_timestamp, ''YYYY-MM-DD'');
END;' language 'plpgsql';



create or replace function im_integer_from_id(integer)
returns varchar as '
DECLARE
        v_result        alias for $1;
BEGIN
        return v_result::varchar;
END;' language 'plpgsql';



create or replace function im_integer_from_id(varchar)
returns varchar as '
DECLARE
        v_result        alias for $1;
BEGIN
        return v_result;
END;' language 'plpgsql';




create or replace function im_integer_from_id(numeric)
returns varchar as '
DECLARE
        v_result        alias for $1;
BEGIN
        return v_result::varchar;
END;' language 'plpgsql';







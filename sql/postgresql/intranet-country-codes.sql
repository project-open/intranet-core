-- /packages/intranet-core/sql/oracle/intranet-country-codes.sql
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
-- @author	unknown@arsdigita.com
-- @author	frank.bergmann@project-open.com

-- ------------------------------------------------------------
-- Countries
--
-- Previously defined in a ".ctl" file, but we need to have
-- these tables defined _before_ we define im_projects etc.
--
-- This is NOT the list of all available countries. We have
-- included here only large countries, European countries, 
-- English and Spanish speaking countries.


create table country_codes (
	iso		char(2)
			constraint country_codes_pk
			primary key,
	country_name	varchar(150) not null
);



create or replace function im_country_from_code (varchar)
returns varchar as '
DECLARE
        p_cc		alias for $1;
        v_country	varchar;
BEGIN
    select country_name
    into v_country
    from country_codes
    where iso = p_cc;

    return v_country;
END;' language 'plpgsql';



\i ../common/intranet-country-codes.sql


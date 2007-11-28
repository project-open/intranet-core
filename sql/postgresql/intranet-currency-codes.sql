-- /packages/intranet-core/sql/oracle/intranet-currency-codes.sql
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



-- ------------------------------------------------------------
-- Currencies
--
-- Previously defined in a ".ctl" file, but we need to have
-- these tables defined _before_ we define im_projects etc.
--
-- This is NOT the list of all available currencies. We have
-- included here only important currencies
-- Only the currencies with supported_p equal to t will be 
-- shown in the currency widget


create table currency_codes (
	iso		char(3)
			constraint currency_codes_pk
			primary key,
	currency_name	varchar(200) not null,
	supported_p	char(1) default 'f' 
			constraint currency_codes_supported_check
			check (supported_p in ('t','f')),
	symbol		varchar(10),
	rounding_factor	integer default 100
);


\i ../common/intranet-currency-codes.sql


-- /packages/intranet-core/sql/postgres/postgresql84-patch.sql
--
-- Copyright (C) 2011 Frank Bergmann
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
-- @author      frank.bergmann@project-open.com


CREATE OR REPLACE FUNCTION to_date(timestamp with time zone, text) RETURNS date
AS 'select to_date($1::text, $2);' LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION to_date(date, text) RETURNS date
AS 'select to_date($1::text, $2);' LANGUAGE SQL IMMUTABLE;


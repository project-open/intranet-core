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
-- @author	unknown@arsdigita.com
-- @author	frank.bergmann@project-open.com



-- Patch the acs_object_types OpenACS table to add field
create or replace function inline_0 ()
returns integer as $body$
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
        where table_name = 'ACS_OBJECT_TYPES' and column_name = 'TYPE_CATEGORY_TYPE';
        if v_count > 0 then return 0; end if;

        alter table acs_object_types
        add type_category_type char varying(50);

        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-------------------------------------------------------------
-- Main Loader

\i intranet-categories.sql
\i intranet-country-codes.sql
\i intranet-currency-codes.sql
\i intranet-users.sql
\i intranet-biz-objects.sql
\i intranet-offices.sql
\i intranet-companies.sql
\i intranet-projects.sql
\i intranet-notifications.sql
\i intranet-views.sql
\i intranet-permissions.sql
\i intranet-components.sql
\i intranet-menus.sql
\i intranet-defs.sql

-- These patches are only for OpenACS 5.1.
-- \i intranet-openacs-patches.sql


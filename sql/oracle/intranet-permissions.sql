-- /packages/intranet/sql/intranet-permissions.sql
--
-- Project/Open Core Module, fraber@fraber.de, 030828
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- Copyright (C) 1999-2004 ArsDigita, Frank Bergmann and others
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


-------------------------------------------------------------
-- Privileges
--
-- Privileges are permission tokens relative to the "subsite"
-- (package) object "Project/Open Core".
-- 

begin
    acs_privilege.create_privilege('add_customers','Add Customers','Add Customers');
    acs_privilege.create_privilege('view_customers','View Customers','View Customers');
    acs_privilege.create_privilege('view_customers_all','View All Customers','View All Customers');
    acs_privilege.create_privilege('view_customer_contacts','View Customer Contacts','View Customer Contacts');
    acs_privilege.create_privilege('view_customer_details','View Customer Details','View Customer Details');
    acs_privilege.create_privilege('add_projects','Add Projects','Add Projects');
    acs_privilege.create_privilege('view_projects','View Projects','View Projects');
    acs_privilege.create_privilege('view_project_members','View Project Members','View Project Members');
    acs_privilege.create_privilege('view_projects_all','View All Projects','View All Projects');
    acs_privilege.create_privilege('view_projects_history','View Project History','View Project History');
    acs_privilege.create_privilege('add_users','Add Users','Add Users');
    acs_privilege.create_privilege('view_users','View Users','View Users');
    acs_privilege.create_privilege('search_intranet','Search Intranet','Search Intranet');
end;
/

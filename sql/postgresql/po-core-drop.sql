-- /packages/intranet-core/sql/postgres/intranet-core-drop.sql
--
-- Copyright (C) 1999-2004 Project/Open
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
-- @author      frank.bergmann@project-open.com


-- -------------------------------------------------------
-- drop projects

drop table po_projects;

-- -------------------------------------------------------
-- drop companies

drop FUNCTION po_company__new (
        integer,varchar,timestamptz,integer,varchar,integer,
        varchar,varchar,integer,integer,integer,varchar,
        integer,integer,integer,varchar,integer,char(1),varchar,integer
);


drop function po_company__delete (integer);

drop function po_company__name (integer);


-- delete the table and all of its objects
drop table po_companies;

delete from groups where group_id in (select object_id from acs_objects where object_type = 'po_company');

delete from parties where party_id in (select object_id from acs_objects where object_type = 'po_company');

delete from acs_objects where object_type='po_company';

-- drop the object_type
-- acs_object_types__drop_type('po_company');
delete from acs_object_types where object_type='po_company';
delete from acs_object_types where object_type='po_office';
delete from acs_object_types where object_type='po_project';


-- -------------------------------------------------------
-- drop offices

drop table po_offices;



-- -------------------------------------------------------
-- drop the basic infrastructure


drop function po_permission_p (integer,integer,varchar);

drop sequence po_categories_seq;
drop sequence po_dynviews_seq;
drop sequence po_dynview_columns_seq;

drop view po_project_status; 
drop view po_project_types;
drop view po_company_status; 
drop view po_company_types;
drop view po_annual_revenue;

drop table po_category_hierarchy;
drop table po_categories;
drop table country_codes;
drop table currency_codes;
drop table po_dynview_columns;
drop table po_dynviews;



drop function po_category_from_id (integer);


\i po-menu-drop.sql


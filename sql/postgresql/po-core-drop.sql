-- Uninstall file for the data model created by 'po-core-create.sql'
--
-- @author fraber@fraber.de


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


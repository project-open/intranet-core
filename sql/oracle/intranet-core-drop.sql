-- ------------------------------------------------------------
-- /packages/intranet-core/sql/oracle/intranet-drop.yymmdd.sql
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

-----------------------------------------------------------
-- Cleanup Projects
-- Needs to happen _before_ removing permissions etc.
--
begin
     for row in (
        select cons.constraint_id
        from rel_constraints cons, rel_segments segs
        where
                segs.segment_id = cons.required_rel_segment
     ) loop

        rel_segment.del(row.constraint_id);

     end loop;
end;
/
show errors;




-- ------------------------------------------------------------
-- Remove contents to deal with cyclical RIs
-- ------------------------------------------------------------

delete from im_project_url_map;

delete from im_url_types;
delete from im_projects;
delete from im_projects_status_audit;
delete from im_project_status;
delete from im_project_types;

drop index im_project_parent_id_idx;
drop table im_projects_status_audit;

drop table im_project_url_map;
drop table im_url_types;


-- ------------------------------------------------------------
-- Now drop the tables
-- ------------------------------------------------------------

drop view im_project_status;
drop view im_project_types;
drop view im_customer_status;
drop view im_customer_types;
drop view im_partner_status;
drop view im_partner_types;
drop view im_prior_experiences;
drop view im_hiring_sources;
drop view im_job_titles;
drop view im_departments;
drop view im_annual_revenue;





-----------------------------------------------------------
-- Menus
--
-- Menus are a very basic part of the P/O System, but they
-- are very independed wrt the rest of the data model, so
-- we can delete them early.

drop table im_menus;
delete from acs_objects where object_type='im_menu';
drop package im_menu;

delete from acs_objects where object_type='im_menu';
begin
    acs_object_type.drop_type('im_menu');
end;
/
show errors;



-----------------------------------------------------------
-- Permissions 

begin
   im_drop_profile ('P/O Admins');
   im_drop_profile ('Customers'); 
   im_drop_profile ('Offices'); 
   im_drop_profile ('Employees'); 
   im_drop_profile ('Freelancers'); 
   im_drop_profile ('Project Managers'); 
   im_drop_profile ('Senior Managers'); 
   im_drop_profile ('Accounting'); 
end;
/
show errors;

delete from acs_objects where object_type='im_profile';
delete from group_type_rels where group_type = 'im_profile';
drop table im_profiles;
delete from group_types where group_type = 'im_profile';
drop package im_profile;
BEGIN
 acs_object_type.drop_type ('im_profile');
END;
/
show errors;

begin
    acs_privilege.drop_privilege('view');
    acs_privilege.drop_privilege('add_customers');
    acs_privilege.drop_privilege('view_customers');
    acs_privilege.drop_privilege('view_customers_all');
    acs_privilege.drop_privilege('view_customer_contacts');
    acs_privilege.drop_privilege('view_customer_details');
    acs_privilege.drop_privilege('add_projects');
    acs_privilege.drop_privilege('view_projects');
    acs_privilege.drop_privilege('view_project_members');
    acs_privilege.drop_privilege('view_projects_all');
    acs_privilege.drop_privilege('view_projects_history');
    acs_privilege.drop_privilege('add_users');
    acs_privilege.drop_privilege('view_users');
    acs_privilege.drop_privilege('search_intranet');
end;
/
show errors;


-----------------------------------------------------------
-- Components
--
-- Similar to menus - indenpendent of the rest of the DM

drop table im_component_plugins;
delete from acs_objects where object_type='im_component_plugin';
drop package im_component_plugin;

delete from acs_objects where object_type='im_component_plugin';
begin
    acs_object_type.drop_type('im_component_plugin');
end;
/
show errors;

-----------------------------------------------------------
-- Views
drop sequence im_views_seq;
drop sequence im_view_columns_seq;
drop table im_view_columns;
drop table im_views;


-------------------------------------------------------
-- Helper functions
--
drop function im_create_administration_group;
drop function im_category_from_id;
drop function ad_group_member_p;
drop function im_proj_url_from_type;
drop function im_name_from_user_id;
drop function im_email_from_user_id;
drop function im_initials_from_user_id;
drop function im_first_letter_default_to_a;


-------------------------------------------------------
-- Projects
--

-- Drop the "Internal Project"
DECLARE
    v_internal_project_id      integer;
BEGIN
    select project_id
    into v_internal_project_id
    from im_projects
    where project_path = 'internal';

    im_project.del(v_internal_project_id);
END;
/
show errors;


drop package im_project;
drop table im_projects;
drop sequence im_url_types_type_id_seq;

delete from acs_objects where object_type='im_project';
BEGIN
 acs_object_type.drop_type ('im_project');
END;
/
show errors;


-------------------------------------------------------
-- Customers
--

-- Test delete of a know customer
DECLARE
    v_internal_customer_id	integer;
BEGIN
    select customer_id
    into v_internal_customer_id
    from im_customers
    where customer_path = 'internal';

    im_customer.del(v_internal_customer_id);
END;
/
show errors;


-- Remove all possible links to customers from offices
BEGIN
    update im_offices
    set customer_id = null;
END;
/
show errors;


drop package im_customer;
drop table im_customers;

delete from acs_objects where object_type='im_customer';
BEGIN
 acs_object_type.drop_type ('im_customer');
END;
/
show errors;


-------------------------------------------------------
-- Offices
--
drop package im_office;
drop table im_offices;

delete from acs_objects where object_type='im_office';
BEGIN
 acs_object_type.drop_type ('im_office');
END;
/
show errors;



-------------------------------------------------------
-- P/O Business Objects

drop table im_member_rels;
drop package im_member_rel;

drop table im_biz_object_role_map;
drop table im_biz_object_members;
drop package im_biz_object;
drop table im_biz_objects;
delete from acs_objects where object_type='im_biz_object';

drop table im_biz_object_roles;

BEGIN
 acs_object_type.drop_type ('im_biz_object');
 acs_object_type.drop_type ('im_member_rel');
END;
/
show errors;


-----------------------------------------------------------
-- Permissions 

begin
   im_drop_profile ('P/O Admins');
   im_drop_profile ('Customers'); 
   im_drop_profile ('Offices'); 
   im_drop_profile ('Employees'); 
   im_drop_profile ('Freelancers'); 
   im_drop_profile ('Project Managers'); 
   im_drop_profile ('Senior Managers'); 
   im_drop_profile ('Accounting'); 
end;
/
show errors;


-------------------------------------------------------
-- Users
drop table users_contact;


-------------------------------------------------------
-- Country & Currency Codes
drop table country_codes;
drop table currency_codes;


-------------------------------------------------------
-- Categories
--
drop sequence categories_seq;
drop table category_hierarchy;
drop table categories;





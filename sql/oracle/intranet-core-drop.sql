-- ------------------------------------------------------------
-- intranet-drop.yymmdd.sql
-- 25.6.2003, Frank Bergmann <fraber@fraber.de>
-- ------------------------------------------------------------

-----------------------------------------------------------
-- Views

drop sequence im_views_seq;
drop sequence im_view_columns_seq;
drop table im_view_columns;
drop table im_views;


-----------------------------------------------------------
-- Menus
--
-- Menus are a very basic part of the P/O System, but they
-- are very independed wrt the rest of the data model, so
-- we can delete them early.

drop table im_menus;
delete from acs_objects where object_type='im_menu';
drop package im_menu;
begin
    acs_object_type.drop_type('im_menu');
end;
/



-----------------------------------------------------------
-- Component Plugins
--
-- Similar to menus - indenpendent of the rest of the DM

drop table im_component_plugins;
delete from acs_objects where object_type='im_component_plugin';
drop package im_component_plugin;
begin
    acs_object_type.drop_type('im_component_plugin');
end;
/



-- ------------------------------------------------------------
-- Remove contents to deal with cyclical RIs
-- ------------------------------------------------------------

delete from im_partners;
delete from im_partner_types;

delete from im_project_url_map;

delete from im_url_types;
delete from im_projects;
delete from im_projects_status_audit;
delete from im_project_status;
delete from im_project_types;

delete from im_customers;
delete from im_customer_status;

delete from im_offices;
delete from im_facilities;


drop table im_offices;
drop table im_partners;


drop index im_project_parent_id_idx;
drop table im_projects_status_audit;

drop table im_project_url_map;
drop table im_url_types;

drop table users_contact;


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

drop function im_category_from_id;
drop function im_proj_url_from_type;
drop function im_name_from_user_id;

drop function im_first_letter_default_to_a;

drop table im_projects;
drop table im_customers;
drop table im_facilities;

drop sequence im_url_types_type_id_seq;

-------------------------------------------------------

drop sequence categories_seq;
drop table category_hierarchy;
drop table categories;

-------------------------------------------------------

drop table country_codes;
drop table currency_codes;



-----------------------------------------------------------
-- Privileges

begin
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


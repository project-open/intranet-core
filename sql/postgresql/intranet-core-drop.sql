-- /packages/intranet-core/sql/oracle/intranet-core-drop.sql
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
create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
    for row in
        select cons.constraint_id
        from rel_constraints cons, rel_segments segs
        where
                segs.segment_id = cons.required_rel_segment
    loop

        rel_segment__delete(row.constraint_id);

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- ------------------------------------------------------------
-- Cleanup users
-- ------------------------------------------------------------
create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
    for row in
        select party_id
        from parties
        where email like ''%project-open.com''
    loop

        acs.remove_user(row.party_id);

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- ------------------------------------------------------------
-- Remove contents to deal with cyclical RIs
-- ------------------------------------------------------------

delete from im_project_url_map;

delete from im_url_types;
delete from im_projects;
--delete from im_project_status; (this is a view, cannot delete)
delete from im_biz_object_role_map;
delete from im_biz_object_urls;
--delete from im_project_types; (this is a view, cannot delete)

drop table im_project_url_map;
drop table im_url_types;


-- ------------------------------------------------------------
-- Now drop the tables
-- ------------------------------------------------------------

drop view im_project_status;
drop view im_project_types;
drop view im_company_status;
drop view im_company_types;
drop view im_partner_status;
drop view im_partner_types;
--drop view im_prior_experiences;
--drop view im_hiring_sources;
--drop view im_job_titles;
--drop view im_departments;
drop view im_annual_revenue;




-----------------------------------------------------------
-- Auxil tables
drop table im_start_weeks;
drop table im_start_months;


-----------------------------------------------------------
-- Menus
--
-- Menus are a very basic part of the P/O System, but they
-- are very independed wrt the rest of the data model, so
-- we can delete them early.

drop table im_menus;
delete from acs_permissions 
where object_id in (
		select object_id 
		from acs_objects 
		where object_type='im_menu'
	)
;
delete from acs_objects where object_type='im_menu';
-- drop package im_menu;

select acs_object_type__drop_type('im_menu', 'f');


-----------------------------------------------------------
-- Permissions 

select im_drop_profile ('P/O Admins');
select im_drop_profile ('Companies'); 
select im_drop_profile ('Employees'); 
select im_drop_profile ('Freelancers'); 
select im_drop_profile ('Project Managers'); 
select im_drop_profile ('Senior Managers'); 
select im_drop_profile ('Accounting'); 

create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
     for row in 
        select profile_id
	from im_profiles
     loop
	PERFORM im_profile__delete(row.profile_id);
     end loop;
     return 0;
END;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


delete from composition_rels where rel_id in (
	select rel_id from acs_rels where object_id_two in (
		select object_id from acs_objects where object_type='im_profile'
	)
);
delete from composition_rels where rel_id in (
	select rel_id from acs_rels where object_id_one in (
		select object_id from acs_objects where object_type='im_profile'
	)
);
delete from acs_rels where object_id_two in (
	select object_id from acs_objects where object_type='im_profile'
);
delete from acs_rels where object_id_one in (
	select object_id from acs_objects where object_type='im_profile'
);
delete from acs_permissions where grantee_id in (
	select object_id from acs_objects where object_type = 'im_profile'
);
delete from group_element_index where element_id in (
	select object_id from acs_objects where object_type='im_profile'
);
delete from groups where group_id in (
	select object_id from acs_objects where object_type='im_profile'
);
delete from parties where party_id in (
	select object_id from acs_objects where object_type='im_profile'
);

delete from group_type_rels where group_type = 'im_profile';
drop table im_profiles;
delete from acs_objects where object_type = 'im_profile';

delete from group_types where group_type = 'im_profile';
-- drop package im_profile;
select  acs_object_type__drop_type ('im_profile', 'f');


-- before remove priviliges remove granted permissions
create or replace function inline_revoke_permission (varchar)
returns integer as '
DECLARE
	p_priv_name	alias for $1;
BEGIN
     lock table acs_permissions_lock;

     delete from acs_permissions
     where privilege = p_priv_name;

     return 0;

end;' language 'plpgsql';




select acs_privilege__remove_child('admin', 'view');
select acs_privilege__remove_child('admin', 'add_companies');
select acs_privilege__remove_child('admin', 'view_companies');
select acs_privilege__remove_child('admin', 'view_companies_all');
select acs_privilege__remove_child('admin', 'edit_companies_all');
select acs_privilege__remove_child('admin', 'view_company_contacts');
select acs_privilege__remove_child('admin', 'view_company_details');
select acs_privilege__remove_child('admin', 'view_offices');
select acs_privilege__remove_child('admin', 'view_offices_all');
select acs_privilege__remove_child('admin', 'add_offices');
select acs_privilege__remove_child('admin', 'view_internal_offices');
select acs_privilege__remove_child('admin', 'edit_internal_offices');
select acs_privilege__remove_child('admin', 'add_projects');
select acs_privilege__remove_child('admin', 'view_project_members');
select acs_privilege__remove_child('admin', 'view_projects_all');
select acs_privilege__remove_child('admin', 'view_projects_history');
select acs_privilege__remove_child('admin', 'add_users');
select acs_privilege__remove_child('admin', 'view_users');
select acs_privilege__remove_child('admin', 'view_user_regs');
select acs_privilege__remove_child('admin', 'search_intranet');
select acs_privilege__remove_child('admin', 'admin_categories');
select acs_privilege__remove_child('admin', 'view_topics');


select inline_revoke_permission ('add_companies');
select inline_revoke_permission ('view_companies');
select inline_revoke_permission ('view_companies_all');
select inline_revoke_permission ('view_company_contacts');
select inline_revoke_permission ('view_company_details');
select inline_revoke_permission ('add_projects');
select inline_revoke_permission ('view_projects');
select inline_revoke_permission ('view_project_members');
select inline_revoke_permission ('view_projects_all');
select inline_revoke_permission ('view_projects_history');
select inline_revoke_permission ('add_users');
select inline_revoke_permission ('view_users');
select inline_revoke_permission ('search_intranet');
select inline_revoke_permission ('view_offices');
select inline_revoke_permission ('view_offices_all');
select inline_revoke_permission ('add_offices');
select inline_revoke_permission ('view_internal_offices');
select inline_revoke_permission ('edit_internal_offices');
select inline_revoke_permission ('view_user_regs');
select inline_revoke_permission ('admin_categories');
select inline_revoke_permission ('view_topics');

select inline_revoke_permission ('view');

drop function inline_revoke_permission (varchar);

-- remove privileges
select acs_privilege__drop_privilege('add_companies');
select acs_privilege__drop_privilege('view_companies');
select acs_privilege__drop_privilege('view_companies_all');
select acs_privilege__drop_privilege('view_company_contacts');
select acs_privilege__drop_privilege('view_company_details');
select acs_privilege__drop_privilege('add_projects');
select acs_privilege__drop_privilege('view_projects');
select acs_privilege__drop_privilege('view_project_members');
select acs_privilege__drop_privilege('view_projects_all');
select acs_privilege__drop_privilege('view_projects_history');
select acs_privilege__drop_privilege('add_users');
select acs_privilege__drop_privilege('view_users');
select acs_privilege__drop_privilege('search_intranet');
select acs_privilege__drop_privilege('view_offices');
select acs_privilege__drop_privilege('view_offices_all');
select acs_privilege__drop_privilege('add_offices');
select acs_privilege__drop_privilege('view_internal_offices');
select acs_privilege__drop_privilege('edit_internal_offices');
select acs_privilege__drop_privilege('view_user_regs');
select acs_privilege__drop_privilege('admin_categories');
select acs_privilege__drop_privilege('view_topics');

select acs_privilege__drop_privilege('view');



-----------------------------------------------------------
-- Components
--
-- Similar to menus - indenpendent of the rest of the DM

drop table im_component_plugins;
delete from acs_objects where object_type='im_component_plugin';
-- drop package im_component_plugin;

delete from acs_objects where object_type='im_component_plugin';
select acs_object_type__drop_type('im_component_plugin', 'f');


-----------------------------------------------------------
-- Views
drop sequence im_views_seq;
drop sequence im_view_columns_seq;
drop table im_view_columns;
drop table im_views;


-------------------------------------------------------
-- Helper functions
--
--drop function im_create_administration_group;
--drop function im_category_from_id;
--drop function ad_group_member_p;
--drop function im_proj_url_from_type;
--drop function im_name_from_user_id;
--drop function im_email_from_user_id;
--drop function im_initials_from_user_id;
--drop function im_first_letter_default_to_a;


-------------------------------------------------------
-- Projects
--

create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
    for row in
        select project_id
        from im_projects
    loop
        im_project__delete(row.project_id);
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- drop package im_project;

-- Do not drop triggers because they are deleted 
-- together with their table when it is dropped.
--
-- drop trigger im_projects_update_tr on im_projects;
-- drop trigger im_project_insert_tr on im_projects;
-- drop function im_projects_update_tr ();
-- drop function im_project_insert_tr ();

drop table im_projects;
drop sequence im_url_types_type_id_seq;

delete from acs_objects where object_type='im_project';
select acs_object_type__drop_type ('im_project', 'f');



-------------------------------------------------------
-- Companies
--

create or replace function inline_0 ()
returns integer as '
DECLARE
        row RECORD;
BEGIN
    for row in
        select company_id
        from im_companies
    loop
        im_company__delete(row.company_id);
    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Remove all possible links to companies from offices
update im_offices set company_id = null;


-- drop package im_company;
drop table im_companies;

delete from acs_objects where object_type='im_company';
select acs_object_type__drop_type ('im_company', 'f');


-------------------------------------------------------
-- Offices
--
-- drop package im_office;
drop table im_offices;

delete from acs_objects where object_type='im_office';
select acs_object_type__drop_type ('im_office', 'f');

-------------------------------------------------------
-- P/O Business Objects

select acs_rel_type__drop_type('im_biz_object_member', 'f');

-- drop table im_member_rels;
-- drop package im_member_rel;

drop table im_biz_object_urls;
drop table im_biz_object_role_map;
drop table im_biz_object_members;
-- drop package im_biz_object;
drop table im_biz_objects;
delete from acs_objects where object_type='im_biz_object';

-- drop table im_biz_object_roles;

select acs_object_type__drop_type ('im_biz_object', 'f');
select acs_object_type__drop_type ('im_member_rel', 'f');



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
drop sequence im_categories_seq;
drop table im_category_hierarchy;
drop view im_office_types;
drop view im_office_status;
drop view im_biz_object_role;
drop table im_categories;


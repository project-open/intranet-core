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
commit;


-- ------------------------------------------------------------
-- Cleanup users
-- ------------------------------------------------------------
begin
     for row in (
        select party_id
        from parties
        where email like '%project-open.com'
     ) loop

        acs.remove_user(row.party_id);

     end loop;
end;
/
commit;



-- ------------------------------------------------------------
-- Remove contents to deal with cyclical RIs
-- ------------------------------------------------------------

delete from im_project_url_map;

delete from im_url_types;
delete from im_projects;
delete from im_projects_status_audit;
delete from im_project_status;
delete from im_biz_object_role_map;
delete from im_biz_object_urls;
delete from im_project_types;

drop table im_projects_status_audit;
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
drop package im_menu;
begin
    acs_object_type.drop_type('im_menu');
end;
/
commit;



-----------------------------------------------------------
-- Permissions 

begin
   im_drop_profile ('P/O Admins');
   im_drop_profile ('Companies'); 
   im_drop_profile ('Employees'); 
   im_drop_profile ('Freelancers'); 
   im_drop_profile ('Project Managers'); 
   im_drop_profile ('Senior Managers'); 
   im_drop_profile ('Accounting'); 
end;
/

begin
     for row in (
        select profile_id
	from im_profiles
     ) loop
	im_profile.del(row.profile_id);
     end loop;
end;
/

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
drop package im_profile;
BEGIN
 acs_object_type.drop_type ('im_profile');
END;
/
commit;



begin
    acs_privilege.drop_privilege('add_companies');
    acs_privilege.drop_privilege('view_companies');
    acs_privilege.drop_privilege('view_companies_all');
    acs_privilege.drop_privilege('view_company_contacts');
    acs_privilege.drop_privilege('view_company_details');
    acs_privilege.drop_privilege('add_projects');
    acs_privilege.drop_privilege('view_projects');
    acs_privilege.drop_privilege('view_project_members');
    acs_privilege.drop_privilege('view_projects_all');
    acs_privilege.drop_privilege('view_projects_history');
    acs_privilege.drop_privilege('add_users');
    acs_privilege.drop_privilege('view_users');
    acs_privilege.drop_privilege('view_user_regs');
    acs_privilege.drop_privilege('search_intranet');
    acs_privilege.drop_privilege('admin_categories');
    acs_privilege.drop_privilege('view_topics');
    acs_privilege.drop_privilege('view_internal_offices');
    acs_privilege.drop_privilege('edit_internal_offices');
    acs_privilege.drop_privilege('view_offices');
    acs_privilege.drop_privilege('view_offices_all');
    acs_privilege.drop_privilege('add_offices');

end;
/
commit;


begin
     acs_privilege.remove_child('admin', 'view');
    acs_privilege.drop_privilege('view');
end;
/



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
commit;

-----------------------------------------------------------
-- Views
drop sequence im_views_seq;
drop sequence im_view_columns_seq;
drop table im_view_columns;
drop table im_views;


-------------------------------------------------------
-- Helper functions
--
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


begin
     for row in (
        select project_id
        from im_projects
     ) loop
        im_project.del(row.project_id);
     end loop;
end;
/


drop package im_project;
drop table im_projects;
drop sequence im_url_types_type_id_seq;

delete from acs_objects where object_type='im_project';
BEGIN
 acs_object_type.drop_type ('im_project');
END;
/
commit;


-------------------------------------------------------
-- Companies
--

begin
     for row in (
        select company_id
        from im_companies
     ) loop
        im_company.del(row.company_id);
     end loop;
end;
/
commit;

-- Remove all possible links to companies from offices
BEGIN
    update im_offices
    set company_id = null;
END;
/
commit;


drop package im_company;
drop table im_companies;

delete from acs_objects where object_type='im_company';
BEGIN
 acs_object_type.drop_type ('im_company');
END;
/
commit;


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
commit;



-------------------------------------------------------
-- P/O Business Objects

BEGIN
    acs_rel_type.drop_type('im_biz_object_member');
END;
/


drop table im_biz_object_urls;
drop table im_biz_object_role_map;
drop table im_biz_object_members;
drop package im_biz_object;
drop table im_biz_objects;
delete from acs_objects where object_type='im_biz_object';


BEGIN
 acs_object_type.drop_type ('im_biz_object');
 acs_object_type.drop_type ('im_member_rel');
END;
/
commit;


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
drop table im_categories;





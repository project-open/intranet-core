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
-- Profiles
--
-- Profiles are just regular groups that are used to define
-- user permissions using the intranet-core object.

begin
   im_create_intranet_group ('P/O Admins');
   im_create_intranet_group ('Customers'); 
   im_create_intranet_group ('Offices'); 
   im_create_intranet_group ('Employees'); 
   im_create_intranet_group ('Freelancers'); 
   im_create_intranet_group ('Project Managers'); 
   im_create_intranet_group ('Senior Managers'); 
   im_create_intranet_group ('Accounting'); 
end;
/
show errors;

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


-------------------------------------------------------------
-- Privileges Setup
--
-- Setup an initial privilege matrix

-- Shortcut proc to setup loads of privileges.
--
create or replace procedure im_priv_create (
	p_priv_name IN varchar,
        p_profile_name IN varchar
)
IS
  v_profile_id		integer;
  v_object_id		integer;
BEGIN
     -- Get the group_id from group_name
     select group_id 
     into v_profile_id
     from groups
     where group_name = p_profile_name;

     -- Get the context_id (package_id)
     select package_id 
     into v_object_id
     from apm_packages
     where package_key = 'intranet-core';

     -- shortcut: 400 works ... 
     v_object_id := 400;

     acs_permission.grant_permission(v_object_id, v_profile_id, p_priv_name);
END;
/
show errors;

BEGIN
    im_priv_create('view_projects', 'Employees');
    im_priv_create('view_project_members', 'Employees');
    im_priv_create('view_projects_all', 'Employees');
    im_priv_create('view_projects_history', 'Employees');
    im_priv_create('add_projects', 'Employees');
    im_priv_create('search_intranet', 'Employees');
    im_priv_create('view_users', 'Employees');
END;
/
show errors;


-- Shortcut proc define subgroup behaviour
--
create or replace procedure im_subgroup_create (
        p_parent_name IN varchar,
        p_subgroup_name IN varchar
)
IS
	v_rel_id		integer;
	v_system_user_id	integer;
	v_parent_id		integer;
	v_subgroup_id		integer;
BEGIN
     -- Get the group_id from group_name
     select group_id
     into v_parent_id
     from groups
     where group_name = p_parent_name;

     -- Get the subgroup
     select group_id
     into v_subgroup_id
     from groups
     where group_name = p_subgroup_name;

        v_system_user_id := 0;
        v_rel_id := composition_rel.new(
                object_id_one    => v_parent_id,
                object_id_two    => v_subgroup_id,
                creation_user    => v_system_user_id,
                creation_ip      => '0:0:0:0'
         );
END;
/
show errors;


BEGIN
--	im_subgroup_create('Project Managers', 'Employees');

    im_priv_create('view_customers', 'Project Managers');
    im_priv_create('view_projects', 'Project Managers');
    im_priv_create('view_project_members', 'Project Managers');
    im_priv_create('view_projects_all', 'Project Managers');
    im_priv_create('view_projects_history', 'Project Managers');
    im_priv_create('add_projects', 'Project Managers');
    im_priv_create('search_intranet', 'Project Managers');
    im_priv_create('view_users', 'Project Managers');
    im_priv_create('add_users', 'Project Managers');

    im_priv_create('view_customers', 'Senior Managers');
    im_priv_create('view_customer_contacts', 'Senior Managers');
    im_priv_create('view_customer_details', 'Senior Managers');
    im_priv_create('view_customer_all', 'Senior Managers');
    im_priv_create('add_customers', 'Senior Managers');
    im_priv_create('view_projects', 'Senior Managers');
    im_priv_create('view_project_members', 'Senior Managers');
    im_priv_create('view_projects_all', 'Senior Managers');
    im_priv_create('view_projects_history', 'Senior Managers');
    im_priv_create('add_projects', 'Senior Managers');
    im_priv_create('search_intranet', 'Senior Managers');
    im_priv_create('view_users', 'Senior Managers');
    im_priv_create('add_users', 'Senior Managers');

END;
/
commit;

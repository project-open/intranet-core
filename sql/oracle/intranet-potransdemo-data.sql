-- /packages/intranet-core/sql/oracle/intranet-potransemo-data.sql
--
-- Copyright (C) 2003-2004 Project/Open
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



-- ----------------------------------------------------------------
prompt Setup a System Administrator
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'system.administrator@project-open.com',
		username => 'sysadmin',
		first_names => 'System',
		last_name => 'Administrator',
		screen_name => 'SysAdmin',
		password => '98A5362F10CA8A081B4363CF10EAF1A40A953BE7',
		salt => '1443DC5C16AEE3B04DD8D110BB069FE13EF1E976',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('P/O Admins',v_user_id);

	-- make SitewideAdmin 
	acs_permission.grant_permission (
        	object_id => -4,
        	grantee_id => v_user_id,
                privilege => 'admin'
	);
end;
/


------------------------------------------------------------------
prompt Setup a Senior Manager
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'senior.manager@project-open.com',
		username => 'senman',
		first_names => 'Senior',
		last_name => 'Manager',
		screen_name => 'SenMan',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Senior Managers',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup a Project Manager
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'project.manager@project-open.com',
		username => 'proman',
		first_names => 'Project',
		last_name => 'Manager',
		screen_name => 'ProMan',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
	im_profile_add_user('Project Managers',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup Accounting
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'accounting@project-open.com',
		username => 'accounting',
		first_names => 'Ac',
		last_name => 'Counting',
		screen_name => 'Accounting',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
	im_profile_add_user('Accounting',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup an Employee
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'staff.member1@project-open.com',
		username => 'staffmem1',
		first_names => 'Staff',
		last_name => 'Member1',
		screen_name => 'StaffMem1',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup an Employee
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'staff.member2@project-open.com',
		username => 'staffmem2',
		first_names => 'Staff',
		last_name => 'Member2',
		screen_name => 'StaffMem2',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Employees',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup a Customer Contact
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'customer1@project-open.com',
		username => 'customer1',
		first_names => 'Cus',
		last_name => 'Tomer1',
		screen_name => 'CusTomer1',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Customers',v_user_id);
end;
/


------------------------------------------------------------------
prompt Setup a Customer Contact
declare
        v_user_id       integer;
        v_rel_id        integer;
begin
        v_user_id := acs.add_user(
                email => 'customer2@project-open.com',
                username => 'customer2',
                first_names => 'Cus',
                last_name => 'Tomer2',
                screen_name => 'CusTomer2',
                password => '99C7819784E7520CF4E527A2307767B727E476BC',
                salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
                email_verified_p => 't',
                member_state => 'approved'
        );

        im_profile_add_user('Customers',v_user_id);
end;
/



------------------------------------------------------------------
prompt Setup Freelance1
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'free.lance1@project-open.com',
		username => 'freelance1',
		first_names => 'Free',
		last_name => 'Lance1',
		screen_name => 'Freelance1',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Freelancers',v_user_id);
end;
/

------------------------------------------------------------------
prompt Setup Freelance2
declare
	v_user_id	integer;
	v_rel_id	integer;
begin
	v_user_id := acs.add_user(
		email => 'free.lance2@project-open.com',
		username => 'freelance2',
		first_names => 'Free',
		last_name => 'Lance2',
		screen_name => 'Freelance2',
		password => '99C7819784E7520CF4E527A2307767B727E476BC',
		salt => '2CD5F36548084E5B22B1597643B05B16BD4C3B4F',
		email_verified_p => 't',
		member_state => 'approved'
	);

	im_profile_add_user('Freelancers',v_user_id);
end;
/


-- Create an "internal" project implementing P/O
declare
	v_project_id		integer;
	v_internal_customer_id	integer;
	v_rel_id		integer;
	v_user_id		integer;
begin
	select customer_id
	into v_internal_customer_id
	from im_customers
	where customer_path = 'internal';

	v_project_id := im_project.new(
		object_type	=> 'im_project',
		project_name	=> 'Project/Open Installation',
		project_nr	=> 'po_install',
		project_path	=> 'po_install',
		customer_id	=> v_internal_customer_id
	);

	-- Add some users
	-- 1300 is full member, 1301 is PM, 1302 is Key Account
	select party_id	into v_user_id
	from parties where email='project.manager@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1301
	);

	select party_id	into v_user_id
	from parties where email='staff.member1@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='system.administrator@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='senior.manager@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);

	select party_id	into v_user_id
	from parties where email='free.lance1@project-open.com';
	v_rel_id := im_biz_object_member.new (
        	object_id       => v_project_id,
        	user_id         => v_user_id,
        	object_role_id  => 1300
	);
end;
/
commit;


-- Create the default User Matrix, defining the rights of
-- one user group to read, write or admin other user groups
BEGIN
    -- Customers (more precise: customer contacts) have no
    -- permissions to see anybody else...

    -- Freelancers have no permissions to see anybody else

    -- Employees are allowed to administer freelancers
    -- and to read other Employees (read names, emails, ...)
    im_user_matrix_grant('Freelancers','Employees','admin');
    im_user_matrix_grant('P/O Admins','Employees','read');
    im_user_matrix_grant('Senior Managers','Employees','read');
    im_user_matrix_grant('Project Managers','Employees','read');
    im_user_matrix_grant('Accounting','Employees','read');
    im_user_matrix_grant('Employees','Employees','read');
    im_user_matrix_grant('Sales','Employees','read');


    -- Project Managers in our sample company are similar to 
    -- Employees (not very privileged).
    im_user_matrix_grant('Freelancers','Project Managers','admin');

    im_user_matrix_grant('P/O Admins','Project Managers','read');
    im_user_matrix_grant('Senior Managers','Project Managers','read');
    im_user_matrix_grant('Project Managers','Project Managers','read');
    im_user_matrix_grant('Accounting','Project Managers','read');
    im_user_matrix_grant('Employees','Project Managers','read');
    im_user_matrix_grant('Sales','Project Managers','read');


    -- Senior Managers can administer all groups, regardless
    -- of their area (may have to be revised in larger orgs.).
    im_user_matrix_grant('Freelancers','Senior Managers','admin');
    im_user_matrix_grant('Employees','Senior Managers','admin');
    im_user_matrix_grant('Project Managers','Senior Managers','admin');
    im_user_matrix_grant('Customers','Senior Managers','admin');
    im_user_matrix_grant('Senior Managers','Senior Managers','read');


    -- Accounting are like Employees, but can see customers
    im_user_matrix_grant('P/O Admins','Accounting','read');
    im_user_matrix_grant('Senior Managers','Accounting','read');
    im_user_matrix_grant('Project Managers','Accounting','read');
    im_user_matrix_grant('Accounting','Accounting','read');
    im_user_matrix_grant('Employees','Accounting','read');
    im_user_matrix_grant('Sales','Accounting','read');
    im_user_matrix_grant('Freelancers','Accounting','read');
    im_user_matrix_grant('Customers','Accounting','read');


    -- Sales are like Employees, but can see customers. No Freelancers
    im_user_matrix_grant('P/O Admins','Sales','read');
    im_user_matrix_grant('Senior Managers','Sales','read');
    im_user_matrix_grant('Project Managers','Sales','read');
    im_user_matrix_grant('Accounting','Sales','read');
    im_user_matrix_grant('Employees','Sales','read');
    im_user_matrix_grant('Sales','Sales','read');
    im_user_matrix_grant('Customers','Sales','read');


    -- P/O Admins can administer all groups.
    im_user_matrix_grant('Freelancers','P/O Admins','admin');
    im_user_matrix_grant('Employees','P/O Admins','admin');
    im_user_matrix_grant('Project Managers','P/O Admins','admin');
    im_user_matrix_grant('Customers','P/O Admins','admin');
    im_user_matrix_grant('Senior Managers','P/O Admins','admin');
    im_user_matrix_grant('P/O Admins','P/O Admins','admin');
    im_user_matrix_grant('Sales','P/O Admins','admin');
    im_user_matrix_grant('Accounting','P/O Admins','admin');
END;
/
commit;


-- Instant satisfaction of the "masters of the universe"... :-)
-- Add all site-wide administrators as P/O-Admins and Employees.

declare
	v_poadmin_id	integer;
	v_employee_id	integer;
begin
	select group_id
	into v_poadmin_id
	from groups
	where group_name = 'P/O Admins';

	select group_id
	into v_employee_id
	from groups
	where group_name = 'Employees';

    for row in (
        select grantee_id
	from acs_permissions
        where 	object_id = -4
		and grantee_id not in (
			select member_id
			from group_member_map
			where group_id = v_poadmin_id
		)
     ) loop
	im_profile_add_user('P/O Admins',row.grantee_id);
     end loop;

    for row in (
        select grantee_id
	from acs_permissions
        where 	object_id = -4
		and grantee_id not in (
			select member_id
			from group_member_map
			where group_id = v_employee_id
		)
     ) loop
	im_profile_add_user('Employees',row.grantee_id);
     end loop;
end;
/
commit;





prompt Initializing Employees Permissions
BEGIN
    im_priv_create('view_project_members', 	'Employees');
END;
/

BEGIN
    im_priv_create('view_projects_all', 	'Employees');
END;
/

BEGIN
    im_priv_create('view_projects_history', 	'Employees');
END;
/

BEGIN
    im_priv_create('add_projects', 		'Employees');
END;
/

BEGIN
    im_priv_create('search_intranet', 		'Employees');
END;
/

BEGIN
    im_priv_create('view_users', 		'Employees');
END;
/

BEGIN
    im_priv_create('add_users', 		'Employees');
END;
/

BEGIN
    im_priv_create('read_private_data', 	'Employees');
END;
/

BEGIN
    im_priv_create('view_internal_offices', 	'Employees');
END;
/

prompt Initializing Project Managers Permissions
BEGIN
    im_priv_create('view_project_members', 	'Project Managers');
END;
/

BEGIN
    im_priv_create('view_projects_all', 	'Project Managers');
END;
/

BEGIN
    im_priv_create('view_projects_history', 	'Project Managers');
END;
/

BEGIN
    im_priv_create('add_projects', 		'Project Managers');
END;
/

BEGIN
    im_priv_create('search_intranet', 		'Project Managers');
END;
/

BEGIN
    im_priv_create('view_users', 		'Project Managers');
END;
/

BEGIN
    im_priv_create('add_users', 		'Project Managers');
END;
/

BEGIN
    im_priv_create('read_private_data', 	'Project Managers');
END;
/

BEGIN
    im_priv_create('view_internal_offices', 	'Project Managers');
END;
/


prompt Initializing Senior Managers Permissions
BEGIN
    im_priv_create('view_customers', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_customer_contacts', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_customer_details', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_customers_all', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('add_customers', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_project_members', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_projects_all', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_projects_history', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('add_projects', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('search_intranet', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_users', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('add_users', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_invoices', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_payments', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_costs', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('add_invoices', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('add_payments', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('add_costs', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('add_offices', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('admin_categories', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('edit_internal_offices',	'Senior Managers');
END;
/

BEGIN
    im_priv_create('read_private_data', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_internal_offices', 	'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_offices', 		'Senior Managers');
END;
/

BEGIN
    im_priv_create('view_offices_all', 		'Senior Managers');
END;
/


prompt Initializing Sales Permissions
BEGIN
    im_priv_create('view_customers', 		'Sales');
END;
/

BEGIN
    im_priv_create('view_customer_contacts', 	'Sales');
END;
/

BEGIN
    im_priv_create('view_customer_details', 	'Sales');
END;
/

BEGIN
    im_priv_create('view_customers_all', 	'Sales');
END;
/

BEGIN
    im_priv_create('add_customers', 		'Sales');
END;
/

BEGIN
    im_priv_create('view_project_members', 	'Sales');
END;
/

BEGIN
    im_priv_create('view_projects_all', 	'Sales');
END;
/

BEGIN
    im_priv_create('add_projects', 		'Sales');
END;
/

BEGIN
    im_priv_create('search_intranet', 		'Sales');
END;
/

BEGIN
    im_priv_create('view_users', 		'Sales');
END;
/

BEGIN
    im_priv_create('add_offices', 		'Sales');
END;
/

BEGIN
    im_priv_create('view_offices', 		'Sales');
END;
/

BEGIN
    im_priv_create('view_internal_offices', 	'Sales');
END;
/

BEGIN
    im_priv_create('view_offices_all', 		'Sales');
END;
/



prompt Initializing P/O Admins Permissions
BEGIN
    im_priv_create('view_customers', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_customer_contacts', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_customer_details', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_customers_all', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('add_customers', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_project_members', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_projects_all', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_projects_history', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('add_projects', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('search_intranet', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_users', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('add_users', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_invoices', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_payments', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_costs', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('add_invoices', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('add_payments', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('add_costs', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_offices', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('add_offices', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('admin_categories', 		'P/O Admins');
END;
/

BEGIN
    im_priv_create('edit_internal_offices',	'P/O Admins');
END;
/

BEGIN
    im_priv_create('read_private_data', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_internal_offices', 	'P/O Admins');
END;
/

BEGIN
    im_priv_create('view_offices_all', 		'P/O Admins');
END;
/


prompt Initializing Accounting Permissions
BEGIN
    im_priv_create('view_customers', 		'Accounting');
END;
/

BEGIN
    im_priv_create('view_customer_contacts', 	'Accounting');
END;
/

BEGIN
    im_priv_create('view_customer_details', 	'Accounting');
END;
/

BEGIN
    im_priv_create('view_customers_all', 	'Accounting');
END;
/

BEGIN
    im_priv_create('add_customers', 		'Accounting');
END;
/

BEGIN
    im_priv_create('view_project_members', 	'Accounting');
END;
/

BEGIN
    im_priv_create('view_projects_all', 	'Accounting');
END;
/

BEGIN
    im_priv_create('view_projects_history', 	'Accounting');
END;
/

BEGIN
    im_priv_create('search_intranet', 		'Accounting');
END;
/

BEGIN
    im_priv_create('view_users', 		'Accounting');
END;
/

BEGIN
    im_priv_create('add_users', 		'Accounting');
END;
/

BEGIN
    im_priv_create('view_offices', 		'Accounting');
END;
/

BEGIN
    im_priv_create('view_invoices', 		'Accounting');
END;
/

BEGIN
    im_priv_create('view_payments', 		'Accounting');
END;
/

BEGIN
    im_priv_create('view_costs', 		'Accounting');
END;
/

BEGIN
    im_priv_create('add_invoices', 		'Accounting');
END;
/

BEGIN
    im_priv_create('add_payments', 		'Accounting');
END;
/

BEGIN
    im_priv_create('add_costs', 		'Accounting');
END;
/
commit;



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


-- Group_ID:
--  17 - 149: Customers
-- 150 - 199: Varios
	-- 150: Mataro Office
	-- ...
-- 200 - 699: Projects
	-- 200: MySLS
-- 700 - ...: Not defined yet
--1000 - ...: System groups


-- SLS Employees 
INSERT INTO users (user_id, email, password, first_names,last_name, registration_date, registration_ip, user_state) VALUES (3, 'admin@project-open.org', 'admin', 'Admin', 'Istrator', sysdate, '0.0.0.0', 'authorized');
INSERT INTO users (user_id, email, password, first_names,last_name, registration_date, registration_ip, user_state) VALUES (4, 'bigman@project-open.org', 'bigman','Big', 'Manager', sysdate, '0.0.0.0', 'authorized');
INSERT INTO users (user_id, email, password, first_names,last_name, registration_date, registration_ip, user_state) VALUES (5, 'pm@project-open.org', 'pm','Project', 'Manager', sysdate, '0.0.0.0', 'authorized');
INSERT INTO users (user_id, email, password, first_names,last_name, registration_date, registration_ip, user_state) VALUES (6, 'employee@project-open.org', 'employee','Emplo', 'Yee1', sysdate, '0.0.0.0', 'authorized');
INSERT INTO users (user_id, email, password, first_names,last_name, registration_date, registration_ip, user_state) VALUES (7, 'accounting@project-open.org', 'accounting','Accoun', 'Ting', sysdate, '0.0.0.0', 'authorized');
INSERT INTO users (user_id, email, password, first_names,last_name, registration_date, registration_ip, user_state) VALUES (8, 'freelance@project-open.org', 'freelance','Free', 'Lance', sysdate, '0.0.0.0', 'authorized');
INSERT INTO users (user_id, email, password, first_names,last_name, registration_date, registration_ip, user_state) VALUES (9, 'customer@project-open.org', 'customer','Customer', 'Contact', sysdate, '0.0.0.0', 'authorized');

-- Mark as members of group "Employees"
INSERT INTO user_group_map VALUES (9, 3, 'administrator', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (9, 4, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (9, 5, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (9, 6, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (9, 7, 'member', sysdate, 1, '0.0.0.0');

-- Give some dummy Employee information
INSERT INTO im_employees (user_id, start_date) VALUES (3,sysdate);
INSERT INTO im_employees (user_id, start_date) VALUES (4,sysdate);
INSERT INTO im_employees (user_id, start_date) VALUES (5,sysdate);
INSERT INTO im_employees (user_id, start_date) VALUES (6,sysdate);
INSERT INTO im_employees (user_id, start_date) VALUES (7,sysdate);
INSERT INTO im_employees (user_id, start_date) VALUES (8,sysdate);
INSERT INTO im_employees (user_id, start_date) VALUES (9,sysdate);

-- Mark client as client 
INSERT INTO user_group_map VALUES (6, 9, 'member', sysdate, 1, '0.0.0.0');

-- Mark freelance as freelance
INSERT INTO user_group_map VALUES (14, 8, 'member', sysdate, 1, '0.0.0.0');

-- Make Admin (user_id=3) an 'admin' of Intranet Administration (group_id=5)
INSERT INTO user_group_map(user_id, group_id, role, mapping_user, mapping_ip_address) 
VALUES (3, 5, 'administrator', 1, '0.0.0.0');

-- Make Admin (user_id=3) an 'admin' of Site Administration (group_id=1)
INSERT INTO user_group_map(user_id, group_id, role, mapping_user, mapping_ip_address) 
VALUES (3, 1, 'administrator', 1, '0.0.0.0');



-- Setup Mataró Facility & Office and add members
INSERT INTO im_facilities (
        phone,fax,address_line1,address_line2,address_city,address_postal_code,address_country_code,
	landlord,security,note,facility_id,facility_name,address_state
) VALUES (
	'+34 609 953 751','+34 93 751 1235','Somestreet','','Barcelona','08008','','','','',1,'Barcelona Facility','Barcelona'
);

INSERT INTO user_groups (
	creation_ip_address,creation_user,group_id,group_type,approved_p,
	new_member_policy,parent_group_id,group_name,short_name
) VALUES (
	'0.0.0.0', 1, 150, 'intranet', 't', 
	'closed', '8', 'Barcelona Office', 'Barcelona'
);
INSERT INTO im_offices (
	facility_id,public_p,group_id
) VALUES (
	1, 't', 150
);
INSERT INTO user_group_map VALUES (150, 3, 'administrator', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (150, 4, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (150, 5, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (150, 6, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (150, 7, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (150, 8, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (150, 9, 'member', sysdate, 1, '0.0.0.0');



-- Setup "Internal" client (group_id=17) with Frank Bergmann (user_id=3)
-- as manager
INSERT INTO user_groups (
	creation_ip_address, creation_user, group_name, short_name, group_id, 
	group_type, approved_p, new_member_policy, parent_group_id, 
	modification_date, modifying_user
) VALUES (
	'0.0.0.0', 1, 'Internal', 'internal', 17, 
	'intranet', 't', 'closed', 6, sysdate, 1
);
INSERT INTO im_customers (
	referral_source, customer_status_id, customer_type_id, annual_revenue_id,
	billable_p,note,contract_value,site_concept,manager_id,start_date,group_id
) VALUES (
	'', 46, 54, 226, 'f', 'Interal Projects', '', '',  3, sysdate, 17
);
INSERT INTO user_group_map (
	group_id, user_id, role, mapping_user, mapping_ip_address
) VALUES (
	17, 3, 'administrator', 3, '0.0.0.0'
);

INSERT INTO user_groups VALUES (19, 'intranet', 'East Bay Communications Ltd', 'client01', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);
INSERT INTO user_groups VALUES (20, 'intranet', 'Far Way', 'accent', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);
INSERT INTO user_groups VALUES (21, 'intranet', 'Projects.com', 'agency', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);
INSERT INTO user_groups VALUES (22, 'intranet', 'Super Important Client', 'agius', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);
INSERT INTO user_groups VALUES (23, 'intranet', 'Less Important Client', 'agnew', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);
INSERT INTO user_groups VALUES (24, 'intranet', 'Brown and Company', 'alden', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);
INSERT INTO user_groups VALUES (25, 'intranet', 'George, Rummy and Dick Inc.', 'asist', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);
-- reserving groups 125-139 for more clients

INSERT INTO im_customers VALUES (19, 'f', 46, 51, null, '', '', 226, sysdate, null, 't', '', 4, 0, sysdate);
INSERT INTO im_customers VALUES (20, 'f', 46, 51, null, '', '', 226, sysdate, null, 't', '', 4, 0, sysdate);
INSERT INTO im_customers VALUES (21, 'f', 46, 51, null, '', '', 226, sysdate, null, 't', '', 4, 0, sysdate);
INSERT INTO im_customers VALUES (22, 'f', 46, 51, null, '', '', 226, sysdate, null, 't', '', 4, 0, sysdate);
INSERT INTO im_customers VALUES (23, 'f', 46, 51, null, '', '', 226, sysdate, null, 't', '', 4, 0, sysdate);
INSERT INTO im_customers VALUES (24, 'f', 46, 51, null, '', '', 226, sysdate, null, 't', '', 4, 0, sysdate);
INSERT INTO im_customers VALUES (25, 'f', 46, 51, null, '', '', 226, sysdate, null, 't', '', 4, 0, sysdate);
-- reserving groups 125-139 for more clients


INSERT INTO user_group_map VALUES (19, 4, 'administrator', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (20, 4, 'administrator', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (21, 4, 'administrator', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (22, 4, 'administrator', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (23, 4, 'administrator', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (24, 4, 'administrator', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (25, 4, 'administrator', sysdate, 1, '0,0,0.0');


-- Add "MySLS" Project
INSERT INTO user_groups (
	creation_ip_address,creation_user,group_name,short_name,group_id,group_type,
	approved_p,new_member_policy,parent_group_id,modification_date,modifying_user,existence_public_p
) VALUES (
	'0.0.0.0', 1, 'MySLS', '2003_0001', 200, 'intranet', 't', 'closed', 7, sysdate, 1, 'f'
);
INSERT INTO im_projects (
        customer_id,project_type_id,project_status_id,project_lead_id,supervisor_id,
	parent_id,project_budget,description,requires_report_p,start_date,end_date,group_id
) VALUES (
	17, 92, 76, 3, 3, '', '', 'ERP for SLS...', 'f', sysdate, sysdate, 200
);
-- Assign Users to the project
INSERT INTO user_group_map VALUES (200, 3, 'administrator', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (200, 4, 'administrator', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (200, 5, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (200, 6, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (200, 7, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (200, 8, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (200, 9, 'member', sysdate, 1, '0,0,0,0');



-- Add a "First"  Project
INSERT INTO user_groups VALUES (201,'intranet','First Project','2003_0002','root@localhost',sysdate,1,'0.0.0.0','t','t','f','closed','open','f','f','f','f',null,'f',sysdate,1,7);
INSERT INTO im_projects (
        customer_id,project_type_id,project_status_id,project_lead_id,supervisor_id,
	parent_id,project_budget,description,requires_report_p,start_date,end_date,group_id
) VALUES (
	17, 86, 76, 5, 4, '', '', 'Dummy Project to test MySLS', 'f', sysdate, sysdate, 201
);
-- Assign users
INSERT INTO user_group_map VALUES (201, 4, 'administrator', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (201, 5, 'administrator', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (201, 6, 'member', sysdate, 1, '0,0,0,0');



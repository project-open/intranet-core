-- ------------------------------------------------------------
-- /packages/intranet-core/sql/oracle/intranet-population.sql
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

-- Sample Groups
-- 	User Profiles
-- 	Example Offices
-- 	Example Customers
-- Users

-- ------------------------------------------------------------
-- Sample Groups
-- ------------------------------------------------------------

-- Group_IDs:
-- 1	- 5	Administration Groups
-- 6	- 39	User Profiles
-- 40	- 49	Some Offices
-- 50	- 59	Some Customers
-- 60	- 69	Some Projects

-- 150	- 199: Varios
	-- 150: Mataro Office
	-- ...
-- 200	- 699: Projects
	-- 200: MySLS
-- 700	- ...: Not defined yet
--1000	- ...: System groups


-- ------------------------------------------------------------
-- Sample Users
-- ------------------------------------------------------------

declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'general.manager@project-open.com',
	username	=> 'genman',	
	first_names	=> 'General',
	last_name	=> 'Manager',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'xxx',
        salt		=> '1234'
    );
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'project.manager@project-open.com',
	username	=> 'proman',	
	first_names	=> 'Project',
	last_name	=> 'Manager',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'xxx',
        salt		=> '1234'
    );
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'staff.member@project-open.com',
	username	=> 'staffmem',	
	first_names	=> 'Staff',
	last_name	=> 'Member',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'xxx',
        salt		=> '1234'
    );
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'accounting@project-open.com',
	username	=> 'accounting',	
	first_names	=> 'Ac',
	last_name	=> 'Counting',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'xxx',
        salt		=> '1234'
    );
end;
/	





declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'freeelance.one@project-open.com',
	username	=> 'freeone',	
	first_names	=> 'Freelance',
	last_name	=> 'One',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'xxx',
        salt		=> '1234'
    );
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'freelance.two@project-open.com',
	username	=> 'freetwo',	
	first_names	=> 'Freelance',
	last_name	=> 'Two',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'xxx',
        salt		=> '1234'
    );
end;
/	


declare
	v_user_id	integer;
begin
    v_user_id := acs.add_user(
	email		=> 'client.contact@project-open.com',
	username	=> 'clicon',	
	first_names	=> 'Client',
	last_name	=> 'Contact',
        email_verified_p => 't',
        member_state	=> 'approved',
	password	=> 'xxx',
        salt		=> '1234'
    );
end;
/	


-- ------------------------------------------------------------
-- Sample Customers
-- ------------------------------------------------------------


-- Setup "Internal" client (group_id=50) with SysAdmin (user_id=3) as manager
INSERT INTO user_groups VALUES (50, 'intranet', 'Internal', 'internal', 
'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 'f', 'closed', 'open', 
'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 6);

INSERT INTO im_customers VALUES (50, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 'f', '', 4, 0, sysdate, '', null);

INSERT INTO user_group_map VALUES (50,3,'administrator',sysdate,1,'0,0,0.0');

-- Setup some more customers
INSERT INTO user_groups VALUES (51, 'intranet', 'East Bay Communications Ltd', 
'eastbay', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 6);
INSERT INTO user_groups VALUES (52, 'intranet', 'Far Away', 
'farways', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 6);
INSERT INTO user_groups VALUES (53, 'intranet', 'Projects.com', 
'pro-com', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 6);
INSERT INTO user_groups VALUES (54, 'intranet', 'Super Biscuits Inc.', 
'superb', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 6);
INSERT INTO user_groups VALUES (55, 'intranet', 'Detmolder Brotbaecker GmbH', 
'detmolder-brot', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 6);
INSERT INTO user_groups VALUES (56, 'intranet', 'Brown and Company', 
'brownco', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 6);
INSERT INTO user_groups VALUES (57, 'intranet', 'George, Rummy and Dick Inc.', 
'georgeco', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 6);

-- Adding some dummy values to the customers
INSERT INTO im_customers VALUES (51, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 't', '', 4, 0, sysdate, '', null);
INSERT INTO im_customers VALUES (52, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 't', '', 4, 0, sysdate, '', null);
INSERT INTO im_customers VALUES (53, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 't', '', 4, 0, sysdate, '', null);
INSERT INTO im_customers VALUES (54, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 't', '', 4, 0, sysdate, '', null);
INSERT INTO im_customers VALUES (55, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 't', '', 4, 0, sysdate, '', null);
INSERT INTO im_customers VALUES (56, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 't', '', 4, 0, sysdate, '', null);
INSERT INTO im_customers VALUES (57, 'f', 46, 51, 11, 11, '', '', 226, 
sysdate, null, 't', '', 4, 0, sysdate, '', null);


-- Making customers member of group "Customers"
INSERT INTO user_group_map VALUES (51, 4, 'member', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (52, 4, 'member', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (53, 4, 'member', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (54, 4, 'member', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (55, 4, 'member', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (56, 4, 'member', sysdate, 1, '0,0,0.0');
INSERT INTO user_group_map VALUES (57, 4, 'member', sysdate, 1, '0,0,0.0');


-- ------------------------------------------------------------
-- Sample Users Group Memberships
-- ------------------------------------------------------------


-- Mark client as client 
INSERT INTO user_group_map VALUES (6, 11, 'member', sysdate, 1, '0.0.0.0');

-- Mark freelancers as freelancers
INSERT INTO user_group_map VALUES (14, 9, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (14, 8, 'member', sysdate, 1, '0.0.0.0');

-- Make SysAdmin as Site Admin and Intranet Admin (1 & 5)
INSERT INTO user_group_map VALUES (1, 3, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (5, 3, 'member', sysdate, 1, '0.0.0.0');

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


-- ------------------------------------------------------------
-- Sample Offices
-- ------------------------------------------------------------

-- First setup facilities (referenced by im_office)
INSERT INTO im_facilities (
phone,fax,address_line1,address_line2,address_city,address_postal_code,
address_country_code,landlord,security,note,facility_id,facility_name,
address_state) VALUES (
'+34 93 741 1234','+34 93 751 1235','Thos i Codina 15','','Mataro','08302',
'','','','',1,'Mataro Facility','Mataro');

INSERT INTO user_groups VALUES (40, 'intranet', 'Mataro Office', 
'Mataro Office', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 8);

-- Setup the office entry (=group + facility)
INSERT INTO im_offices (facility_id,public_p,group_id) VALUES (1, 't', 40);

-- Add users as members of the office
INSERT INTO user_group_map VALUES (40,4,'administrator',sysdate,1,'0.0.0.0');
INSERT INTO user_group_map VALUES (40, 5, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (40, 6, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (40, 7, 'member', sysdate, 1, '0.0.0.0');
INSERT INTO user_group_map VALUES (40, 8, 'member', sysdate, 1, '0.0.0.0');


-- Second office in Premia de Dalt
INSERT INTO im_facilities (
phone,fax,address_line1,address_line2,address_city,address_postal_code,
address_country_code,landlord,security,note,facility_id,facility_name,
address_state) VALUES (
'+34 93 751 6454',null,'Avda. Felix Millet, 45','','Premia de Dalt','08338',
'','','','',2,'Premia Facility','Premia');

INSERT INTO user_groups VALUES (41, 'intranet', 'Premia Office', 
'Premia Office', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 
't', 'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', 
sysdate, 1, 8);

-- Setup the office entry (=group + facility)
INSERT INTO im_offices (facility_id,public_p,group_id) VALUES (2, 't', 41);

INSERT INTO user_group_map VALUES (41,3,'administrator',sysdate,1,'0.0.0.0');



-- ------------------------------------------------------------
-- Administration
-- ------------------------------------------------------------

-- Associate intranet user groups with a few modules
BEGIN
   user_group_type_module_add('intranet', 'news');
   user_group_type_module_add('intranet', 'address-book');
   user_group_type_module_add('intranet', 'download');
END;
/
show errors;


-- ------------------------------------------------------------
-- Add Development Projects (with Internal Customers)
-- ------------------------------------------------------------

-- Add "Project/Open" Main Project
INSERT INTO user_groups VALUES (60, 'intranet', 'Project/Open', 
'proj-open', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 
'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 7);

INSERT INTO im_projects VALUES(60, null, 50, 92, 76, '', null, null, 
null, null, sysdate, sysdate, '', 3, 3, null, 'f', null);

-- Assign Users to the project
INSERT INTO user_group_map VALUES (60,3,'administrator',sysdate,1, '0,0,0,0');
INSERT INTO user_group_map VALUES (60, 4, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (60, 5, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (60, 6, 'member', sysdate, 1, '0,0,0,0');


-- Add "Project/Translation" Sub Project
INSERT INTO user_groups VALUES (61, 'intranet', 'Project/Translation', 
'proj-trans', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 
'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 7);

INSERT INTO im_projects VALUES(61, 60, 50, 92, 76, '', null, null, 
null, null, sysdate, sysdate, '', 3, 3, null, 'f', null);

-- Assign Users to the project
INSERT INTO user_group_map VALUES (61,3,'administrator',sysdate,1, '0,0,0,0');
INSERT INTO user_group_map VALUES (61, 6, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (61, 7, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (61, 8, 'member', sysdate, 1, '0,0,0,0');


-- Add "Project/Agency" Sub Project
INSERT INTO user_groups VALUES (62, 'intranet', 'Project/Translation', 
'proj-agency', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 
'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 7);

INSERT INTO im_projects VALUES(62, 60, 50, 92, 76, '', null, null, 
null, null, sysdate, sysdate, '', 3, 3, null, 'f', null);

-- Assign Users to the project
INSERT INTO user_group_map VALUES (62,3,'administrator',sysdate,1, '0,0,0,0');
INSERT INTO user_group_map VALUES (62, 6, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (62, 7, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (62, 8, 'member', sysdate, 1, '0,0,0,0');


-- Add "Project/Knowledge" Sub Project
INSERT INTO user_groups VALUES (63, 'intranet', 'Project/Knowledge', 
'proj-km', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 
'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 7);

INSERT INTO im_projects VALUES(63, 60, 50, 92, 76, '', null, null, 
null, null, sysdate, sysdate, '', 3, 3, null, 'f', null);

-- Assign Users to the project
INSERT INTO user_group_map VALUES (63,3,'administrator',sysdate,1, '0,0,0,0');
INSERT INTO user_group_map VALUES (63, 6, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (63, 7, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (63, 8, 'member', sysdate, 1, '0,0,0,0');



-- ------------------------------------------------------------
-- Add Implantations Projects (with External Customers)
-- ------------------------------------------------------------

-- Add "East Bay ERP" Main Project
INSERT INTO user_groups VALUES (64, 'intranet', 'East Bay ERP', 
'east-bay-erp', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 
'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 7);

INSERT INTO im_projects VALUES(64, null, 51, 92, 76, '', null, null, 
null, null, sysdate, sysdate, '', 3, 3, null, 'f', null);

-- Assign Users to the project
INSERT INTO user_group_map VALUES (64,3,'administrator',sysdate,1, '0,0,0,0');
INSERT INTO user_group_map VALUES (64, 4, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (64, 5, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (64, 6, 'member', sysdate, 1, '0,0,0,0');


-- Add "East Bay Maintenance" Maintenance
INSERT INTO user_groups VALUES (65, 'intranet', 'East Bay Maintenance', 
'east-bay-maint', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 
'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 7);

INSERT INTO im_projects VALUES(65, 64, 51, 92, 76, '', null, null, 
null, null, sysdate, sysdate, '', 3, 3, null, 'f', null);

-- Assign Users to the project
INSERT INTO user_group_map VALUES (65,3,'administrator',sysdate,1, '0,0,0,0');
INSERT INTO user_group_map VALUES (65, 4, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (65, 5, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (65, 6, 'member', sysdate, 1, '0,0,0,0');



-- Add "Far Way Intranet" 
INSERT INTO user_groups VALUES (66, 'intranet', 'Far Way Intranet', 
'far-way intranet', 'root@localhost', sysdate, 1, '0.0.0.0', 't', 't', 
'f', 'closed', 'open', 'f', 'f', 'f', 'f', null, 'f', sysdate, 1, 7);

INSERT INTO im_projects VALUES(66, null, 52, 92, 76, '', null, null, 
null, null, sysdate, sysdate, '', 3, 3, null, 'f', null);

-- Assign Users to the project
INSERT INTO user_group_map VALUES (66,3,'administrator',sysdate,1, '0,0,0,0');
INSERT INTO user_group_map VALUES (66, 4, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (66, 5, 'member', sysdate, 1, '0,0,0,0');
INSERT INTO user_group_map VALUES (66, 6, 'member', sysdate, 1, '0,0,0,0');




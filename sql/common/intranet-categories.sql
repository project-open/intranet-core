-- /packages/intranet-core/sql/common/intranet-categories.sql
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
-- @author	unknown@arsdigita.com
-- @author	frank.bergmann@project-open.com


-- ------------------------------------------------------------
-- Categories
--
-- We insert all of the intranet categories we use at
-- ArsDigita more as a starting point/reference for 
-- other companies. Feel free to change these either
-- here in the data model or through /www/admin/intranet
-- ------------------------------------------------------------


--------- Category Ranges ----------------------------------
-- Somethimes we want to use category IDs directly in 
-- program code, so we need to define reserved category spaces
-- for each module. Not very clean, but clumsy SQL to get
-- category_ids are neither very elegant...

--   0- 10	Intranet Task Board Time Frame
--  40- 49	Intranet Company Status
--  51-	59	Intranet Company Types
--  60- 65	Intranet Partner Status
--  66- 69	Intranet Project On Track Status
--  71- 83	Intranet Project Status
--  85-109	Intranet Project Type
-- 110-119	Intranet Quality
-- 120-129	Intranet Hiring Source
-- 130-149	Intranet Task Board
-- 150-159	Intranet Job Title
-- 190-199	Intranet Qualification Process
-- 200-219	Intranet Department
-- 220-229	Intranet Annual Revenue
-- 250-299	Intranet Translation Language
-- 320-329	Intranet UoM
-- 340-359	Intranet Translation Task Status
-- 360-379	Intranet Project Status
-- 400-409	Intranet Prior Experience
-- 450-459	Intranet Employee Pipeline Status
-- 500-599	Intranet Translation Subject Area
-- 600-699	Intranet Translation File Type
-- 800-899	Intranet Invoice Payment Method
-- 900-999	Intranet Cost Templates
-- 1000-1099	Intranet Payment Type (for im_payments)
-- 1100-1199	Intranet Topic Type
-- 1200-1299	Intranet Topic Status
-- 1300-1399	Intranet Project Role
-- 2000-2099	Intranet Freelance Skill Type
-- 2100-2199	Intranet Freelance TM Tools
-- 2200-2299	Intranet Experience Level
-- 2300-2399	Intranet LOC Tools
-- 2400-2419	Intranet Skill Weight

-- 2420-2499	??

-- 2500-2599	Translation Hierarchy

-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status
-- 3200-3299    Intranet CRM Tracking
-- 3300-3399    reserved for cost centers
-- 3400-3499    Intranet Investment Type
-- 3500-3599    Intranet Investment Status
-- 3600-3699    Intranet Investment Amortization Interval (reserved)
-- 3700-3799    Intranet Cost Item Type
-- 3800-3899    Intranet Cost Item Status
-- 3900-3999    Intranet Cost Item Planning Type
-- 4000-4099	Intranet Expense Type
-- 4100-4199	Intranet Expense Payment Type
-- 4200-4299	Intranet TM Integration Type
-- 4300-4399	Intranet Trans Task Type
-- 4300-4499    Intranet Bug-Tracker
-- 4400-4499    Intranet Trans RFQ
-- 4500-4599    (reserved)

-- 5000-5999	Timesheet Management
-- 5000-5099	Intranet Absence Type

-- 6000-6999	Intranet RecruitingRecruiting
-- 7000-7999	Intranet Translation Quality
-- 8000-8999	Intranet Translation Marketplace

-- 9000-9499	Intranet Material
-- 9500-9699	Intranet Timesheet Tasks
-- 9700-9799	Intranet Cust-Baselkb

-- 10000-10999	Intranet DynField

-- Ugly: This range has been "polluted" because previous
-- systems had the im_categories_seq set to 10000.
-- However, none of the value should have exceeded 10999

-- 11000-11099	Intranet SQL Selectors
-- 11100-11199	CRM IP Type (100)
-- 11200-11299	CRM IP Status (100)
-- 11300-11399	Intranet Trans Invoices VAW
-- 11400-11499	Intranet Notes Status
-- 11500-11599	Intranet Notes Status
-- 11600-11699	Intranet Invoice Canned Notes
-- 11700-11799	reserved (100)
-- 11800-11899	reserved (100)
-- 11900-11999	reserved (100)
-- 12000-12999	reserved (1000)
-- 13000-13999	reserved (1000)
-- 14000-14999	reserved (1000)
-- 15000-15999	reserved (1000)
-- 16000-16999	reserved (1000)
-- 17000-17999	reserved (1000)
-- 18000-18999	reserved (1000)
-- 19000-19999	reserved (1000)
-- 20000-99999	reserved (80000)
--100000-999999 reserved (900000)
--1000000-9999999 reserved (9000000)

-- Here starts the free values for im_categories_seq
-- since 2006-05-26

------------------------------------------------------
-- Business Objects
--
create or replace view im_biz_object_role as 
select category_id as role_id, category as role
from im_categories 
where category_type = 'Intranet Biz Object Role';

------------------------------------------------------
-- Projects
--
create or replace view im_project_status as 
select category_id as project_status_id, category as project_status
from im_categories 
where category_type = 'Intranet Project Status';

create or replace view im_project_types as
select category_id as project_type_id, category as project_type
from im_categories
where category_type = 'Intranet Project Type';

------------------------------------------------------
-- Companies
--
create or replace view im_company_status as 
select category_id as company_status_id, category as company_status
from im_categories 
where category_type = 'Intranet Company Status';

create or replace view im_company_types as
select category_id as company_type_id, category as company_type
from im_categories
where category_type = 'Intranet Company Type';

create or replace view im_annual_revenue as
select category_id as revenue_id, category as revenue
from im_categories
where category_type = 'Intranet Annual Revenue';

------------------------------------------------------
-- Partners
--
create or replace view im_partner_status as 
select category_id as partner_status_id, category as partner_status
from im_categories 
where category_type = 'Intranet Partner Status';

create or replace view im_partner_types as
select category_id as partner_type_id, category as partner_type
from im_categories
where category_type = 'Intranet Partner Type';

------------------------------------------------------
-- Offices
--
create or replace view im_office_status as 
select category_id as office_status_id, category as office_status
from im_categories 
where category_type = 'Intranet Office Status';

create or replace view im_office_types as
select category_id as office_type_id, category as office_type
from im_categories
where category_type = 'Intranet Office Type';



------------------------------------------------------
-- Setup Categories
--

-- Intranet Company Status
insert into im_categories (
	CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, 
	CATEGORY, CATEGORY_TYPE
) values (
	'', 'f', '41', 
	'Potential', 'Intranet Company Status'
);

insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '42', 'Inquiring', 'Intranet Company Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '43', 'Qualifying', 'Intranet Company Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '44', 'Quoting', 'Intranet Company Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '45', 'Quote out', 'Intranet Company Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '46', 'Active', 'Intranet Company Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '47', 'Declined', 'Intranet Company Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '48', 'Inactive', 'Intranet Company Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '49', 'Deleted', 'Intranet Company Status');

-- Introduce hierarchical company stati
-- Basicly, we've got not three super-states:
--	potential	everything before the company becomes "active"
--	active		when the company is a valid customer or provider
--	close		all possible outcomes when a business relation finishes
--
insert into im_category_hierarchy values (41,42);
insert into im_category_hierarchy values (41,43);
insert into im_category_hierarchy values (41,44);
insert into im_category_hierarchy values (41,45);

insert into im_category_hierarchy values (48,47);
insert into im_category_hierarchy values (48,49);



-- Intranet Company Types
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '51', 'Unknown', 'Intranet Company Type');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '52', 'Other', 'Intranet Company Type');
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '53', 'Internal', 'Intranet Company Type');

INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '54', 'MLV Translation Agency Customer', 'Intranet Company Type');
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '55', 'Software Company', 'Intranet Company Type');

INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '56', 'Provider', 'Intranet Company Type');
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '57', 'Customer', 'Intranet Company Type');

INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '58', 'Freelance Provider', 'Intranet Company Type');
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '59', 'Office Equipment Provider', 'Intranet Company Type');

-- This is a "parent_only_p" category that doesn't appear on the drop-down boxes
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, PARENT_ONLY_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', 't', '60', 'CustOrIntl', 'Intranet Company Type');


-- Establish CustOrIntl super-category
-- CustOrIntl is used by the customers select box
insert into im_category_hierarchy values (60,53);
insert into im_category_hierarchy values (60,57);
insert into im_category_hierarchy values (60,54);
insert into im_category_hierarchy values (60,55);

-- Customers
insert into im_category_hierarchy values (57,54);
insert into im_category_hierarchy values (57,55);

-- Providers
insert into im_category_hierarchy values (56,58);
insert into im_category_hierarchy values (56,59);


-- Partner Status
-- insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
-- ('', 'f', '60', 'Targeted', 'Intranet Partner Status');
-- insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
-- ('', 'f', '61', 'In Discussion', 'Intranet Partner Status');
-- insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
-- ('', 'f', '62', 'Active', 'Intranet Partner Status');
-- insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
-- ('', 'f', '63', 'Announced', 'Intranet Partner Status');
-- insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
-- ('', 'f', '64', 'Dormant', 'Intranet Partner Status');
-- insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
-- ('', 'f', '65', 'Dead', 'Intranet Partner Status');


-- Project On Track Status
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '66', 'Green', 'Intranet Project On Track Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '67', 'Yellow', 'Intranet Project On Track Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '68', 'Red', 'Intranet Project On Track Status');


-- Project Status
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '71', 'Potential', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '72', 'Inquiring', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '73', 'Qualifying', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '74', 'Quoting', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '75', 'Quote Out', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '76', 'Open', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '77', 'Declined', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '78', 'Delivered', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '79', 'Invoiced', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '80', 'Partially Paid', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '81', 'Closed', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '82', 'Deleted', 'Intranet Project Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '83', 'Canceled', 'Intranet Project Status');

-- Introduce hierarchical project states.
-- Basicly, we've got not three super-states:
--	potential	everything before the project gets "open"
--	open		when the project is executed and
--	close		all possible outcomes when execution is finished
--
insert into im_category_hierarchy values (71,72);
insert into im_category_hierarchy values (71,73);
insert into im_category_hierarchy values (71,74);
insert into im_category_hierarchy values (71,75);
insert into im_category_hierarchy values (81,77);
insert into im_category_hierarchy values (81,78);
insert into im_category_hierarchy values (81,79);
insert into im_category_hierarchy values (81,80);
insert into im_category_hierarchy values (81,82);
insert into im_category_hierarchy values (81,83);


-- Project Type
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE) 
values ('84', 'Project Task', 'Intranet Project Type');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) 
values ('', 'f', '85', 'Unknown', 'Intranet Project Type');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) 
values ('', 'f', '86', 'Other', 'Intranet Project Type');

-- 87 - 97 reserved for Translation
-- 97 - Strategic Consulting  	Consulting Project 	
-- 98 - Software Maintenance 		
-- 99 - Software Development 
-- 100 - Task (for timesheet tasks)


-- Hiring Source
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '121', 'Personal Contact', 'Intranet Hiring Source');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '122', 'Web Site', 'Intranet Hiring Source');

-- Job Title
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '151', 'Linguistic Staff Jr.', 'Intranet Job Title');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '152', 'Linguistic Staff Sr.', 'Intranet Job Title');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '153', 'Project Manager Jr.', 'Intranet Job Title');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '154', 'Project Manager Sr.', 'Intranet Job Title');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '155', 'Freelance', 'Intranet Job Title');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '156', 'Managing Director', 'Intranet Job Title');



-- 160-169	Intranet Office Status
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '160', 'Active', 'Intranet Office Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '161', 'Inactive', 'Intranet Office Status');


-- 170-179	Intranet Office Type
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '170', 'Main Office', 'Intranet Office Type');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '171', 'Sales Office', 'Intranet Office Type');


-- Qualilification Process
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '191', 'University Studies', 'Intranet Qualification Process');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '192', 'Domain Expert', 'Intranet Qualification Process');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '193', 'None', 'Intranet Qualification Process');

-- Task Board
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', 130, '15 Minutes', 'Intranet Task Board Time Frame');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', 131, '1 hour', 'Intranet Task Board Time Frame');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', 132, '1 day', 'Intranet Task Board Time Frame');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', 133, 'Side Project', 'Intranet Task Board Time Frame');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', 134, 'Full Time', 'Intranet Task Board Time Frame');



-- Intranet Anual Revenue
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '223', 'EUR 0-1k', 'Intranet Annual Revenue');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '224', 'EUR 1-10k', 'Intranet Annual Revenue');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '222', 'EUR 10-100k', 'Intranet Annual Revenue');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '225', '> EUR 100k', 'Intranet Annual Revenue');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '226', 'Pre-revenue', 'Intranet Annual Revenue');



-- Unit or Mesurement
INSERT INTO im_categories VALUES (320,'Hour','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (321,'Day','','Intranet UoM','category','t','f');
INSERT INTO im_categories VALUES (322,'Unit','','Intranet UoM','category','t','f');
-- Page, S-Word, T-Word, S-Line, T-Line defined in intranet-translation


-- Prior Experience
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '400', 'Small Project Work', 'Intranet Prior Experience');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '401', 'Medium Project Work', 'Intranet Prior Experience');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '402', 'Large Project Work', 'Intranet Prior Experience');



-- DynView (system views) Type
insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('1400', 'ObjectList', 'Intranet DynView Type');

insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('1405', 'ObjectView', 'Intranet DynView Type');

insert into im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('1410', 'Backup', 'Intranet DynView Type');
-- reserved 1400 - 1499 for DynView Types



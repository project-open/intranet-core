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
-- 340-379	Intranet Translation Task Status
-- 380-399	Intranet Project Status (extended)
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
-- 2420-2499	reserved
-- 2500-2599	Intranet Project Type (extension)
-- 2600-2999	Translation Hierarchy
-- 3000-3099    Intranet Cost Center Type
-- 3100-3199    Intranet Cost Center Status
-- 3200-3299    Intranet CRM Tracking
-- 3300-3399    Intranet Cost Centers (other)
-- 3400-3499    Intranet Investment Type
-- 3500-3599    Intranet Investment Status
-- 3600-3699    Intranet Investment Amortization Interval (100)
-- 3700-3799    Intranet Cost Item Type
-- 3800-3899    Intranet Cost Item Status
-- 3900-3999    Intranet Cost Item Planning Type
-- 4000-4099	Intranet Expense Type
-- 4100-4199	Intranet Expense Payment Type
-- 4200-4299	Intranet TM Integration Type
-- 4300-4399	Intranet Trans Task Type
-- 4300-4499    Intranet Bug-Tracker
-- 4400-4499    Intranet Trans RFQ
-- 4500-4549    reserved (used to be used for Release Mgmt)
-- 4550-4599    Intranet Project Type (extension)
-- 5000-5999	Timesheet Management
-- 5000-5099	Intranet Absence Type
-- 6000-6999	Intranet Recruiting
-- 7000-7999	Intranet Translation Quality
-- 8000-8999	Intranet Translation Marketplace
-- 9000-9499	Intranet Material
-- 9500-9699	Intranet Timesheet Tasks
-- 9700-9799	Intranet Cust-Baselkb
-- 10000-10999	Intranet DynField
-- 11000-11099	Intranet SQL Selectors
-- 11100-11199	CRM IP Type (100)
-- 11200-11299	CRM IP Status (100)
-- 11300-11399	Intranet Trans Invoices VAW
-- 11400-11499	Intranet Notes Status
-- 11500-11599	Intranet Notes Status
-- 11600-11699	Intranet Invoice Canned Notes
-- 11700-11799	Intranet Conf Item Status (100)
-- 11800-11999	Intranet Conf Item Type (200)
-- 12000-12999	Intranet ConfDB (1000)
-- 13000-13999	Intranet Semantic Network (1000)
-- 14000-14999	Leinhaeuser Development... (1000)
-- 15000-15099	Intranet Report Status
-- 15100-15199	Intranet Report Type
-- 15200-15999	Intranet Report - Other (800)
-- 16000-16999	Intranet Absences (1000)
-- 17000-17999  Intranet Timesheet2 Workflow (1000)
-- 18000-18999  Intranet Absences Workflow (1000)
-- 19000-19999  Intranet Expenses Workflow  (1000)
-- 20000-20999  Intranet Change Management (1000)
-- 21000-21999  Intranet Translation Language (1000)
-- 22000-22999  Intranet User Type (1000)
-- 23000-23999  Intranet Conf Item Type (1000 for intranet-nagios)
-- 24000-24999  Intranet TinyTM (1000)
-- 25000-25999  Customer UNED Spain reserved (1000)
-- 26000-26999  Customer ILO/ISSA reserved (1000)
-- 27000-27999  Intranet Release Management (1000)
-- 28000-28999  Customer A reserved (1000)
-- 29000-29999  Customer B reserved (1000)
-- 30000-39999  Intranet Helpdesk (10000)
-- 40000-40999  Intranet Skin (1000)
-- 41000-41099  Intranet Salutation (100)
-- 41100-41999  Intranet GTD Dashboard  
-- 42000-42999  Intranet VAT Type (1000)
-- 43000-43999  Intranet REST (1000)
-- 44000-49999  reserved (1000)
-- 50000-59999  Navision Integration (10000)
-- 50000-50099	Navision free
-- 50100-50199	Navision Reuse Band
-- 50200-50499	Navision Intranet Translation Task Type (Activity Group + Activities)
-- 50500-50599  Navision General Posting Group
-- 50600-50699  Navision VAT Posting Group
-- 50700-50799  Navision Customer Posting Group
-- 50800-50899  Navision Vendor Posting Group
-- 50900-50999  Navision Payment Method Code
-- 51000-59999  Navision reserved
-- 60000-60999  Intranet Translation Task Type CSV Importer (1000)
-- 60000-69999  Customer DHL Malaysia reserved
-- 70000-70999  Intranet Project Priority (1000)
-- 71000-71999  Intranet Baseline (1000)
-- 72000-72999  Intranet SLA Management (1000)
-- 73000-73999  Intranet Planning (1000)
-- 74000-74999  Intranet Idea Management (1000)
-- 75000-75999  Intranet Risk Management (1000)
-- 76000-76999  Intranet Sencha Ticket Tracker (1000)
-- 77000-77999  Intranet Cost Calculation Account Type (1000)
-- 78000-78999  Intranet Cost Calculation Transaction Type (1000)
-- 79000-79999  Intranet <to be defined> (1000)
-- 80000-80099  Customer SOR (100)
-- 80100-80199  reserved (100)
-- 80200-80299  reserved (100)
-- 80300-80399  reserved (100)
-- 80400-80499  reserved (100)
-- 80500-80599  reserved (100)
-- 80600-80699  reserved (100)
-- 80700-80799  reserved (100)
-- 80800-80899  reserved (100)
-- 80900-80999  reserved (100)
-- 81000-81999  reserved (1000)
-- 82000-81999  reserved (1000)
-- 83000-81999  reserved (1000)
-- 84000-81999  reserved (1000)
-- 85000-81999  reserved (1000)
-- 86000-81999  reserved (1000)
-- 87000-81999  reserved (1000)
-- 88000-81999  reserved (1000)
-- 89000-81999  reserved (1000)
-- 90000-99999  reserved (10000)
--100000-999999 reserved (900000)
--1000000-9999999 reserved (9000000)


-- Here starts the free values for im_categories_seq
-- since 2006-05-26

------------------------------------------------------
-- Business Objects
--
create or replace view im_biz_object_role as 
select category_id as role_id, category as role
from im_categories where category_type = 'Intranet Biz Object Role';

------------------------------------------------------
-- Projects
--
create or replace view im_project_status as 
select category_id as project_status_id, category as project_status
from im_categories where category_type = 'Intranet Project Status';

create or replace view im_project_types as
select category_id as project_type_id, category as project_type
from im_categories where category_type = 'Intranet Project Type';

------------------------------------------------------
-- Companies
--
create or replace view im_company_status as 
select category_id as company_status_id, category as company_status
from im_categories where category_type = 'Intranet Company Status';

create or replace view im_company_types as
select category_id as company_type_id, category as company_type
from im_categories where category_type = 'Intranet Company Type';

create or replace view im_annual_revenue as
select category_id as revenue_id, category as revenue
from im_categories where category_type = 'Intranet Annual Revenue';

------------------------------------------------------
-- Partners
--
create or replace view im_partner_status as 
select category_id as partner_status_id, category as partner_status
from im_categories where category_type = 'Intranet Partner Status';

create or replace view im_partner_types as
select category_id as partner_type_id, category as partner_type
from im_categories where category_type = 'Intranet Partner Type';

------------------------------------------------------
-- Offices
--
create or replace view im_office_status as 
select category_id as office_status_id, category as office_status
from im_categories where category_type = 'Intranet Office Status';

create or replace view im_office_types as
select category_id as office_type_id, category as office_type
from im_categories where category_type = 'Intranet Office Type';



------------------------------------------------------
-- Setup Categories
--

-- Intranet Company Status

SELECT im_category_new ('40', 'Active or Potential', 'Intranet Company Status');
update im_categories set enabled_p = 'f' where category_id = 40;


SELECT im_category_new ('41', 'Potential', 'Intranet Company Status');
SELECT im_category_new ('42', 'Inquiring', 'Intranet Company Status');
SELECT im_category_new ('43', 'Qualifying', 'Intranet Company Status');
SELECT im_category_new ('44', 'Quoting', 'Intranet Company Status');
SELECT im_category_new ('45', 'Quote out', 'Intranet Company Status');
SELECT im_category_new ('46', 'Active', 'Intranet Company Status');
SELECT im_category_new ('47', 'Declined', 'Intranet Company Status');
SELECT im_category_new ('48', 'Inactive', 'Intranet Company Status');
SELECT im_category_new ('49', 'Deleted', 'Intranet Company Status');

-- Introduce hierarchical company stati
-- Basically, we've got not three super-states:
--	potential	everything before the company becomes "active"
--	active		when the company is a valid customer or provider
--	close		all possible outcomes when a business relation finishes
--
SELECT im_category_hierarchy_new (42, 41);
SELECT im_category_hierarchy_new (43, 41);
SELECT im_category_hierarchy_new (44, 41);
SELECT im_category_hierarchy_new (47, 48);
SELECT im_category_hierarchy_new (49, 48);

SELECT im_category_hierarchy_new (41, 40);
SELECT im_category_hierarchy_new (46, 40);


-- Intranet Company Types
SELECT im_category_new ('51', 'Unknown', 'Intranet Company Type');
SELECT im_category_new ('52', 'Other', 'Intranet Company Type');
SELECT im_category_new ('53', 'Internal', 'Intranet Company Type');
SELECT im_category_new ('54', 'MLV Translation Agency Customer', 'Intranet Company Type');
SELECT im_category_new ('55', 'Software Company', 'Intranet Company Type');
SELECT im_category_new ('56', 'Provider', 'Intranet Company Type');
SELECT im_category_new ('57', 'Customer', 'Intranet Company Type');
SELECT im_category_new ('58', 'Freelance Provider', 'Intranet Company Type');
SELECT im_category_new ('59', 'Office Equipment Provider', 'Intranet Company Type');
SELECT im_category_new ('60', 'CustOrIntl', 'Intranet Company Type');

-- Dont show CustOrIntl in drop-down boxes
update im_categories set enabled_p='f' where category_id=60;


-- Establish CustOrIntl super-category
-- CustOrIntl is used by the customers select box
SELECT im_category_hierarchy_new (53, 60);
SELECT im_category_hierarchy_new (57, 60);
SELECT im_category_hierarchy_new (54, 60);
SELECT im_category_hierarchy_new (55, 60);


-- Customers
SELECT im_category_hierarchy_new (54, 57);
SELECT im_category_hierarchy_new (55, 57);

-- Providers
SELECT im_category_hierarchy_new (58, 56);
SELECT im_category_hierarchy_new (59, 56);


-- Partner Status
--  
-- SELECT im_category_new ('60', 'Targeted', 'Intranet Partner Status');
-- SELECT im_category_new ('61', 'In Discussion', 'Intranet Partner Status');
-- SELECT im_category_new ('62', 'Active', 'Intranet Partner Status');
-- SELECT im_category_new ('63', 'Announced', 'Intranet Partner Status');
-- SELECT im_category_new ('64', 'Dormant', 'Intranet Partner Status');
-- SELECT im_category_new ('65', 'Dead', 'Intranet Partner Status');

-- Project On Track Status
SELECT im_category_new ('66', 'Green', 'Intranet Project On Track Status');
SELECT im_category_new ('67', 'Yellow', 'Intranet Project On Track Status');
SELECT im_category_new ('68', 'Red', 'Intranet Project On Track Status');


-- Project Status
SELECT im_category_new ('71', 'Potential', 'Intranet Project Status');
SELECT im_category_new ('72', 'Inquiring', 'Intranet Project Status');
SELECT im_category_new ('73', 'Qualifying', 'Intranet Project Status');
SELECT im_category_new ('74', 'Quoting', 'Intranet Project Status');
SELECT im_category_new ('75', 'Quote Out', 'Intranet Project Status');
SELECT im_category_new ('76', 'Open', 'Intranet Project Status');
SELECT im_category_new ('77', 'Declined', 'Intranet Project Status');
SELECT im_category_new ('78', 'Delivered', 'Intranet Project Status');
SELECT im_category_new ('79', 'Invoiced', 'Intranet Project Status');
SELECT im_category_new ('80', 'Partially Paid', 'Intranet Project Status');
SELECT im_category_new ('81', 'Closed', 'Intranet Project Status');
SELECT im_category_new ('82', 'Deleted', 'Intranet Project Status');
SELECT im_category_new ('83', 'Canceled', 'Intranet Project Status');

-- Introduce hierarchical project states.
-- Basically, we've got not three super-states:
--	potential	everything before the project gets "open"
--	open		when the project is executed and
--	close		all possible outcomes when execution is finished
--

SELECT im_category_hierarchy_new (72, 71);
SELECT im_category_hierarchy_new (73, 71);
SELECT im_category_hierarchy_new (74, 71);
SELECT im_category_hierarchy_new (75, 71);

SELECT im_category_hierarchy_new (77, 81);
SELECT im_category_hierarchy_new (78, 81);
SELECT im_category_hierarchy_new (79, 81);
SELECT im_category_hierarchy_new (80, 81);
SELECT im_category_hierarchy_new (82, 81);
SELECT im_category_hierarchy_new (83, 81);


-- Project Type
-- SELECT im_category_new (84, 'Project Task', 'Intranet Project Type');
SELECT im_category_new (85, 'Unknown', 'Intranet Project Type');
SELECT im_category_new (86, 'Other', 'Intranet Project Type');
-- 87 - 97 reserved for Translation
SELECT im_category_new (97, 'Strategic Consulting', 'Intranet Project Type');
SELECT im_category_new (98, 'Software Maintenance', 'Intranet Project Type');
SELECT im_category_new (99, 'Software Development', 'Intranet Project Type');
SELECT im_category_new (100, 'Task', 'Intranet Project Type');
SELECT im_category_new (101, 'Ticket', 'Intranet Project Type');
update im_categories set enabled_p = 'f' where category_id = 101;

-- 102 - 109 reserved for other Project subclasses
SELECT im_category_new (2500, 'Translation Project', 'Intranet Project Type');
SELECT im_category_new (2501, 'Consulting Project', 'Intranet Project Type');
-- 2502 reserved for "SLA"
-- 2503 reserved
SELECT im_category_new (2504, 'Milestone', 'Intranet Project Type');
update im_categories set enabled_p = 'f'
where category = 'Milestone' and category_type = 'Intranet Project Type';
SELECT im_category_new (2510, 'Program', 'Intranet Project Type');


SELECT im_category_hierarchy_new (97, 2501);
SELECT im_category_hierarchy_new (98, 2501);
SELECT im_category_hierarchy_new (99, 2501);



-- Hiring Source
SELECT im_category_new ('121', 'Personal Contact', 'Intranet Hiring Source');
SELECT im_category_new ('122', 'Web Site', 'Intranet Hiring Source');

-- Job Title
SELECT im_category_new ('151', 'Linguistic Staff Jr.', 'Intranet Job Title');
SELECT im_category_new ('152', 'Linguistic Staff Sr.', 'Intranet Job Title');
SELECT im_category_new ('153', 'Project Manager Jr.', 'Intranet Job Title');
SELECT im_category_new ('154', 'Project Manager Sr.', 'Intranet Job Title');
SELECT im_category_new ('155', 'Freelance', 'Intranet Job Title');
SELECT im_category_new ('156', 'Managing Director', 'Intranet Job Title');

-- 160-169	Intranet Office Status
SELECT im_category_new ('160', 'Active', 'Intranet Office Status');
SELECT im_category_new ('161', 'Inactive', 'Intranet Office Status');

-- 170-179	Intranet Office Type
SELECT im_category_new ('170', 'Main Office', 'Intranet Office Type');
SELECT im_category_new ('171', 'Sales Office', 'Intranet Office Type');


-- Qualilification Process
SELECT im_category_new ('191', 'University Studies', 'Intranet Qualification Process');
SELECT im_category_new ('192', 'Domain Expert', 'Intranet Qualification Process');
SELECT im_category_new ('193', 'None', 'Intranet Qualification Process');

-- Task Board
 
SELECT im_category_new (130, '15 Minutes', 'Intranet Task Board Time Frame');
SELECT im_category_new (131, '1 hour', 'Intranet Task Board Time Frame');
SELECT im_category_new (132, '1 day', 'Intranet Task Board Time Frame');
SELECT im_category_new (133, 'Side Project', 'Intranet Task Board Time Frame');
SELECT im_category_new (134, 'Full Time', 'Intranet Task Board Time Frame');



-- Intranet Anual Revenue
SELECT im_category_new ('223', 'EUR 0-1k', 'Intranet Annual Revenue');
SELECT im_category_new ('224', 'EUR 1-10k', 'Intranet Annual Revenue');
SELECT im_category_new ('222', 'EUR 10-100k', 'Intranet Annual Revenue');
SELECT im_category_new ('225', '> EUR 100k', 'Intranet Annual Revenue');
SELECT im_category_new ('226', 'Pre-revenue', 'Intranet Annual Revenue');



-- Unit or Mesurement
SELECT im_category_new (320, 'Hour', 'Intranet UoM');
SELECT im_category_new (321, 'Day', 'Intranet UoM');
SELECT im_category_new (322, 'Unit', 'Intranet UoM');
-- Page, S-Word, T-Word, S-Line, T-Line defined in intranet-translation


-- Prior Experience
SELECT im_category_new ('400', 'Small Project Work', 'Intranet Prior Experience');
SELECT im_category_new ('401', 'Medium Project Work', 'Intranet Prior Experience');
SELECT im_category_new ('402', 'Large Project Work', 'Intranet Prior Experience');


-- DynView (system views) Type
SELECT im_category_new ('1400', 'ObjectList', 'Intranet DynView Type');
SELECT im_category_new ('1405', 'ObjectView', 'Intranet DynView Type');
SELECT im_category_new ('1410', 'Backup', 'Intranet DynView Type');
-- reserved 1400 - 1499 for DynView Types



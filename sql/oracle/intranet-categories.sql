-- /packages/intranet-core/sql/oracle/intranet-categories.sql
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


-- ------------------------------------------------------------
-- Categories
--
-- We insert all of the intranet categories we use at
-- ArsDigita more as a starting point/reference for 
-- other companies. Feel free to change these either
-- here in the data model or through /www/admin/intranet
-- ------------------------------------------------------------


--------- Category Ranges  ----------------------------------
-- Somethimes we want to use category IDs directly in 
-- program code, so we need to define reserved category spaces
-- for each module. Not very clean, but clumsy SQL to get
-- category_ids are neither very elegant...

--   0- 10	Intranet Task Board Time Frame
--  40- 49	Intranet Customer Status
--  51-	59	Intranet Customer Types
--  60- 69	Intranet Partner Status
--  71- 83	Intranet Project Status
--  85- 96	Intranet Project Type
-- 110-119	Intranet Quality
-- 120-129	Intranet Hiring Source
-- 130-149	Intranet Task Board
-- 150-159	Intranet Job Title
-- 190-199	Intranet Qualification Process
-- 200-219	Intranet Department
-- 220-229	Intranet Annual Revenue
-- 250-299	Intranet Translation Language
-- 320-329	Intranet Translation UoM
-- 340-399	Intranet Translation Task Status
-- 360-379	Intranet Project Status
-- 400-409	Intranet Prior Experience
-- 450-459	Intranet Employee Pipeline Status
-- 500-599	Intranet Translation Subject Area
-- 600-699	Intranet Invoice Status
-- 700-799	Intranet Invoice Type
-- 800-899	Intranet Invoice Payment Method
-- 900-999	Intranet Invoice Templates
-- 1000-1099	Intranet Payment Type
-- 1100-1199	Intranet Topic Type
-- 1200-1299	Intranet Topic Status
-- 2000-2099	Intranet Freelance Skill Type
-- 2100-2199	Intranet Freelance TM Tools

-- 3000-3099	Intranet Cost Center Type
-- 3100-3199	Intranet Cost Center Status


-------------------------------------------------------------
-- Categories
--
-- we use these for categorizing content, registering user interest
-- in particular areas, organizing archived Q&A threads
-- we also may use this as a mailing list to keep users up
-- to date with what goes on at the site

create sequence categories_seq start with 1;
create table categories (
	category_id		integer 
				constraint categories_pk
				primary key,
	category		varchar(50) not null,
	category_description	varchar(4000),
	category_type		varchar(50),
	profiling_weight	integer default 1
				constraint im_profiling_weight_ck
				check(profiling_weight >= 0),
	enabled_p		char(1) default 'f'
				constraint im_enabled_p_ck
				check(enabled_p in ('t','f')),
	mailing_list_info	varchar(4000)
);


-- optional system to put categories in a hierarchy
-- (see /doc/user-profiling.html)
-- we use a UNIQUE constraint instead of PRIMARY key
-- because we use rows with NULL parent_category_id to
-- signify the top-level categories

create table category_hierarchy (
	parent_category_id	integer
				constraint im_parent_category_fk
				references categories,
	child_category_id	integer
				constraint im_child_category_fk
				references categories,
				constraint category_hierarchy_un 
				unique (parent_category_id, child_category_id)
);




-- views on intranet categories to make queries cleaner

------------------------------------------------------
-- Projects
--
create or replace view im_project_status as 
select category_id as project_status_id, category as project_status
from categories 
where category_type = 'Intranet Project Status';

create or replace view im_project_types as
select category_id as project_type_id, category as project_type
from categories
where category_type = 'Intranet Project Type';

------------------------------------------------------
-- Customers
--
create or replace view im_customer_status as 
select category_id as customer_status_id, category as customer_status
from categories 
where category_type = 'Intranet Customer Status';

create or replace view im_customer_types as
select category_id as customer_type_id, category as customer_type
from categories
where category_type = 'Intranet Customer Type';

create or replace view im_annual_revenue as
select category_id as revenue_id, category as revenue
from categories
where category_type = 'Intranet Annual Revenue';

------------------------------------------------------
-- Partners
--
create or replace view im_partner_status as 
select category_id as partner_status_id, category as partner_status
from categories 
where category_type = 'Intranet Partner Status';

create or replace view im_partner_types as
select category_id as partner_type_id, category as partner_type
from categories
where category_type = 'Intranet Partner Type';

------------------------------------------------------
-- HR
--
create or replace view im_prior_experiences as
select category_id as experience_id, category as experience
from categories
where category_type = 'Intranet Prior Experience';

create or replace view im_hiring_sources as
select category_id as source_id, category as source
from categories
where category_type = 'Intranet Hiring Source';

create or replace view im_job_titles as
select category_id as job_title_id, category as job_title
from categories
where category_type = 'Intranet Job Title';

create or replace view im_departments as
select category_id as department_id, category as department
from categories
where category_type = 'Intranet Department';

create or replace view im_qualification_processes as
select category_id as qualification_id, category as qualification
from categories
where category_type = 'Intranet Qualification Process';

create or replace view im_employee_pipeline_states as
select category_id as state_id, category as state
from categories
where category_type = 'Intranet Employee Pipeline State';

------------------------------------------------------
-- Offices
--
create or replace view im_office_status as 
select category_id as office_status_id, category as office_status
from categories 
where category_type = 'Intranet Office Status';

create or replace view im_office_types as
select category_id as office_type_id, category as office_type
from categories
where category_type = 'Intranet Office Type';



-- Intranet Customer Status
insert into categories (
	PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  
	CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE
) values (
	'1',  '',  'f',  '41',  
	'Potential',  '',  'Intranet Customer Status'
);

insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '42',  'Inquiries',  '',  'Intranet Customer Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '43',  'Qualifying',  '',  'Intranet Customer Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '44',  'Quoting',  '',  'Intranet Customer Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '45',  'Quote out',  '',  'Intranet Customer Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '46',  'Active',  '',  'Intranet Customer Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '47',  'Declined',  '',  'Intranet Customer Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '48',  'Inactive',  '',  'Intranet Customer Status');

-- Intranet Customer Types
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '51',  'Unknown',  '',  'Intranet Customer Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '52',  'Other',  '',  'Intranet Customer Type');
INSERT INTO categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '53',  'Internal',  '',  'Intranet Customer Type');


-- Partner Status
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '60',  'Targeted',  '',  'Intranet Partner Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '61',  'In Discussion',  '',  'Intranet Partner Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '62',  'Active',  '',  'Intranet Partner Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '63',  'Announced',  '',  'Intranet Partner Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '64',  'Dormant',  '',  'Intranet Partner Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '65',  'Dead',  '',  'Intranet Partner Status');

-- Project Status
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '71',  'Potential',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '72',  'Inquiring',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '73',  'Qualifying',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '74',  'Quoting',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '75',  'Quote Out',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '76',  'Open',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '77',  'Declined',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '78',  'Delivered',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '79',  'Invoiced',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '80',  'Partially Paid',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '81',  'Closed',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '82',  'Deleted',  '',  'Intranet Project Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '83',  'Canceled',  '',  'Intranet Project Status');

-- Project Type
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '85',  'Unknown',  '',  'Intranet Project Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '86',  'Other',  '',  'Intranet Project Type');


-- Hiring Source
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '121',  'Personal Contact',  '',  'Intranet Hiring Source');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '122',  'Web Site',  '',  'Intranet Hiring Source');

-- Job Title
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '151',  'Linguistic Staff Jr.',  '',  'Intranet Job Title');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '152',  'Linguistic Staff Sr.',  '',  'Intranet Job Title');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '153',  'Project Manager Jr.',  '',  'Intranet Job Title');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '154',  'Project Manager Sr.',  '',  'Intranet Job Title');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '155',  'Freelance',  '',  'Intranet Job Title');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '156',  'Managing Director',  '',  'Intranet Job Title');



-- 160-169	Intranet Office Status
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '160',  'Active',  '',  'Intranet Office Status');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '161',  'Inctive',  '',  'Intranet Office Status');


-- 170-179	Intranet Office Type
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '170',  'Main Office',  '',  'Intranet Office Type');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '171',  'Sales Office',  '',  'Intranet Office Type');


-- Qualilification Process
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '191',  'University Studies',  '',  'Intranet Qualification Process');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '192',  'Domain Expert',  '',  'Intranet Qualification Process');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '193',  'None',  '',  'Intranet Qualification Process');

-- Task Board
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('0',  '',  'f',  130,  '15 Minutes',  '',  'Intranet Task Board Time Frame');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('2',  '',  'f',  131,  '1 hour',  '',  'Intranet Task Board Time Frame');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('3',  '',  'f',  132,  '1 day',  '',  'Intranet Task Board Time Frame');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('4',  '',  'f',  133,  'Side Project',  '',  'Intranet Task Board Time Frame');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('10',  '',  'f',  134,  'Full Time',  '',  'Intranet Task Board Time Frame');

-- Intranet Departments
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '201',  'Administration',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '202',  'Business Development',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '203',  'Client services',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '204',  'Finance',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '205',  'Internal IT Support',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '206',  'Legal',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '207',  'Marketing',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '208',  'Office management',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '209',  'Operations',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '210',  'Human Resources',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '211',  'Sales',  '',  'Intranet Department');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '212',  'Senior Management',  '',  'Intranet Department');



-- Intranet Anual Revenue
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '223',  'EUR 0-1k',  '',  'Intranet Annual Revenue');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '224',  'EUR 1-10k',  '',  'Intranet Annual Revenue');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '222',  'EUR 10-100k',  '',  'Intranet Annual Revenue');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '225',  '> EUR 100k',  '',  'Intranet Annual Revenue');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '226',  'Pre-revenue',  '',  'Intranet Annual Revenue');


-- Prior Experience
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '400',  'Small Project Work',  '',  'Intranet Prior Experience');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '401',  'Medium Project Work',  '',  'Intranet Prior Experience');
insert into categories (PROFILING_WEIGHT,  CATEGORY_DESCRIPTION,  ENABLED_P,  CATEGORY_ID,  CATEGORY,  MAILING_LIST_INFO,  CATEGORY_TYPE) values 
('1',  '',  'f',  '402',  'Large Project Work',  '',  'Intranet Prior Experience');

-- reserved 1100 - 1200 for Forum Topic Types



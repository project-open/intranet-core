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
-- 320-329	Intranet UoM
-- 340-359	Intranet Translation Task Status
-- 360-379	Intranet Project Status
-- 400-409	Intranet Prior Experience
-- 450-459	Intranet Employee Pipeline Status
-- 500-599	Intranet Translation Subject Area
-- 600-699	Intranet Invoice Status
-- 700-799	Intranet Invoice Type
-- 800-899	Intranet Invoice Payment Method
-- 900-999	Intranet Invoice Templates
-- 1000-1099	Intranet Payment Type (for im_payments)
-- 1100-1199	Intranet Topic Type
-- 1200-1299	Intranet Topic Status
-- 1300-1399	Intranet Project Role
-- 2000-2099	Intranet Freelance Skill Type
-- 2100-2199	Intranet Freelance TM Tools
-- 2200-2299	Intranet Experience Level
-- 2300-2399	Intranet LOC Tools
-- 2400-2499	??
-- 2500-2599	Translation Hierarchy

-- 3000-3099	Intranet Cost Center Type
-- 3100-3199	Intranet Cost Center Status


-------------------------------------------------------------
-- Categories
--
-- we use categories as a universal storage for business
-- object states and types, instead of a zillion of 
-- tables like 'im_project_status' and 'im_project_type'.

create sequence im_categories_seq start with 10000;
create table im_categories (
	category_id		integer 
				constraint im_categories_pk
				primary key,
	category		varchar(50) not null,
	category_description	varchar(4000),
	category_type		varchar(50),
	category_gif		varchar(100) default 'category',
	enabled_p		char(1) default 't'
				constraint im_enabled_p_ck
				check(enabled_p in ('t','f')),
                                -- used to indicate "abstract" super-categorys
                                -- that are not valid values for objects.
                                -- For example: "Translation Project" is not a
                                -- project_type, but a class of project_types.
	parent_only_p		char(1) default 'f'
				constraint im_parent_only_p_ck
				check(parent_only_p in ('t','f'))
);

-- fraber 040320: Don't allow for duplicated entries!
create unique index im_categories_cat_cat_type_idx on im_categories(category, category_type);


-- optional system to put categories in a hierarchy.
-- This table stores the "transitive closure" of the
-- is-a relationship between categories in a kind of matrix.
-- Let's asume: B isa A and C isa B. So we'll store
-- the tupels (C,A), (C,B) and (B,A).
--
-- This structure is a very fast structure for asking:
--
--	"is category A a subcategory of B?"
--
-- but requires n^2 storage space in the worst case and
-- it's a mess retracting settings from the hierarchy.
-- We won't have very deep hierarchies, so storage complexity
-- is not going to be a problem.

create table im_category_hierarchy (
	parent_id		integer
				constraint im_parent_category_fk
				references im_categories,
	child_id		integer
				constraint im_child_category_fk
				references im_categories,
				constraint category_hierarchy_un 
				unique (parent_id, child_id)
);
create index im_cat_hierarchy_parent_id_idx on im_category_hierarchy(parent_id);
create index im_cat_hierarchy_child_id_idx on im_category_hierarchy(child_id);


-- views on intranet categories to make queries cleaner

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
-- Customers
--
create or replace view im_customer_status as 
select category_id as customer_status_id, category as customer_status
from im_categories 
where category_type = 'Intranet Customer Status';

create or replace view im_customer_types as
select category_id as customer_type_id, category as customer_type
from im_categories
where category_type = 'Intranet Customer Type';

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
-- HR
--
create or replace view im_prior_experiences as
select category_id as experience_id, category as experience
from im_categories
where category_type = 'Intranet Prior Experience';

create or replace view im_hiring_sources as
select category_id as source_id, category as source
from im_categories
where category_type = 'Intranet Hiring Source';

create or replace view im_job_titles as
select category_id as job_title_id, category as job_title
from im_categories
where category_type = 'Intranet Job Title';

create or replace view im_departments as
select category_id as department_id, category as department
from im_categories
where category_type = 'Intranet Department';

create or replace view im_qualification_processes as
select category_id as qualification_id, category as qualification
from im_categories
where category_type = 'Intranet Qualification Process';

create or replace view im_employee_pipeline_states as
select category_id as state_id, category as state
from im_categories
where category_type = 'Intranet Employee Pipeline State';

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

-- Intranet Customer Status
insert into im_categories (
	CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, 
	CATEGORY, CATEGORY_TYPE
) values (
	'', 'f', '41', 
	'Potential', 'Intranet Customer Status'
);

insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '42', 'Inquiries', 'Intranet Customer Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '43', 'Qualifying', 'Intranet Customer Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '44', 'Quoting', 'Intranet Customer Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '45', 'Quote out', 'Intranet Customer Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '46', 'Active', 'Intranet Customer Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '47', 'Declined', 'Intranet Customer Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '48', 'Inactive', 'Intranet Customer Status');

-- Intranet Customer Types
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '51', 'Unknown', 'Intranet Customer Type');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '52', 'Other', 'Intranet Customer Type');
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '53', 'Internal', 'Intranet Customer Type');
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '54', 'Translation Agency', 'Intranet Customer Type');
INSERT INTO im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '55', 'IT Consulting', 'Intranet Customer Type');


-- Partner Status
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '60', 'Targeted', 'Intranet Partner Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '61', 'In Discussion', 'Intranet Partner Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '62', 'Active', 'Intranet Partner Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '63', 'Announced', 'Intranet Partner Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '64', 'Dormant', 'Intranet Partner Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '65', 'Dead', 'Intranet Partner Status');

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

-- Project Type
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '85', 'Unknown', 'Intranet Project Type');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '86', 'Other', 'Intranet Project Type');
-- 87 - 97 reserved for Translation


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
('', 'f', '161', 'Inctive', 'Intranet Office Status');


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

-- Intranet Departments
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '201', 'Administration', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '202', 'Business Development', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '203', 'Client services', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '204', 'Finance', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '205', 'Internal IT Support', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '206', 'Legal', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '207', 'Marketing', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '208', 'Office management', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '209', 'Operations', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '210', 'Human Resources', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '211', 'Sales', 'Intranet Department');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '212', 'Senior Management', 'Intranet Department');



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
-- Page, S-Word, T-Word, S-Line, T-Line defined in intranet-translation


-- Prior Experience
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '400', 'Small Project Work', 'Intranet Prior Experience');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '401', 'Medium Project Work', 'Intranet Prior Experience');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values 
('', 'f', '402', 'Large Project Work', 'Intranet Prior Experience');

-- reserved 1100 - 1200 for Forum Topic Types


